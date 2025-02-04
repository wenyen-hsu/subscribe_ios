import SwiftUI

struct ContentView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var showingAddSheet = false
    @State private var showingCalendar = false
    @State private var selectedCurrency: Subscription.Currency = .TWD
    @AppStorage("selectedCurrency") private var savedCurrency = "TWD"
    @State private var selectedMonth = Date()
    
    var totalAmount: Double {
        subscriptionManager.subscriptions.reduce(0) { total, subscription in
            let amount = subscription.amount
            if subscription.currency != selectedCurrency {
                return total + (subscription.currency == .TWD ? 
                    amount * Subscription.Currency.USD.exchangeRate :
                    amount * (1/Subscription.Currency.USD.exchangeRate))
            }
            return total + amount
        }
    }
    
    var yearlyAmount: Double {
        subscriptionManager.subscriptions.reduce(0) { total, subscription in
            let monthlyAmount = subscription.amount
            let convertedAmount = subscription.currency != selectedCurrency ?
                (subscription.currency == .TWD ? 
                    monthlyAmount * Subscription.Currency.USD.exchangeRate :
                    monthlyAmount * (1/Subscription.Currency.USD.exchangeRate)) :
                monthlyAmount
            
            return total + (convertedAmount * Double(subscription.remainingMonths()))
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 幣別切換
                Picker("Currency", selection: $selectedCurrency) {
                    Text("TWD").tag(Subscription.Currency.TWD)
                    Text("USD").tag(Subscription.Currency.USD)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedCurrency) { newValue in
                    savedCurrency = newValue.rawValue
                }
                
                // 訂閱列表
                List {
                    ForEach(subscriptionManager.subscriptions) { subscription in
                        SubscriptionRow(
                            subscription: subscription,
                            displayCurrency: selectedCurrency,
                            onCancel: { date in
                                subscriptionManager.cancelSubscription(id: subscription.id, cancelDate: date)
                            }
                        )
                    }
                    .onDelete(perform: deleteSubscription)
                }
                
                // 添加測試按鈕
                //#if DEBUG
                //Button("模擬下個月") {
                //    subscriptionManager.simulateNextMonth()
                //}
                //.padding()
                //#endif
                
                // 總金額
                VStack(spacing: 8) {
                    HStack {
                        Text("每月總支出:")
                        Spacer()
                        Text("\(selectedCurrency.symbol)\(String(format: "%.2f", totalAmount))")
                            .font(.headline)
                    }
                    
                    HStack {
                        Text("年度支出:")
                        Spacer()
                        Text("\(selectedCurrency.symbol)\(String(format: "%.2f", yearlyAmount))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .navigationTitle("訂閱管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingCalendar.toggle() }) {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: { showingAddSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddSubscriptionView(subscriptions: $subscriptionManager.subscriptions, defaultCurrency: selectedCurrency)
        }
        .sheet(isPresented: $showingCalendar) {
            NavigationView {
                CalendarView(subscriptions: subscriptionManager.subscriptions,
                           selectedMonth: selectedMonth)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            HStack {
                                Button(action: { moveMonth(by: -1) }) {
                                    Image(systemName: "chevron.left")
                                }
                                Button(action: { moveMonth(by: 1) }) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("完成") {
                                showingCalendar = false
                            }
                        }
                    }
            }
        }
    }
    
    private func deleteSubscription(at offsets: IndexSet) {
        subscriptionManager.subscriptions.remove(atOffsets: offsets)
    }
    
    private func moveMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month,
                                             value: value,
                                             to: selectedMonth) {
            selectedMonth = newDate
        }
    }
}

struct SubscriptionRow: View {
    let subscription: Subscription
    let displayCurrency: Subscription.Currency
    let onCancel: (Date) -> Void
    @State private var showingCancelAlert = false
    @State private var showingCancelDatePicker = false
    @State private var selectedCancelDate = Date()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(subscription.name)
                    .font(.headline)
                HStack {
                    Text(subscription.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                    if subscription.isRecurring {
                        if let cancelDate = subscription.cancelDate {
                            Text("將於 \(cancelDate.formatted(date: .abbreviated, time: .omitted)) 取消")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else {
                            Text("(每月)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.secondary)
            }
            Spacer()
            // 顯示原始金額和換算金額
            VStack(alignment: .trailing) {
                Text("\(subscription.currency.symbol)\(String(format: "%.2f", subscription.amount))")
                    .font(.system(.body, design: .monospaced))
                if subscription.currency != displayCurrency {
                    let convertedAmount = subscription.currency == .TWD ? 
                        subscription.amount * Subscription.Currency.USD.exchangeRate :
                        subscription.amount * (1/Subscription.Currency.USD.exchangeRate)
                    Text("\(displayCurrency.symbol)\(String(format: "%.2f", convertedAmount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if subscription.isRecurring && subscription.cancelDate == nil {
                showingCancelAlert = true
            }
        }
        .alert("取消訂閱", isPresented: $showingCancelAlert) {
            Button("選擇取消日期") {
                showingCancelDatePicker = true
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("您確定要取消這個訂閱嗎？")
        }
        .sheet(isPresented: $showingCancelDatePicker) {
            NavigationView {
                VStack {
                    DatePicker("選擇取消日期",
                             selection: $selectedCancelDate,
                             in: Date()...,
                             displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                }
                .navigationTitle("選擇取消日期")
                .navigationBarItems(
                    leading: Button("取消") {
                        showingCancelDatePicker = false
                    },
                    trailing: Button("確定") {
                        onCancel(selectedCancelDate)
                        showingCancelDatePicker = false
                    }
                )
            }
        }
        .padding(.vertical, 4)
    }
} 
