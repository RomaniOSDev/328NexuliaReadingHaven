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
        VStack(spacing: 0) {
            ShelfBannerView(imageName: "bannerPagesGlow")

            if !hasData {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(Color("AppAccent"))
                    Text("No statistics yet")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("Add synopses and drafts to see charts of your reading shelf.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryRow

                        chartCard(title: "Library volume", subtitle: "Synopses vs drafts") {
                            Chart(volumePoints) { point in
                                BarMark(
                                    x: .value("Type", point.name),
                                    y: .value("Count", point.count)
                                )
                                .foregroundStyle(by: .value("Type", point.name))
                                .cornerRadius(8)
                            }
                            .chartForegroundStyleScale([
                                "Synopses": Color("AppPrimary"),
                                "Drafts": Color("AppAccent")
                            ])
                            .chartLegend(.hidden)
                            .frame(height: 180)
                        }

                        if store.synopsisCount > 0 {
                            chartCard(title: "Chapter status", subtitle: "Progress across synopses") {
                                Chart(statusPoints) { point in
                                    BarMark(
                                        x: .value("Count", point.count),
                                        y: .value("Status", point.name)
                                    )
                                    .foregroundStyle(by: .value("Status", point.name))
                                    .cornerRadius(8)
                                }
                                .chartForegroundStyleScale([
                                    ChapterStatus.inProgress.title: Color("AppPrimary"),
                                    ChapterStatus.done.title: Color("AppAccent")
                                ])
                                .chartLegend(.hidden)
                                .frame(height: 140)

                                HStack(spacing: 16) {
                                    legendDot(color: Color("AppPrimary"), title: "In progress", value: store.inProgressSynopsisCount)
                                    legendDot(color: Color("AppAccent"), title: "Done", value: store.doneSynopsisCount)
                                }
                            }
                        }

                        chartCard(title: "Activity", subtitle: "Edits in the last 7 days") {
                            Chart(activityPoints) { point in
                                LineMark(
                                    x: .value("Day", point.day, unit: .day),
                                    y: .value("Edits", point.count)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color("AppAccent"))
                                .lineStyle(StrokeStyle(lineWidth: 3))

                                AreaMark(
                                    x: .value("Day", point.day, unit: .day),
                                    y: .value("Edits", point.count)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color("AppAccent").opacity(0.35), Color("AppAccent").opacity(0.02)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                                PointMark(
                                    x: .value("Day", point.day, unit: .day),
                                    y: .value("Edits", point.count)
                                )
                                .foregroundStyle(Color("AppPrimary"))
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { _ in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                        .foregroundStyle(Color("AppTextSecondary").opacity(0.25))
                                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { _ in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                        .foregroundStyle(Color("AppTextSecondary").opacity(0.25))
                                    AxisValueLabel()
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .frame(height: 200)
                        }

                        if !bookPoints.isEmpty {
                            chartCard(title: "Books", subtitle: "Synopses per title") {
                                Chart(bookPoints) { point in
                                    BarMark(
                                        x: .value("Count", point.count),
                                        y: .value("Book", point.name)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color("AppPrimary"), Color("AppAccent")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(6)
                                }
                                .frame(height: CGFloat(max(160, bookPoints.count * 36)))
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 10) {
            summaryTile(title: "Synopses", value: store.synopsisCount)
            summaryTile(title: "Drafts", value: store.draftCount)
            summaryTile(title: "Linked", value: store.linkedDraftCount)
        }
    }

    private func summaryTile(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
    }

    private func chartCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
    }

    private func legendDot(color: Color, title: String, value: Int) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(title): \(value)")
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
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
