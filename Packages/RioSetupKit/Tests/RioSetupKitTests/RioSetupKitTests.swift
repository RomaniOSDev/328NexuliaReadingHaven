import XCTest
@testable import RioSetupKit

// MARK: - Test doubles

@MainActor
private final class MockStore: RioSetupSessionStoring {
    var savedLastURL: URL?
    var hasShownNativeShell = false
    var conversionData: [String: String]?
    var cachedEntryURL: URL?
    func resetIfFreshInstall() {}
}

private struct MockGate: RioSetupGate {
    var open = true
    func isOpen(on date: Date) -> Bool { open }
}

/// Records the order in which the router touches its collaborators.
@MainActor
private final class Recorder: RioSetupEntryURLProviding, RioSetupReachabilityProbing, RioSetupTrackingAuthorizing {
    var events: [String] = []
    var entryURL: URL?
    var finalURL: URL?
    var conversionDelay: Duration?

    func requestIfNeeded() async { events.append("att") }

    func waitForConversion() async {
        events.append("wait")
        if let conversionDelay { try? await Task.sleep(for: conversionDelay) }
    }

    func makeEntryURL() -> URL? {
        events.append("entry")
        return entryURL
    }

    func resolve(_ url: URL) async -> URL? {
        events.append("probe \(url.absoluteString)")
        return finalURL
    }
}

@MainActor
private func makeRouter(gate: MockGate = MockGate(), store: MockStore, recorder: Recorder) -> RioSetupRouter {
    RioSetupRouter(gate: gate, store: store, entry: recorder, probe: recorder, tracking: recorder)
}

@MainActor
private func makeEntry(
    store: MockStore,
    template: String = "https://panel.example/",
    timeout: Duration = .seconds(10)
) -> RioSetupAppsFlyerEntry {
    RioSetupAppsFlyerEntry(
        store: store,
        baseTemplate: template,
        fallback: RioSetupFallbackURLComposer(template: template, trackingParameterName: "aff_sub"),
        timeout: timeout
    )
}

private func query(_ url: URL?) -> [String: String] {
    let items = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
    return Dictionary(items.map { ($0.name, $0.value ?? "") }) { first, _ in first }
}

// MARK: - Tests

final class RioSetupKitTests: XCTestCase {
    private let entryURL = URL(string: "https://panel.example/abc?sub7=abc")!
    private let finalURL = URL(string: "https://offer.example/landing")!

    // MARK: Configuration

    func testObfuscationUnfoldsXORPayload() {
        let payload = Array("https://panel.example/".utf8).map { $0 ^ 0x5A }
        XCTAssertEqual(RioSetupObfuscation.unfold(payload, blend: 0x5A), "https://panel.example/")
    }

    func testPackageKeysKeepTheirStoredValues() {
        XCTAssertEqual(RioSetupKeys.savedLastURL, "sessionAnchorURL")
        XCTAssertEqual(RioSetupKeys.nativeShell, "rio_setup_remote_blocked")
        XCTAssertEqual(RioSetupKeys.trackingParameter, "aff_sub")
    }

    func testConfigurationFallsBackToDefaultTrackingParameter() {
        let configuration = RioSetupConfiguration(
            appsFlyerDevKey: "key", appleAppID: "1", entryURLTemplate: "https://panel.example/", calendarGateAnchor: "07.10.2026"
        )
        XCTAssertEqual(configuration.trackingParameterName, "aff_sub")
    }

    // MARK: Gate

    func testGateOpensOnAnchorDay() throws {
        let utc = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let gate = RioSetupCalendarGate(anchor: "07.10.2026", timeZone: utc)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        func day(_ day: Int, hour: Int) throws -> Date {
            try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour)))
        }

        XCTAssertFalse(gate.isOpen(on: try day(6, hour: 23)))
        XCTAssertTrue(gate.isOpen(on: try day(7, hour: 0)))
        XCTAssertTrue(gate.isOpen(on: try day(8, hour: 12)))
    }

    func testGateStaysClosedForMalformedAnchor() {
        XCTAssertFalse(RioSetupCalendarGate(anchor: "2026-10-07").isOpen(on: .distantFuture))
    }

    // MARK: Fallback URL

    func testFallbackFillsPlaceholdersAndAppendsTrackingParameter() throws {
        let composer = RioSetupFallbackURLComposer(
            template: "https://panel.example/go?click={clickid}&geo=%7Bsubid2%7D",
            trackingParameterName: "aff_sub"
        )
        let items = query(composer.composedURL())

        XCTAssertEqual(items["click"]?.count, 32)
        XCTAssertFalse(try XCTUnwrap(items["geo"]).contains("subid2"))
        XCTAssertFalse(try XCTUnwrap(items["aff_sub"]).isEmpty)
    }

    func testFallbackKeepsTrackingParameterFromTemplate() {
        let composer = RioSetupFallbackURLComposer(template: "https://panel.example/?aff_sub=fixed", trackingParameterName: "aff_sub")
        XCTAssertEqual(composer.composedURL()?.absoluteString, "https://panel.example/?aff_sub=fixed")
    }

    // MARK: AppsFlyer entry URL

    @MainActor
    func testEntryURLPutsSub7IntoPathAndMapsConversionKeys() throws {
        let store = MockStore()
        store.conversionData = [
            "af_sub7": "/R4bhbQgt/", "af_sub1": "one", "media_source": "fb", "af_siteid": "site",
            "af_ad": "creative", "campaign_id": "42", "af_sub2": "  ", "app_id": "777",
        ]
        let url = try XCTUnwrap(makeEntry(store: store).makeEntryURL())
        let items = query(url)

        XCTAssertEqual(url.host, "panel.example")
        XCTAssertEqual(url.path, "/R4bhbQgt")
        XCTAssertEqual(items["sub7"], "/R4bhbQgt/")
        XCTAssertEqual(items["sub1"], "one")
        XCTAssertEqual(items["channel"], "fb")
        XCTAssertEqual(items["sub6"], "site")
        XCTAssertEqual(items["sub8"], "creative")
        XCTAssertEqual(items["campid"], "42")
        XCTAssertEqual(items["app_id"], "777")
        XCTAssertNil(items["sub2"], "blank values are dropped")
        XCTAssertEqual(items["sub15"], Bundle.main.bundleIdentifier)
    }

    @MainActor
    func testEntryURLKeepsBasePathWithoutSub7() throws {
        let store = MockStore()
        store.conversionData = ["af_status": "Organic"]
        let url = try XCTUnwrap(makeEntry(store: store, template: "https://panel.example/base").makeEntryURL())

        XCTAssertEqual(url.path, "/base")
        XCTAssertNil(query(url)["sub7"])
    }

    func testFlattenUsesDotAndIndexPaths() {
        let flat = RioSetupAppsFlyerEntry.flatten([
            "is_first_launch": true,
            "install_time": 3,
            "nested": ["key": "value", "list": ["a", ["deep": 1]]] as [String: Any],
        ])

        XCTAssertEqual(flat["is_first_launch"], "true")
        XCTAssertEqual(flat["install_time"], "3")
        XCTAssertEqual(flat["nested.key"], "value")
        XCTAssertEqual(flat["nested.list[0]"], "a")
        XCTAssertEqual(flat["nested.list[1].deep"], "1")
    }

    @MainActor
    func testWaitForConversionEndsWhenConversionArrives() async {
        let store = MockStore()
        let entry = makeEntry(store: store)
        let waiting = Task { await entry.waitForConversion() }
        await Task.yield()

        entry.receive(["af_status": "Non-organic"])
        await waiting.value

        XCTAssertEqual(store.conversionData, ["af_status": "Non-organic"])
    }

    @MainActor
    func testWaitForConversionEndsOnTimeout() async {
        let store = MockStore()
        let started = ContinuousClock.now
        await makeEntry(store: store, timeout: .milliseconds(100)).waitForConversion()

        XCTAssertGreaterThanOrEqual(ContinuousClock.now - started, .milliseconds(100))
        XCTAssertNil(store.conversionData)
    }

    @MainActor
    func testWaitForConversionSkipsWhenEntryURLIsCached() async {
        let store = MockStore()
        store.cachedEntryURL = entryURL
        let started = ContinuousClock.now
        await makeEntry(store: store, timeout: .seconds(5)).waitForConversion()

        XCTAssertLessThan(ContinuousClock.now - started, .seconds(1))
    }

    // MARK: Router

    @MainActor
    func testClosedGateLaunchesNative() async {
        let recorder = Recorder()
        let router = makeRouter(gate: MockGate(open: false), store: MockStore(), recorder: recorder)
        await router.run()

        XCTAssertEqual(router.destination, .native)
        XCTAssertEqual(recorder.events, [])
    }

    @MainActor
    func testFirstLaunchResolvesStagingToFinalURL() async {
        let store = MockStore()
        let recorder = Recorder()
        recorder.entryURL = entryURL
        recorder.finalURL = finalURL
        let router = makeRouter(store: store, recorder: recorder)
        XCTAssertEqual(router.destination, .staging)

        await router.run()

        XCTAssertEqual(router.destination, .web(finalURL))
        XCTAssertEqual(recorder.events, ["att", "wait", "entry", "probe \(entryURL.absoluteString)"])
        XCTAssertEqual(store.cachedEntryURL, entryURL)
        XCTAssertEqual(router.staging.progress, 1)
    }

    @MainActor
    func testFailedProbeFallsBackToNative() async {
        let recorder = Recorder()
        recorder.entryURL = entryURL
        let router = makeRouter(store: MockStore(), recorder: recorder)
        await router.run()

        XCTAssertEqual(router.destination, .native)
    }

    @MainActor
    func testMissingEntryURLSkipsProbe() async {
        let recorder = Recorder()
        let router = makeRouter(store: MockStore(), recorder: recorder)
        await router.run()

        XCTAssertEqual(router.destination, .native)
        XCTAssertEqual(recorder.events, ["att", "wait", "entry"])
    }

    @MainActor
    func testRelaunchOpensSavedURLWithoutRebuildingEntry() async {
        let store = MockStore()
        store.savedLastURL = finalURL
        let recorder = Recorder()
        let router = makeRouter(store: store, recorder: recorder)
        await router.run()

        XCTAssertEqual(router.destination, .web(finalURL))
        XCTAssertEqual(recorder.events, [])
    }

    @MainActor
    func testSavedURLWinsOverNativeShellFlag() async {
        let store = MockStore()
        store.savedLastURL = finalURL
        store.hasShownNativeShell = true
        let recorder = Recorder()
        let router = makeRouter(store: store, recorder: recorder)
        await router.run()

        XCTAssertEqual(router.destination, .web(finalURL))
        XCTAssertEqual(recorder.events, [])
    }

    @MainActor
    func testNativeFlagWithoutSavedURLIsClearedAndStagingRunsAgain() {
        let store = MockStore()
        store.hasShownNativeShell = true
        let router = makeRouter(store: store, recorder: Recorder())

        XCTAssertFalse(store.hasShownNativeShell)
        XCTAssertEqual(router.destination, .staging)
    }

    @MainActor
    func testCancelledStagingKeepsDestination() async {
        let recorder = Recorder()
        recorder.entryURL = entryURL
        recorder.finalURL = finalURL
        recorder.conversionDelay = .seconds(5)
        let router = makeRouter(store: MockStore(), recorder: recorder)

        let run = Task { await router.run() }
        await Task.yield()
        run.cancel()
        await run.value

        XCTAssertEqual(router.destination, .staging)
        XCTAssertFalse(recorder.events.contains { $0.hasPrefix("probe") })
    }
}
