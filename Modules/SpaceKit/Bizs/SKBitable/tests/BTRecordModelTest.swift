//
// Created by duanxiaochen.7 on 2022/6/27.
// Affiliated with SKBitable_Tests-Unit-_Tests.
//
// Description:

import XCTest
@testable import SKBitable
@testable import SKFoundation

class BTRecordModelTest: XCTestCase {
    override func setUp() {
        super.setUp()
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.nopermission", value: true)
        UserScopeNoChangeFG.setMockFG(key: "bitable.pricing.recordsnumandgantt.fe", value: true)
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.card_reform", value: true)
    }

    override func tearDown() {
        super.tearDown()
        UserScopeNoChangeFG.removeMockFG(key: "ccm.bitable.nopermission")
        UserScopeNoChangeFG.removeMockFG(key: "ccm.bitable.card_reform")
        UserScopeNoChangeFG.removeMockFG(key: "bitable.pricing.recordsnumandgantt.fe")
    }

    func testFieldMeta() {
        let meta = BTFieldMeta()
        var newMeta = BTFieldMeta()
        newMeta.id = "new"

        XCTAssertFalse(meta == newMeta)
    }


    func testFieldProperty() {
        let model = BTFieldProperty()
        var newModel = BTFieldProperty()
        newModel.optionsType = .dynamicOption

        XCTAssertFalse(model == newModel)
                
        newModel.isAdvancedRules = true
        newModel.optionsType = .staticOption
        
        var newAutoNumberRuleModel = BTAutoNumberRuleOption()
        newAutoNumberRuleModel.title = "autoIncrease"
        newAutoNumberRuleModel.type = .systemNumber
        newAutoNumberRuleModel.value = "3"
        newAutoNumberRuleModel.id = "1"
        newModel.ruleFieldOptions = [newAutoNumberRuleModel]
        
        XCTAssertFalse(model == newModel)
        
        newModel.isAdvancedRules = false
        XCTAssertTrue(model == newModel)
    }

    func testFieldDescriptionModel() {
        let model = BTDescriptionModel()
        var newModel = BTDescriptionModel()
        newModel.disableSync = true

        XCTAssertFalse(model == newModel)
    }

    func testOptionModel() {
        let model = BTOptionModel()
        var newModel = BTOptionModel()
        newModel.id = "new"

        XCTAssertFalse(model == newModel)


        let dynamicModel = BTDynamicOptionRuleModel()
        var newDynamicModel = BTDynamicOptionRuleModel()
        newDynamicModel.targetTable = "new"

        XCTAssertFalse(dynamicModel == newDynamicModel)


        let conditionModel = BTDynamicOptionConditionModel()
        var newConditionModel = BTDynamicOptionConditionModel()
        newConditionModel.conditionId = "new"

        XCTAssertFalse(conditionModel == newConditionModel)
    }

    func testModelUpdate() {
        var model = BTRecordModel()
        let fieldModel = BTFieldModel(recordID: "new")
        model.update(fields: [fieldModel])
        XCTAssertTrue(model.wrappedFields == [fieldModel])
        
        model.update(canShareRecord: true)
        XCTAssertTrue(model.shareable)

        model.update(fieldID: "mockFieldId", buttonStatus: .loading)
        XCTAssertTrue(model.buttonFieldStatus["mockFieldId"] == .loading)
        model.update(topTip: .recordLimit)
        XCTAssert(model.topTipType == .recordLimit)
        var colorModel = BTButtonColorModel(id: 0)
        colorModel.styles = [BTButtonFieldStatus.loading.rawValue: BTButtonColorModel.ButtonColor(bgColor: "mockBgColor")]
        model.update(buttonColors: [colorModel])
        XCTAssertTrue(model.buttonColors.count == 1)
    }
    
    func testSubmitToopTips() {
        var model = BTRecordModel()
        var meta = BTTableMeta()
        meta.viewType = "form"
        meta.viewUnreadableRequiredField = true
        let value = BTRecordValue()
        model.update(meta: meta, value: value, mode: .form, holdDataProvider: nil)
        model.update(shouldShowSubmitTopTip: true)
        XCTAssertTrue(model.shouldShowSubmitTopTip == true)
    }
    
    func testReocrdLimitWithNoFields() {
        var model = BTRecordModel()
        var meta = BTTableMeta()
        let value = BTRecordValue()
        meta.viewType = "form"
        model.update(topTip: .recordLimit)
        model.update(meta: meta, value: value, mode: .form, holdDataProvider: nil)
        XCTAssert(model.wrappedFields.contains(where: { filed in
            return filed.extendedType == .recordCountOverLimit
        }))
    }
    
    func testReocrdLimitWithWithFields() {
        var model = BTRecordModel()
        var meta = BTTableMeta()
        var value = BTRecordValue()
        let fieldValue = BTFieldValue(id: "mockField", editable: true)
        value.fields = [fieldValue]
        var fieldMeta = BTFieldMeta()
        fieldMeta.id = "mockField"
        fieldMeta.name = "Text"
        meta.fields["mockField"] = fieldMeta
        meta.viewType = "form"
        model.update(topTip: .recordLimit)
        model.update(meta: meta, value: value, mode: .form, holdDataProvider: nil)
        XCTAssert(model.wrappedFields.contains(where: { filed in
            return filed.extendedType == .recordCountOverLimit
        }))
    }
    
    func testItemViewTabs() {
        var model = BTRecordModel()
        var meta = BTTableMeta()
        var value = BTRecordValue()
        let fieldValue = BTFieldValue(id: "mockField", editable: true)
        value.fields = [fieldValue]
        
        let fieldMetaParams: [String: Any] = ["type": 24,
                                              "fieldUIType": "Stage"]
        
        guard var fieldMeta = BTFieldMeta.deserialize(from: fieldMetaParams) else {
            XCTAssertTrue(false)
            return
        }
        
        fieldMeta.id = "mockField"
        fieldMeta.name = "Stage"
        meta.fields["mockField"] = fieldMeta
        
        model.update(meta: meta, value: value, mode: .card, holdDataProvider: nil)
        
        XCTAssertTrue(model.shouldShowItemViewTabs)
        XCTAssertNotNil(model.itemViewTabs.first(where: { $0.name == "Stage" }))
    }
}
