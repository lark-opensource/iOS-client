//
// Created by duanxiaochen.7 on 2022/6/27.
// Affiliated with SKBitable_Tests-Unit-_Tests.
//
// Description:

import XCTest
import HandyJSON
@testable import SKBitable
@testable import SKFoundation

class BTTableModelTest: XCTestCase {


    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testTableModelGeneration() {
        var tableModel = BTTableModel()
        do {
           tableModel = try creatMockTableModel()
        } catch {
            XCTFail("tableModel 生成失败: \(error)")
        }
        XCTAssertFalse(tableModel.records.isEmpty)
    }
    
    func testTableModelUpdateRecord() {
        guard var tableModel = try? creatMockTableModel() else {
            return
        }
        if tableModel.records.count > 2 {
            let index = 1
            var record = tableModel.records[index]
            record.update(canEditRecord: !record.editable)
            
            let isSuccessWhenOutOfIndex = tableModel.updateRecord(record, for: tableModel.records.count + 1)
            XCTAssertFalse(isSuccessWhenOutOfIndex, "数组越界守护有问题")
            
            let isSuccessWhenIndexError = tableModel.updateRecord(record, for: 0)
            XCTAssertFalse(isSuccessWhenIndexError, "匹配守护有问题")
            
            tableModel.updateRecord(record, for: index)
            let isUpdateSuccess = tableModel.records[index].editable == record.editable
            XCTAssertFalse(!isUpdateSuccess, "更新 record 有问题")
        }
    }

    func testTableModelUpdateSubmitTopTipShowed() {
        guard var tableModel = try? creatMockTableModel() else {
            return
        }
        tableModel.update(submitTopTipShowed: true)
        XCTAssertTrue(tableModel.submitTopTipShowed)        
    }

    func testTableModelUpdate() {
        guard var tableModel = try? creatMockTableModel() else {
            return
        }
        
        tableModel.update(recordID: "recWIh2U94",
                          fieldID: "fldL3P4nfs",
                          buttonStatus: .loading)
        
        XCTAssertTrue(tableModel.records.first?.buttonFieldStatus["fldL3P4nfs"] == .loading)
    }
    func testTableModelUpdateMeta() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.mobile.support_remote_compute", value: true)
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.enable_edit_form_banner", value: true)
        var tabmeMeta = BTTableMeta()
        var record = [
            [
                "recordId": "",
                "isFiltered": false,
                "headerBarColor": "",
                "fields": [],
                "deletable": false,
                "visible": true,
                "editable": true,
                "shareable": true,
                "groupValue": "",
                "globalIndex": 0,
                "dataStatus": "success"
            ]
        ] as [[String : Any]]
        var val = [
            "baseId": "",
            "tableId": "",
            "loaded": true,
            "total": 1,
            "activeIndex": 0,
            "records": record,
            "timestamp": 0,
            "formBannerUrl": "url"
        ] as [String : Any]
        tabmeMeta.isFormulaServiceSuspend = true
        var tableValue = BTTableValue.deserialize(from: val)!
        var model = BTTableModel()
        model.update(meta: tabmeMeta, value: tableValue, mode: .card, holdDataProvider: nil)
        let isNotFalse = model.records.first?.isFormulaServiceSuspend != false
        XCTAssertTrue(isNotFalse, "isFormulaServiceSuspend should not be false")
    }
    
    func testFieldExtendedType() {
        let typeEnum = BTFieldExtendedType.customFormCover
        let id = typeEnum.mockFieldID
        let isForm = typeEnum.isForm
        XCTAssertTrue(isForm, "isForm should not be false")
        XCTAssertEqual(id, BTCustomFormCoverCell.reuseIdentifier, "shoule be equal")
    }
}
