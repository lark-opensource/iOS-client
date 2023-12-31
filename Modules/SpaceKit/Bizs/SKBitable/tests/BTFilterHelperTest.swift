//
//  BTFilterHelperTest.swift
//  SKBitable_Tests-Unit-_Tests
//
//  Created by zengsenyuan on 2022/8/7.
//  


import XCTest
@testable import SKBitable

class BTFilterHelperTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCheckFilterConditionStepValid() {
        
        func checkResult(setp: BTFilterStep, fieldErrorType: BTFilterFieldErrorType, isValid: Bool) {
            var condition = BTFilterCondition(conditionId: "test", fieldId: "tst", fieldType: BTFieldType.checkbox.rawValue)
            let filterOptions = BTFilterOptions()
            let result = BTFilterHelper.checkFilterConditionStepValid(step: setp,
                                                                      filterCondition: &condition,
                                                                      filterOptions: filterOptions,
                                                                      fieldErrorType: fieldErrorType)
            XCTAssertTrue(result.isValid == isValid)
        }
        
        BTFilterFieldErrorType.allCases.forEach { errorType in
            checkResult(setp: .field, fieldErrorType: errorType, isValid: true)
        }
        checkResult(setp: .rule, fieldErrorType: .fieldDeleted, isValid: false)
    }
    
    func testCheckGetFilterStep() {
        
        let step0 = BTFilterHelper.getFilterStep(by: 0)
        XCTAssertTrue(step0 == .field)
        let step1 = BTFilterHelper.getFilterStep(by: 1)
        XCTAssertTrue(step1 == .rule)
        let step2 = BTFilterHelper.getFilterStep(by: 2)
        XCTAssertTrue(step2 == .value(.first))
        let step3 = BTFilterHelper.getFilterStep(by: 3)
        XCTAssertTrue(step3 == .value(.second))
        let step4 = BTFilterHelper.getFilterStep(by: 4)
        XCTAssertTrue(step4 == .field)
    }
    
    func testGetConjunctionModels() {
        var filterOptions = BTFilterOptions()
        filterOptions.conjunctionOptions = [
            BTFilterOptions.Conjunction(value: "and", text: "all"),
            BTFilterOptions.Conjunction(value: "or", text: "any")
        ]
        let result = BTFilterHelper.getConjunctionModels(by: filterOptions, conjuctionValue: "or")
        XCTAssertTrue(result.models.count == 2)
        XCTAssertTrue(result.selectedIndex == 1)
    }
}
