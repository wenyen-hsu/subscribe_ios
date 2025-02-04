//
//  subscribeUITests.swift
//  subscribeUITests
//
//  Created by Wen Hsu on 2025/2/3.
//

import XCTest

final class SubscribeUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testAddSubscription() {
        // 點擊添加按鈕
        let addButton = app.buttons["plus.circle.fill"]
        XCTAssertTrue(addButton.exists) // 先確認按鈕存在
        addButton.tap()
        
        // 填寫表單
        let nameTextField = app.textFields["訂閱名稱"]
        XCTAssertTrue(nameTextField.exists)
        nameTextField.tap()
        nameTextField.typeText("Netflix")
        
        let amountTextField = app.textFields["金額"]
        XCTAssertTrue(amountTextField.exists)
        amountTextField.tap()
        amountTextField.typeText("450")
        
        // 選擇幣別 (TWD 已經是預設值，可以不用特別選)
        
        // 儲存
        let saveButton = app.buttons["儲存"]
        XCTAssertTrue(saveButton.exists)
        saveButton.tap()
        
        // 等待列表更新
        let predicate = NSPredicate(format: "exists == true")
        let netflixText = app.staticTexts["Netflix"]
        expectation(for: predicate, evaluatedWith: netflixText, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        // 驗證金額
        XCTAssertTrue(app.staticTexts["NT$450.00"].exists)
    }
    
    func testCancelSubscription() {
        // 首先新增一個訂閱
        testAddSubscription()
        
        // 等待項目出現
        let netflixCell = app.staticTexts["Netflix"]
        XCTAssertTrue(netflixCell.exists)
        netflixCell.tap()
        
        // 等待取消按鈕出現
        let cancelButton = app.buttons["選擇取消日期"]
        XCTAssertTrue(cancelButton.exists)
        cancelButton.tap()
        
        // 選擇日期並確認
        let confirmButton = app.buttons["確定"]
        XCTAssertTrue(confirmButton.exists)
        confirmButton.tap()
        
        // 驗證取消狀態
        let cancelText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '將於'")).element
        XCTAssertTrue(cancelText.exists)
    }
    
    func testSwitchCurrency() {
        // 先新增一個訂閱
        testAddSubscription()
        
        // 切換到 USD
        let usdButton = app.buttons["USD"]
        XCTAssertTrue(usdButton.exists)
        usdButton.tap()
        
        // 等待金額轉換
        let predicate = NSPredicate(format: "exists == true")
        let usdAmount = app.staticTexts["$14.85"]
        expectation(for: predicate, evaluatedWith: usdAmount, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testViewCalendar() {
        // 點擊日曆按鈕
        let calendarButton = app.buttons["calendar"]
        XCTAssertTrue(calendarButton.exists)
        calendarButton.tap()
        
        // 驗證日曆視圖
        let currentMonth = getCurrentMonthText() // 需要實作這個輔助方法
        XCTAssertTrue(app.staticTexts[currentMonth].exists)
        
        // 測試月份切換
        let nextButton = app.buttons["chevron.right"]
        XCTAssertTrue(nextButton.exists)
        nextButton.tap()
        
        // 關閉日曆
        let doneButton = app.buttons["完成"]
        XCTAssertTrue(doneButton.exists)
        doneButton.tap()
    }
    
    // 輔助方法：獲取當前月份文字
    private func getCurrentMonthText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY年MM月"
        return dateFormatter.string(from: Date())
    }
}
