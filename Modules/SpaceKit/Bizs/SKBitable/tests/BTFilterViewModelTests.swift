//
//  BTFilterViewModelTests.swift
//  SKBitable_Tests-Unit-_Tests
//
//  Created by zengsenyuan on 2022/8/2.
//


import Foundation
import XCTest
@testable import SKBitable
import RxSwift
import RxCocoa
@testable import SKFoundation

class BTFilterViewModelTests: XCTestCase {
    
    var filterViewModel: BTFilterViewModel!
    var filterDataService = MockFilterDataService()
    var disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        filterDataService.getFieldFilterOptions().subscribe { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .success(let data):
                self.filterViewModel = BTFilterViewModel(filterOptions: data,
                                                         dataService: self.filterDataService)
            default: break
            }
        }.disposed(by: disposeBag)
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.nopermission", value: true)
    }

    override func tearDown() {
        super.tearDown()
        UserScopeNoChangeFG.removeMockFG(key: "ccm.bitable.nopermission")
    }
    
    
    func testConditions() {
        handleCondition()
        let testFieldId = "fldkMFjTjB"
        let testOperator = BTFilterOperator.isGreater.rawValue
        let testFieldType = BTFieldType.dateTime.rawValue
        if let condition = filterViewModel.getFinishCondition(finishStep: .field) {
            XCTAssertTrue(condition.fieldId == testFieldId)
            XCTAssertTrue(condition.fieldType == testFieldType)
            XCTAssertTrue(condition.operator == testOperator)
            XCTAssertTrue(condition.value?.count == 2)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testGetFilterValueDataType() {
        
        func isValueTypeEqual(type1: BTFilterValueDataType, type2: BTFilterValueDataType) -> Bool {
            switch (type1, type2) {
            case (.text, .text): return true
            case (.number, .number): return true
            case (.phone, .phone): return true
            case (.options, .options): return true
            case (.links, .links): return true
            case (.date, .date): return true
            case (.chatter, .chatter): return true
            default: return false
            }
        }
        
        func testMain(fieldId: String, testValueType: BTFilterValueDataType) {
            let expect = expectation(description: "testGetFilterValueDataType")
            filterViewModel.getFilterValueDataType(fieldId: fieldId) { valueType in
                guard let valueType = valueType else {
                    XCTAssertTrue(false)
                    return
                }
                XCTAssertTrue(isValueTypeEqual(type1: testValueType, type2: valueType))
                expect.fulfill()
            }
            waitForExpectations(timeout: 0.05) { error in
                XCTAssertNil(error)
            }
        }
        let testDatas: [String: BTFilterValueDataType] = [
            "fldL3P4nfs": .text(""),
            "fldR7ruaLR": .phone(""),
            "fldCqpcc5M": .chatter(viewModel: BTFilterValueChatterViewModel(fieldId: "",
                                                                            selectedMembers: [],
                                                                            isAllowMultipleSelect: true,
                                                                            chatterType: .user,
                                                                            btDataService: nil)),
            "fld5RXwvxS": .options(alls: [], isAllowMultipleSelect: true),
            "flddmHaNeL": .links(viewModel: BTFilterValueLinkViewModel(fieldId: "",
                                                                       selectedRecordIds: [],
                                                                       isAllowMultipleSelect: true,
                                                                       btDataService: nil)),
            "fldkMFjTjB": .date(Date(), fromat: BTFilterDateView.FormatConfig()),
            "fldjLluqds": .chatter(viewModel: BTFilterValueChatterViewModel(fieldId: "",
                                                                          selectedMembers: [],
                                                                          isAllowMultipleSelect: true,
                                                                          chatterType: .group,
                                                                          btDataService: nil))
        ]
        
        let startCondition = BTFilterCondition(conditionId: "mock_1",
                                               fieldId: "fldCqpcc5M",
                                               fieldType: 11,
                                               value: [["userId": "1",
                                                        "name": "zoujie",
                                                        "enName": "zoujie",
                                                        "avatarUrl": ""],
                                                       ["userId": "2",
                                                        "name": "zengsenyuan",
                                                        "enName": "zengsenyuan",
                                                        "avatarUrl": ""
                                                       ]])
        filterViewModel.startHandleCondition(startCondition, startStep: .field)
        
        testDatas.forEach {
            testMain(fieldId: $0.key, testValueType: $0.value)
        }
    }
    
    func testGetUserFilterValue() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.field.user_based_chatter", value: true)
        filterViewModel.getFilterValueDataType(fieldId: "fldCqpcc5M") { valueType in
            guard let valueType = valueType else {
                XCTAssertTrue(false)
                return
            }
            switch valueType {
            case .chatter:
                XCTAssertTrue(true)
            default:
                XCTAssertTrue(false)
            }
            UserScopeNoChangeFG.removeMockFG(key: "ccm.bitable.field.user_based_chatter")
        }
    }
    
    
    func testGetCurrentExactDateValue() {
        handleCondition()
        let value = filterViewModel.getCurrentExactDateValue()
        XCTAssertNotNil(value)
    }
    
    func testGetCurrentExactDateText() {
        handleCondition()
        let dateText = filterViewModel.getCurrentExactDateText()
        XCTAssertNotNil(dateText)
    }
    
    func testGetFieldsCommonData() {
        handleCondition()
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.mobile.support_remote_compute", value: true)
        let (datas, selectedIndex) = filterViewModel.getFieldsCommonData()
        XCTAssertFalse(datas.isEmpty)
        XCTAssertFalse(selectedIndex == 0)
    }
    
    func testGetRulesCommonData() {
        handleCondition()
        let testFieldId = "fldR7ruaLR"
        let (datas, selectedIndex, rule) = filterViewModel.getRulesCommonData(by: testFieldId)
        XCTAssertTrue(datas.count == 6)
        XCTAssertTrue(selectedIndex == 3)
        XCTAssertTrue(rule == BTFilterOperator.doesNotContain.rawValue)
    }
    
    func testGetDateValueCommonData() {
        let expect = expectation(description: "testGetDateValueCommonData")
        filterViewModel.getDateValueCommonData(fieldId: "fieldId", rule: "is") { _, _, _ in
            expect.fulfill()
        }
        waitForExpectations(timeout: 0.05) { error in
            XCTAssertNil(error)
        }
    }
    func testUpdateConditionField() {
        filterViewModel.updateConditionField(fieldId: "fldx8976")
    }
}

// MARK: - Mock Helper
extension BTFilterViewModelTests {
    
    func makeNewCondition(fieldType: BTFieldType = .text) -> BTFilterCondition {
        return BTFilterCondition(conditionId: "conT0TSxqm", //这个id只是占位
                                 fieldId: "fldR7ruaLR",
                                 fieldType: 13,
                                 operator: BTFilterOperator.doesNotContain.rawValue,
                                 value: nil)
    }
    
    func handleCondition() {
        let testFieldId = "fldkMFjTjB"
        let testOperator = BTFilterOperator.isGreater.rawValue
        let startCondition = makeNewCondition()
        filterViewModel.startHandleCondition(startCondition, startStep: .field)
        filterViewModel.updateConditionField(fieldId: testFieldId)
        filterViewModel.updateConditionOperator(testOperator)
        filterViewModel.updateConditionValue([BTFilterDuration.ExactDate.rawValue, Date().timeIntervalSince1970])
    }
}
