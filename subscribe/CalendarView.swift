import SwiftUI

struct CalendarView: View {
    let subscriptions: [Subscription]
    let selectedMonth: Date
    @State private var selectedDate: Date?
    @State private var showingSubscriptionList = false
    
    private let calendar = Calendar.current
    private let weekDays = ["日", "一", "二", "三", "四", "五", "六"]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY年MM月"
        return formatter
    }()
    
    var body: some View {
        VStack {
            Text(monthFormatter.string(from: selectedMonth))
                .font(.title2)
                .padding(.top)
            
            // 顯示星期列
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                }
            }
            .padding(.vertical)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let date = date {
                        let subscriptionsForDay = getSubscriptions(for: date)
                        DayCell(date: date, subscriptions: subscriptionsForDay)
                            .onTapGesture {
                                selectedDate = date
                                showingSubscriptionList = true
                            }
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingSubscriptionList) {
            if let date = selectedDate {
                SubscriptionListView(
                    date: date,
                    subscriptions: getSubscriptions(for: date)
                )
            }
        }
    }
    
    private func getDaysInMonth() -> [Date?] {
        let calendar = Calendar.current
        
        // 取得這個月的第一天
        let firstDay = startOfMonth()
        
        // 取得第一天是星期幾（1是星期日，2是星期一，依此類推）
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        // 計算需要的前置空格
        let leadingSpaces = Array(repeating: nil as Date?, count: firstWeekday - 1)
        
        // 計算這個月的總天數
        let range = calendar.range(of: .day, in: .month, for: selectedMonth)!
        let daysInMonth = range.count
        
        // 生成這個月所有的日期
        var allDays: [Date] = []
        for day in 1...daysInMonth {
            var components = calendar.dateComponents([.year, .month], from: selectedMonth)
            components.day = day
            if let date = calendar.date(from: components) {
                allDays.append(date)
            }
        }
        
        // 計算需要的尾隨空格（確保總是顯示6週）
        let totalCells = 42 // 6 週 x 7 天
        let trailingSpaces = totalCells - leadingSpaces.count - allDays.count
        let trailingNils = Array(repeating: nil as Date?, count: max(0, trailingSpaces))
        
        return leadingSpaces + allDays.map { Optional($0) } + trailingNils
    }
    
    private func startOfMonth() -> Date {
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        return calendar.date(from: components)!
    }
    
    private func endOfMonth() -> Date {
        var components = DateComponents()
        components.month = 1
        components.day = -1
        return calendar.date(byAdding: components, to: startOfMonth())!
    }
    
    private func getSubscriptions(for date: Date) -> [Subscription] {
        return subscriptions.filter { subscription in
            if subscription.isRecurring {
                return subscription.isChargeDay(date: date)
            } else {
                return calendar.isDate(subscription.startDate, inSameDayAs: date)
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    let subscriptions: [Subscription]
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dateFormatter.string(from: date))
                .font(.subheadline)
            
            if !subscriptions.isEmpty {
                VStack(spacing: 2) {
                    ForEach(subscriptions.prefix(2)) { subscription in
                        Circle()
                            .fill(subscription.isRecurring ? Color.blue : Color.green)
                            .frame(width: 4, height: 4)
                    }
                    if subscriptions.count > 2 {
                        Text("...")
                            .font(.system(size: 8))
                    }
                }
            }
        }
        .frame(height: 45)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(subscriptions.isEmpty ? Color.clear : Color.blue, lineWidth: 1)
        )
    }
}

struct SubscriptionListView: View {
    let date: Date
    let subscriptions: [Subscription]
    @Environment(\.dismiss) var dismiss
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY年MM月dd日"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(subscriptions) { subscription in
                    VStack(alignment: .leading) {
                        Text(subscription.name)
                            .font(.headline)
                        HStack {
                            Text(subscription.currency.symbol + String(format: "%.2f", subscription.amount))
                            if subscription.isRecurring {
                                Text("(每月)")
                                    .foregroundColor(.blue)
                            }
                        }
                        .font(.subheadline)
                    }
                }
            }
            .navigationTitle(dateFormatter.string(from: date))
            .navigationBarItems(trailing: Button("關閉") {
                dismiss()
            })
        }
    }
} 