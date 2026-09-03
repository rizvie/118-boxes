import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var stats: [ElementStat]
    @State private var mode: QuizMode?
    @State private var showTable = false
    @State private var showSettings = false

    private var learned: Int { stats.filter(\.isLearned).count }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        title
                        progressCard

                        ForEach(QuizMode.allCases) { m in
                            modeCard(m)
                        }

                        exploreCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Theme.textLo)
                    }
                }
            }
            .navigationDestination(item: $mode) { m in
                QuizView(mode: m)
            }
            .navigationDestination(isPresented: $showTable) {
                TableView()
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
        .tint(Theme.accent)
    }

    private var title: some View {
        VStack(spacing: 2) {
            Text("Elementary")
                .font(Theme.rounded(34, .heavy))
                .foregroundStyle(Theme.textHi)
            Text("All 118 elements")
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.textLo)
        }
        .padding(.top, 4)
    }

    private var progressCard: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Theme.panelHi, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(learned) / 118)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(learned)")
                    .font(Theme.rounded(24, .heavy))
                    .foregroundStyle(Theme.textHi)
            }
            .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 4) {
                Text("Elements learned")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.textHi)
                Text("\(learned) of 118. Get one right three times and it counts.")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.textLo)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.panel))
    }

    private func modeCard(_ m: QuizMode) -> some View {
        Button {
            Haptics.tap()
            mode = m
        } label: {
            HStack(spacing: 16) {
                Image(systemName: m.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(Theme.accent.opacity(0.16)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(m.title)
                        .font(Theme.rounded(20, .heavy))
                        .foregroundStyle(Theme.textHi)
                    Text(m.blurb)
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.textLo)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.textLo)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.panel))
        }
        .buttonStyle(.plain)
    }

    private var exploreCard: some View {
        Button {
            Haptics.tap()
            showTable = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.star)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(Theme.star.opacity(0.16)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Explore the table")
                        .font(Theme.rounded(20, .heavy))
                        .foregroundStyle(Theme.textHi)
                    Text("Tap any element to see it and hear its name")
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.textLo)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.textLo)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.panel))
        }
        .buttonStyle(.plain)
    }
}
