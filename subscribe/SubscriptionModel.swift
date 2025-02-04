import Foundation

struct Subscription: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: Double
    var currency: Currency
    var startDate: Date
    var lastChargeDate: Date?
    var isRecurring: Bool
    var cancelDate: Date?  // 新增：取消日期
    
    enum Currency: String, Codable {
        case TWD
        case USD
        
        var symbol: String {
            switch self {
            case .TWD: return "NT$"
            case .USD: return "$"
            }
        }
        
        var exchangeRate: Double {
            switch self {
            case .TWD: return 1.0
            case .USD: return 0.033
            }
        }
    }
    
    // 檢查訂閱是否已取消
    var isCancelled: Bool {
        guard let cancelDate = cancelDate else { return false }
        return Date() >= cancelDate
    }
    
    // 取得下一個扣款日期
    func getNextChargeDate() -> Date? {
        guard isRecurring else { return nil }
        
        let calendar = Calendar.current
        let currentDate = lastChargeDate ?? startDate
        
        // 取得當前日期的日
        let targetDay = calendar.component(.day, from: startDate) // 使用原始設定的扣款日
        
        // 取得下個月的第一天
        var components = calendar.dateComponents([.year, .month], from: currentDate)
        components.month! += 1
        components.day = 1
        
        guard let nextMonth = calendar.date(from: components) else { return nil }
        
        // 取得下個月的最後一天
        let range = calendar.range(of: .day, in: .month, for: nextMonth)!
        let lastDayOfMonth = range.upperBound - 1
        
        // 如果目標日期大於當月最後一天，則使用當月最後一天
        components.day = min(targetDay, lastDayOfMonth)
        
        return calendar.date(from: components)
    }
    
    // 檢查指定日期是否為扣款日
    func isChargeDay(date: Date) -> Bool {
        // 如果已經取消且超過取消日期，則不再扣款
        if let cancelDate = cancelDate, date >= cancelDate {
            return false
        }
        
        let calendar = Calendar.current
        let targetDay = calendar.component(.day, from: startDate)
        let currentDay = calendar.component(.day, from: date)
        let lastDayOfMonth = calendar.range(of: .day, in: .month, for: date)!.upperBound - 1
        
        if currentDay == lastDayOfMonth && targetDay > lastDayOfMonth {
            return true
        }
        
        return currentDay == targetDay
    }
    
    // 計算剩餘月份
    func remainingMonths(from date: Date = Date()) -> Int {
        guard let cancelDate = cancelDate else { return 12 }  // 如果沒有取消，計算整年
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: date, to: cancelDate)
        return max(0, (components.month ?? 0) + 1)  // +1 包含當月
    }
}

// 用於管理訂閱的類別
class SubscriptionManager: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        // 每天檢查一次是否需要新增扣款記錄
        timer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            self?.checkAndAddCharges()
        }
        // 立即執行一次檢查
        checkAndAddCharges()
    }
    
    // 為了測試用途，添加一個可以指定當前日期的檢查方法
    func checkAndAddCharges(currentDate: Date = Date()) {
        let calendar = Calendar.current
        
        for (index, subscription) in subscriptions.enumerated() {
            guard subscription.isRecurring else { continue }
            
            if let nextChargeDate = subscription.getNextChargeDate(),
               calendar.isDate(nextChargeDate, inSameDayAs: currentDate) {
                // 建立新的扣款記錄
                var updatedSubscription = subscription
                updatedSubscription.lastChargeDate = nextChargeDate
                subscriptions[index] = updatedSubscription
                
                // 新增一筆新的扣款記錄
                let newCharge = Subscription(
                    name: "\(subscription.name) (自動扣款)",
                    amount: subscription.amount,
                    currency: subscription.currency,
                    startDate: nextChargeDate,
                    lastChargeDate: nil,
                    isRecurring: false,  // 單次扣款記錄
                    cancelDate: nil
                )
                subscriptions.append(newCharge)
            }
        }
    }
    
    // 用於測試的方法
    func simulateNextMonth() {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: Date()) else { return }
        checkAndAddCharges(currentDate: nextMonth)
    }
    
    // 取消訂閱
    func cancelSubscription(id: UUID, cancelDate: Date) {
        if let index = subscriptions.firstIndex(where: { $0.id == id }) {
            var subscription = subscriptions[index]
            subscription.cancelDate = cancelDate
            subscriptions[index] = subscription
        }
    }
} 