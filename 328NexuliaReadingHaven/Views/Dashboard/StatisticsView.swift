import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject private var store: AppDataStore

    private var hasData: Bool {
        !store.synopses.isEmpty || !store.drafts.isEmpty
    }

    private var volumePoints: [NamedCount] {
        [
            NamedCount(name: "Synopses", count: store.synopsisCount),
            NamedCount(name: "Drafts", count: store.draftCount)
        ]
    }

    private var statusPoints: [NamedCount] {
        [
            NamedCount(name: ChapterStatus.inProgress.title, count: store.inProgressSynopsisCount),
            NamedCount(name: ChapterStatus.done.title, count: store.doneSynopsisCount)
        ]
    }

    private var activityPoints: [DayCount] {
        store.activityLast7Days.map { DayCount(day: $0.day, count: $0.count) }
    }

    private var bookPoints: [NamedCount] {
        store.topBooksBySynopsisCount.map { NamedCount(name: $0.title, count: $0.count) }
    }

    var body: some View {
        JournalPage {
            JournalHeading(title: "Stats")

            if !hasData {
                VStack(alignment: .leading, spacing: 9) {
                    JournalRule()
                    Text("No statistics yet")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppPalette.ink)
                    Text("Add a synopsis or draft to see your reading activity.")
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.muted)
                }
            } else {
                summaryRow

                chartSection(title: "Library volume", subtitle: "Synopses vs drafts") {
                    Chart(volumePoints) { point in
                        BarMark(
                            x: .value("Type", point.name),
                            y: .value("Count", point.count)
                        )
                        .foregroundStyle(by: .value("Type", point.name))
                        .cornerRadius(3)
                    }
                    .chartForegroundStyleScale([
                        "Synopses": AppPalette.blue,
                        "Drafts": AppPalette.accent
                    ])
                    .chartLegend(.hidden)
                    .frame(height: 180)
                }

                if store.synopsisCount > 0 {
                    chartSection(title: "Chapter status", subtitle: "Progress across synopses") {
                        Chart(statusPoints) { point in
                            BarMark(
                                x: .value("Count", point.count),
                                y: .value("Status", point.name)
                            )
                            .foregroundStyle(by: .value("Status", point.name))
                            .cornerRadius(3)
                        }
                        .chartForegroundStyleScale([
                            ChapterStatus.inProgress.title: AppPalette.accent,
                            ChapterStatus.done.title: AppPalette.blue
                        ])
                        .chartLegend(.hidden)
                        .frame(height: 140)

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 16) {
                                legendDot(color: AppPalette.accent, title: "In progress", value: store.inProgressSynopsisCount)
                                legendDot(color: AppPalette.blue, title: "Done", value: store.doneSynopsisCount)
                            }
                            .fixedSize(horizontal: true, vertical: false)

                            VStack(alignment: .leading, spacing: 6) {
                                legendDot(color: AppPalette.accent, title: "In progress", value: store.inProgressSynopsisCount)
                                legendDot(color: AppPalette.blue, title: "Done", value: store.doneSynopsisCount)
                            }
                        }
                    }
                }

                chartSection(title: "Activity", subtitle: "Edits in the last 7 days") {
                    Chart(activityPoints) { point in
                        LineMark(
                            x: .value("Day", point.day, unit: .day),
                            y: .value("Edits", point.count)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AppPalette.accent)
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        PointMark(
                            x: .value("Day", point.day, unit: .day),
                            y: .value("Edits", point.count)
                        )
                        .foregroundStyle(AppPalette.blue)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(AppPalette.muted.opacity(0.25))
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                .foregroundStyle(AppPalette.muted)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(AppPalette.muted.opacity(0.25))
                            AxisValueLabel()
                                .foregroundStyle(AppPalette.muted)
                        }
                    }
                    .frame(height: 200)
                }

                if !bookPoints.isEmpty {
                    chartSection(title: "Books", subtitle: "Synopses per title") {
                        Chart(bookPoints) { point in
                            BarMark(
                                x: .value("Count", point.count),
                                y: .value("Book", point.name)
                            )
                            .foregroundStyle(AppPalette.accent)
                            .cornerRadius(3)
                        }
                        .frame(height: CGFloat(max(160, bookPoints.count * 36)))
                    }
                }
            }
        }
    }

    private var summaryRow: some View {
        VStack(spacing: 0) {
            JournalRule()
            summaryLine(title: "Synopses", value: store.synopsisCount)
            JournalRule()
            summaryLine(title: "Drafts", value: store.draftCount)
            JournalRule()
            summaryLine(title: "Linked drafts", value: store.linkedDraftCount)
            JournalRule()
        }
    }

    private func summaryLine(title: String, value: Int) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppPalette.ink)
            Spacer()
            Text(value, format: .number)
                .font(.headline.monospacedDigit())
                .foregroundStyle(AppPalette.accent)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private func chartSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            JournalRule()
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppPalette.ink)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppPalette.muted)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }

    private func legendDot(color: Color, title: String, value: Int) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(title): \(value)")
                .font(.caption)
                .foregroundStyle(AppPalette.muted)
        }
    }
}

private struct NamedCount: Identifiable {
    var id: String { name }
    let name: String
    let count: Int
}

private struct DayCount: Identifiable {
    var id: Date { day }
    let day: Date
    let count: Int
}
