//
// Created by duanxiaochen.7 on 2022/6/27.
// Affiliated with SKBitable_Tests-Unit-_Tests.
//
// Description:

import XCTest
@testable import SKBitable
@testable import SKFoundation
import SKCommon

private let mockFGKeyFormSupportFormula = "ccm.bitable.form_support_formula"
private let mockFGKeyStageField = "ccm.bitable.field.stage"

class BTFieldModelTest: XCTestCase {
    
    var tableModel: BTTableModel?
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        UserScopeNoChangeFG.setMockFG(key: mockFGKeyFormSupportFormula, value: true)
        UserScopeNoChangeFG.setMockFG(key: mockFGKeyStageField, value: true)
        if let tableModel = try? creatMockTableModel() {
            self.tableModel = tableModel
        }
    }

    override func tearDown() {
        super.tearDown()
        UserScopeNoChangeFG.removeMockFG(key: mockFGKeyFormSupportFormula)
        UserScopeNoChangeFG.removeMockFG(key: mockFGKeyStageField)
        AssertionConfigForTest.reset()
    }

    func testUpdatingFieldModel() {
        var field = BTFieldModel(recordID: "mockRecordId")
        _ = field.updating(hiddenCount: 2, isDisclosed: true)
        XCTAssertTrue(field.hiddenFieldsCount == 2)
        XCTAssertTrue(field.isHiddenFieldsDisclosed == true)
        XCTAssertTrue(field.extendedType == .hiddenFieldsDisclosure)
        
        _ = field.updating(formElementType: .formSubmit)
        XCTAssertTrue(field.extendedType == .formSubmit)
        XCTAssertTrue(field.isInForm == true)
        
        field.update(buttonStatus: .loading)
        XCTAssertTrue(field.buttonConfig.status == .loading)
    }
    
    func testResolveUIData() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.mobile.support_remote_compute", value: true)
        var field = BTFieldModel(recordID: "mockRecordId")
        
        let fieldMetaParams: [String: Any] = ["type": 3001,
                                              "fieldUIType": "Button",
                                              "property": ["button": ["title": "mock", "color": 1],
                                                           "isTriggerEnabled": true]]
        
        guard let fieldMeta = BTFieldMeta.deserialize(from: fieldMetaParams) else {
            XCTAssertTrue(false)
            return
        }
        
        field.update(meta: fieldMeta, value: BTFieldValue(), holdDataProvider: nil)
        
        XCTAssertTrue(field.property.isTriggerEnabled == true)
    }
    
    func testUpdateFormBannerUrl() {
        var field = BTFieldModel(recordID: "mockRecordId")
        field.update(formBannerUrl: "")
    }
    
    func testUpdateFieldPermission() {
        var field = BTFieldModel(recordID: "mockRecordId")
        var fieldPermission = BTFieldValue.FieldPermission()
        fieldPermission.stageConvert = ["mockStageOptionId": true]
        field.update(fieldPermission: fieldPermission)
        
        XCTAssertTrue(field.fieldPermission == fieldPermission)
    }
    
    func testStageFieldTab() {
        var field = BTFieldModel(recordID: "mockRecordId")
        let fieldMetaParams: [String: Any] = ["type": 24,
                                              "fieldUIType": "Stage"]
        
        guard let fieldMeta = BTFieldMeta.deserialize(from: fieldMetaParams) else {
            XCTAssertTrue(false)
            return
        }
        
        field.update(meta: fieldMeta, value: BTFieldValue(), holdDataProvider: nil)
        field.update(fieldUneditableReason: .drillDown)
        
        XCTAssertFalse(field.shouldShowOnTabs)
    }
}

extension BTFieldModelTest {
    
    func testFixSelectedRange() {
//        let textView = BTTextView()
//        guard let record = tableModel?.records.first(where: { $0.recordID == "recWIh2U94" }),
//              let field = record.wrappedFields.first(where: { $0.fieldID == "fldL3P4nfs" }) else {
//            XCTAssertFalse(false, "table data error")
//            return
//        }
//        let attributeString = BTUtil.convert(field.textValue)
//
//        textView.attributedText = attributeString
//        let lastSelectedRange = NSRange(location: 0, length: 5)
//
//        //let urlRange = NSRange(location: 10, length: 54)
//        textView.selectedRange = NSRange(location: 0, length: 11)
//        FixSelectedRangeAdapter.fixSelectedRange(textView: textView,
//                                                 lastSelectedRange: lastSelectedRange,
//                                                 currenSelectedRange: textView.selectedRange,
//                                                 attributedString: attributeString,
//                                                 attributedStringKey: AtInfo.attributedStringURLKey)
//        XCTAssertFalse(textView.selectedRange != NSRange(location: 0, length: 64), "urlRange head fix error")
//
//        textView.selectedRange = NSRange(location: 11, length: 56)
//        FixSelectedRangeAdapter.fixSelectedRange(textView: textView,
//                                                 lastSelectedRange: lastSelectedRange,
//                                                 currenSelectedRange: textView.selectedRange,
//                                                 attributedString: attributeString,
//                                                 attributedStringKey: AtInfo.attributedStringURLKey)
//        XCTAssertFalse(textView.selectedRange != NSRange(location: 10, length: 57), "urlRange trail fix error")
//
//
//        //let atInfoRanage = NSRange(location: 94, length: 20)
//        textView.selectedRange = NSRange(location: 90, length: 10)
//        FixSelectedRangeAdapter.fixSelectedRange(textView: textView,
//                                                 lastSelectedRange: lastSelectedRange,
//                                                 currenSelectedRange: textView.selectedRange,
//                                                 attributedString: attributeString,
//                                                 attributedStringKey: BTRichTextSegmentModel.attrStringBTAtInfoKey)
//        XCTAssertFalse(textView.selectedRange != NSRange(location: 90, length: 24), "atRange head fix error")
//
//        textView.selectedRange = NSRange(location: 95, length: 30)
//        FixSelectedRangeAdapter.fixSelectedRange(textView: textView,
//                                                 lastSelectedRange: lastSelectedRange,
//                                                 currenSelectedRange: textView.selectedRange,
//                                                 attributedString: attributeString,
//                                                 attributedStringKey: BTRichTextSegmentModel.attrStringBTAtInfoKey)
//        XCTAssertFalse(textView.selectedRange != NSRange(location: 94, length: 31), "atRange trail fix error")
    }
}
