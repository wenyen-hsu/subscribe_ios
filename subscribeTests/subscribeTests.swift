//
//  subscribeTests.swift
//  subscribeTests
//
//  Created by Wen Hsu on 2025/2/3.
//

import XCTest
@testable import subscribe

final class SubscriptionTests: XCTestCase {
    var sut: Subscription!
    let calendar = Calendar.current
    
    override func setUp() {
        super.setUp()
        // 建立一個基本的訂閱用於測試
        sut = Subscription(
            name: "Netflix",
            amount: 450,
            currency: .TWD,
            startDate: Date(),
            lastChargeDate: nil,
            isRecurring: true
        )
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testSubscriptionInitialization() {
        XCTAssertEqual(sut.name, "Netflix")
        XCTAssertEqual(sut.amount, 450)
        XCTAssertEqual(sut.currency, .TWD)
        XCTAssertTrue(sut.isRecurring)
        XCTAssertNil(sut.lastChargeDate)
        XCTAssertNil(sut.cancelDate)
    }
    
    func testCurrencySymbols() {
        XCTAssertEqual(Subscription.Currency.TWD.symbol, "NT$")
        XCTAssertEqual(Subscription.Currency.USD.symbol, "$")
    }
    
    func testExchangeRates() {
        XCTAssertEqual(Subscription.Currency.TWD.exchangeRate, 1.0)
        XCTAssertEqual(Subscription.Currency.USD.exchangeRate, 0.033)
    }
    
    func testIsChargeDayWithinMonth() {
        // 建立一個固定日期的訂閱
        let dateComponents = DateComponents(year: 2025, month: 2, day: 15)
        let startDate = calendar.date(from: dateComponents)!
        sut.startDate = startDate
        
        // 測試同一天
        XCTAssertTrue(sut.isChargeDay(date: startDate))
        
        // 測試不同天
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startDate)!
        XCTAssertFalse(sut.isChargeDay(date: nextDay))
    }
    
    func testIsChargeDayWithCancellation() {
        let startDate = Date()
        sut.startDate = startDate
        
        // 設定取消日期
        let cancelDate = calendar.date(byAdding: .month, value: 1, to: startDate)!
        sut.cancelDate = cancelDate
        
        // 測試取消日期之後
        let afterCancelDate = calendar.date(byAdding: .day, value: 1, to: cancelDate)!
        XCTAssertFalse(sut.isChargeDay(date: afterCancelDate))
    }
    
    func testRemainingMonths() {
        let startDate = Date()
        let cancelDate = calendar.date(byAdding: .month, value: 3, to: startDate)!
        sut.cancelDate = cancelDate
        
        // 應該返回4個月（包含當月）
        XCTAssertEqual(sut.remainingMonths(from: startDate), 4)
    }
    
    func testGetNextChargeDate() {
        let components = DateComponents(year: 2025, month: 2, day: 15)
        let startDate = calendar.date(from: components)!
        sut.startDate = startDate
        
        let expectedNextCharge = calendar.date(from: DateComponents(year: 2025, month: 3, day: 15))
        XCTAssertEqual(sut.getNextChargeDate(), expectedNextCharge)
    }
}
