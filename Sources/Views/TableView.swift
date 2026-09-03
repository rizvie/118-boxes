import SwiftUI
import SwiftData

struct TableView: View {
    @Query private var stats: [ElementStat]
    @State private var selected: ChemElement?
    @State private var layout: Layout = .table
    @State private var search = ""

    enum Layout: String, CaseIterable { case table = "Table", list = "List" }

    private var learnedSet: Set<Int> {
        Set(stats.filter(\.isLearned).map(\.z))
    }

    private var filtered: [ChemElement] {
        guard !search.isEmpty else { return Elements.all }
        return Elements.all.filter {
            $0.name.localizedCaseInsensitiveContains(search)
                || $0.symbol.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 12) {
                Picker("", selection: $layout) {
                    ForEach(Layout.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 18)

                if layout == .table {
                    grid
                    Spacer(minLength: 0)
                } else {
                    list
                }
            }
            .padding(.top, 8)
        }
        .navigationTitle("The Table")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { ElementDetailView(element: $0) }
        .onDisappear { Speaker.shared.stop() }
    }

    // MARK: Table

    private let cell: CGFloat = 44
    private let gap: CGFloat = 3

    /// row -> column -> element, so each row can be laid out left to right with
    /// blanks where the table has its gaps.
    private var byPosition: [Int: [Int: ChemElement]] {
        var map: [Int: [Int: ChemElement]] = [:]
        for e in Elements.all {
            map[e.row, default: [:]][e.column] = e
        }
        return map
    }

    private var grid: some View {
        let map = byPosition
        // The table is only nine rows deep, so it fits vertically. Only the 18
        // columns need scrolling, and 44pt cells stay tappable for small hands.
        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: gap) {
                ForEach(1...7, id: \.self) { row in
                    rowView(row, map)
                }
                Spacer().frame(height: 10)
                ForEach([9, 10], id: \.self) { row in
                    rowView(row, map)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
    }

    private func rowView(_ row: Int, _ map: [Int: [Int: ChemElement]]) -> some View {
        HStack(spacing: gap) {
            ForEach(1...18, id: \.self) { col in
                if let e = map[row]?[col] {
                    cellView(e)
                        .frame(width: cell, height: cell)
                } else {
                    Color.clear
                        .frame(width: cell, height: cell)
                }
            }
        }
    }

    private func cellView(_ e: ChemElement) -> some View {
        Button {
            Haptics.tap()
            selected = e
        } label: {
            VStack(spacing: 0) {
                Text("\(e.z)")
                    .font(Theme.rounded(9, .semibold))
                    .foregroundStyle(Theme.textLo)
                Text(e.symbol)
                    .font(Theme.rounded(17, .heavy))
                    .foregroundStyle(Theme.textHi)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(e.category.colour.opacity(learnedSet.contains(e.z) ? 0.5 : 0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(e.category.colour.opacity(0.55), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: List

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filtered) { e in
                    Button {
                        Haptics.tap()
                        selected = e
                    } label: {
                        HStack(spacing: 14) {
                            ElementArt(element: e, animated: false)
                                .frame(width: 46, height: 46)
                            Text(e.symbol)
                                .font(Theme.rounded(20, .heavy))
                                .foregroundStyle(Theme.textHi)
                                .frame(width: 42, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.name)
                                    .font(Theme.rounded(18, .bold))
                                    .foregroundStyle(Theme.textHi)
                                Text(e.category.rawValue)
                                    .font(Theme.rounded(13, .medium))
                                    .foregroundStyle(e.category.colour)
                            }
                            Spacer(minLength: 0)
                            if learnedSet.contains(e.z) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Theme.right)
                            }
                            Text("\(e.z)")
                                .font(Theme.rounded(14, .semibold))
                                .foregroundStyle(Theme.textLo)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Theme.panel))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .searchable(text: $search, prompt: "Find an element")
    }
}
