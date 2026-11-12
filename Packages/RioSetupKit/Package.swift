// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "RioSetupKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "RioSetupKit", targets: ["RioSetupKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework-Static", from: "6.0.0")
    ],
    targets: [
        .target(
            name: "RioSetupKit",
            dependencies: [
                .product(name: "AppsFlyerLib-Static", package: "AppsFlyerFramework-Static")
            ]
        ),
        .testTarget(name: "RioSetupKitTests", dependencies: ["RioSetupKit"])
    ]
)
