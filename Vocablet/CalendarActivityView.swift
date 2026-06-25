import SwiftUI
import CoreData

struct CalendarActivityView: View {
    @EnvironmentObject var loc: LocalizationManager
    @FetchRequest(sortDescriptors: [SortDescriptor(\CDWord.createdAt, order: .reverse)])
    private var allWords: FetchedResults<CDWord>

    private var activeDays: Set<DateComponents> {
        let cal = Calendar.current
        var set = Set<DateComponents>()
        for word in allWords {
            guard let date = word.createdAt else { continue }
            set.insert(cal.dateComponents([.year, .month, .day], from: date))
        }
        return set
    }

    private var months: [Date] {
        let cal = Calendar.current
        let now = Date()
        let currentMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        guard let earliest = allWords.compactMap({ $0.createdAt }).min() else {
            return [currentMonth]
        }
        let startMonth = cal.date(from: cal.dateComponents([.year, .month], from: earliest))!
        var result: [Date] = []
        var cursor = currentMonth
        while cursor >= startMonth {
            result.append(cursor)
            cursor = cal.date(byAdding: .month, value: -1, to: cursor)!
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                ForEach(months, id: \.self) { month in
                    MonthGrid(month: month, activeDays: activeDays)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.lilyBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(loc.calendarTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: "#3A3230"))
            }
        }
    }
}

private struct MonthGrid: View {
    let month: Date
    let activeDays: Set<DateComponents>
    @EnvironmentObject var loc: LocalizationManager

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var monthTitle: String {
        let formatter = DateFormatter()
        if loc.language == .en {
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MMMM yyyy"
        } else {
            formatter.locale = Locale(identifier: "zh_TW")
            formatter.dateFormat = "yyyy年M月"
        }
        return formatter.string(from: month)
    }

    private var weekdaySymbols: [String] {
        loc.language == .en
            ? ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            : ["一", "二", "三", "四", "五", "六", "日"]
    }

    /// Day numbers for the month, padded with nil for the leading offset (Monday-first week)
    private var dayCells: [Int?] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let weekday = calendar.component(.weekday, from: firstOfMonth) // 1 = Sunday ... 7 = Saturday
        let mondayFirstOffset = (weekday + 5) % 7  // 0 if month starts on Monday
        var cells: [Int?] = Array(repeating: nil, count: mondayFirstOffset)
        cells.append(contentsOf: range.map { $0 })
        return cells
    }

    private func isActive(day: Int) -> Bool {
        var comps = calendar.dateComponents([.year, .month], from: month)
        comps.day = day
        return activeDays.contains(comps)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(monthTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.lilyText)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.lilySecondaryText)
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(dayCells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayView(day)
                    } else {
                        Color.clear.frame(height: 52)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }

    @ViewBuilder
    private func dayView(_ day: Int) -> some View {
        let active = isActive(day: day)
        VStack(spacing: 4) {
            Circle()
                .fill(active ? Color.lilyAccent.opacity(0.25) : Color.lilyBorder.opacity(0.6))
                .frame(width: 36, height: 36)
                .overlay {
                    if active {
                        Image(systemName: "star.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.lilyAccent)
                    }
                }
            Text("\(day)")
                .font(.system(size: 12, weight: active ? .semibold : .regular))
                .foregroundStyle(active ? Color.lilyText : Color.lilySecondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}
