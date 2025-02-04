import SwiftUI

struct AddSubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var subscriptions: [Subscription]
    let defaultCurrency: Subscription.Currency
    
    @State private var name = ""
    @State private var amount = ""
    @State private var currency: Subscription.Currency
    @State private var startDate = Date()
    @State private var isRecurring = true
    @State private var billingDay = 1
    @State private var showsAlert = false
    @State private var alertMessage = ""
    
    private let availableDays = Array(1...31)
    
    init(subscriptions: Binding<[Subscription]>, defaultCurrency: Subscription.Currency) {
        self._subscriptions = subscriptions
        self.defaultCurrency = defaultCurrency
        self._currency = State(initialValue: defaultCurrency)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("訂閱資訊")) {
                    TextField("訂閱名稱", text: $name)
                    TextField("金額", text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("幣別", selection: $currency) {
                        Text("TWD").tag(Subscription.Currency.TWD)
                        Text("USD").tag(Subscription.Currency.USD)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("扣款設定")) {
                    Toggle("每月自動扣款", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("扣款日", selection: $billingDay) {
                            ForEach(availableDays, id: \.self) { day in
                                Text("\(day)號").tag(day)
                            }
                        }
                        
                        DatePicker("開始日期", selection: $startDate, displayedComponents: .date)
                            .onChange(of: startDate) { newDate in
                                let calendar = Calendar.current
                                let day = calendar.component(.day, from: newDate)
                                billingDay = day
                            }
                    } else {
                        DatePicker("扣款日期", selection: $startDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("新增訂閱")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("儲存") {
                    saveSubscription()
                }
            )
            .alert("錯誤", isPresented: $showsAlert) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveSubscription() {
        guard !name.isEmpty else {
            alertMessage = "請輸入訂閱名稱"
            showsAlert = true
            return
        }
        
        guard let amountDouble = Double(amount), amountDouble > 0 else {
            alertMessage = "請輸入有效的金額"
            showsAlert = true
            return
        }
        
        var finalStartDate = startDate
        if isRecurring {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month], from: startDate)
            components.day = billingDay
            
            if let adjustedDate = calendar.date(from: components) {
                finalStartDate = adjustedDate
            }
        }
        
        let subscription = Subscription(
            name: name,
            amount: amountDouble,
            currency: currency,
            startDate: finalStartDate,
            lastChargeDate: nil,
            isRecurring: isRecurring
        )
        
        subscriptions.append(subscription)
        dismiss()
    }
} 