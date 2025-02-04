//
//  SubscriptionManagerTests.swift
//  subscribe
//
//  Created by Wen Hsu on 2025/2/3.
//

import XCTest
@testable import subscribe

final class SubscriptionManagerTests: XCTestCase {
    var sut: SubscriptionManager!
    
    override func setUp() {
        super.setUp()
        sut = SubscriptionManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testAddSubscription() {
        let subscription = Subscription(
            name: "Netflix",
            amount: 450,
            currency: .TWD,
            startDate: Date(),
            lastChargeDate: nil,
            isRecurring: true
        )
        
        sut.subscriptions.append(subscription)
        XCTAssertEqual(sut.subscriptions.count, 1)
        XCTAssertEqual(sut.subscriptions.first?.name, "Netflix")
    }
    
    func testCancelSubscription() {
        // 添加訂閱
        let subscription = Subscription(
            name: "Netflix",
            amount: 450,
            currency: .TWD,
            startDate: Date(),
            lastChargeDate: nil,
            isRecurring: true
        )
        sut.subscriptions.append(subscription)
        
        // 設定取消日期
        let cancelDate = Date()
        sut.cancelSubscription(id: subscription.id, cancelDate: cancelDate)
        
        XCTAssertEqual(sut.subscriptions.first?.cancelDate, cancelDate)
    }
    
    func testAutoCharge() {
        // 建立一個固定日期的訂閱
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!
        
        let subscription = Subscription(
            name: "Netflix",
            amount: 450,
            currency: .TWD,
            startDate: startDate,
            lastChargeDate: nil,
            isRecurring: true
        )
        sut.subscriptions.append(subscription)
        
        // 模擬下個月的扣款
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startDate)!
        sut.checkAndAddCharges(currentDate: nextMonth)
        
        // 應該有兩筆記錄：原始訂閱和自動扣款記錄
        XCTAssertEqual(sut.subscriptions.count, 2)
        
        // 檢查自動扣款記錄
        let autoCharge = sut.subscriptions.last
        XCTAssertEqual(autoCharge?.name, "Netflix (自動扣款)")
        XCTAssertEqual(autoCharge?.amount, 450)
        XCTAssertFalse(autoCharge?.isRecurring ?? true)
    }
}
