//
//  BTFieldEditTest.swift
//  SKBitable_Tests-Unit-_Tests
//
//  Created by zoujie on 2022/5/27.
//  swiftlint:disable file_length


import XCTest
@testable import SKBitable
import SKFoundation
import SKCommon
import RxSwift
import RxCocoa
import SpaceInterface
@testable import SKFoundation
import SpaceInterface
import SKInfra
import SKUIKit
import WebKit

class BTFieldEditTest: XCTestCase {
    let baseContext = BaseContextImpl(baseToken: "", service: nil, permissionObj: nil, from: "")
    var dataService: DataService = DataService()
    var commonData: BTCommonData = {
        var commonData = BTCommonData()
        
        var fieldConfigItem = BTFieldConfigItem()
        fieldConfigItem.commonColorList = [
            BTColor(id: "inner_color_0", name: "xxx", color: [], type: .multi)
        ]
        fieldConfigItem.commonNumberFormatList = [
            BTNumberFieldFormat(formatCode: "0.0", name: "", sample: "", type: 0, formatterName: "")
        ]
        
        commonData.fieldConfigItem = fieldConfigItem
        
        return commonData
    }()
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        DocsContainer.shared.register(SKCommonDependency.self) {_ in
            return MockSKCommonDependency()
        }
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.field.progress", value: true)
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.field.rating", value: true)
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        UserScopeNoChangeFG.removeMockFG(key: "ccm.bitable.field.progress")
        UserScopeNoChangeFG.removeMockFG(key: "ccm.bitable.field.rating")
    }

    struct FieldEditModelTestError: Error {
        enum ErrorKind {
            case dataDeserializationFailure
        }
        let errorKind: ErrorKind
        let detail: String

        init(kind: ErrorKind, detail: String) {
            self.errorKind = kind
            self.detail = detail
        }
    }

    func testGetView() {
        let viewManger = BTFieldEditViewManager(commonData: BTCommonData(),
                                                fieldEditModel: BTFieldEditModel(),
                                                delegate: nil)

        var fieldEditModel = BTFieldEditModel()
        func singleGetSpecialView(by fieldType: BTFieldType, uiType: String?, hasView: Bool) {
            fieldEditModel.update(fieldType: fieldType, uiType: uiType)
            let view = viewManger.getView(commonData: BTCommonData(), fieldEditModel: fieldEditModel)
            XCTAssertTrue((view != nil) == hasView)
        }
        
        singleGetSpecialView(by: .autoNumber, uiType: BTFieldUIType.autoNumber.rawValue, hasView: true)
        singleGetSpecialView(by: .singleSelect, uiType: BTFieldUIType.singleSelect.rawValue, hasView: true)
        singleGetSpecialView(by: .text, uiType: BTFieldUIType.barcode.rawValue, hasView: true)
        fieldEditModel.fieldProperty.optionsType = .dynamicOption
        singleGetSpecialView(by: .singleSelect, uiType: BTFieldUIType.singleSelect.rawValue, hasView: true)
        
        singleGetSpecialView(by: .checkbox, uiType: BTFieldUIType.checkbox.rawValue, hasView: false)
        singleGetSpecialView(by: .notSupport, uiType: BTFieldUIType.notSupport.rawValue, hasView: false)
        singleGetSpecialView(by: .number, uiType: BTFieldUIType.currency.rawValue, hasView: true)
    }

    func testUpdateData() {
        let viewManger = BTFieldEditViewManager(commonData: BTCommonData(),
                                                fieldEditModel: BTFieldEditModel(),
                                                delegate: nil)

        var fieldEditModel = BTFieldEditModel()
        func singleTestUpdateData(by fieldType: BTFieldType, uiType: String?) {
            let compositeType = BTFieldCompositeType(fieldType: fieldType, uiTypeValue: uiType)
            fieldEditModel.update(fieldType: fieldType, uiType: uiType)
            let newModel = viewManger.updateData(commonData: BTCommonData(), fieldEditModel: fieldEditModel)
            XCTAssertTrue(newModel.compositeType == compositeType)
        }

        singleTestUpdateData(by: .autoNumber, uiType: nil)
        singleTestUpdateData(by: .number, uiType: nil)
        fieldEditModel.fieldProperty.optionsType = .dynamicOption
        singleTestUpdateData(by: .singleSelect, uiType: nil)
        singleTestUpdateData(by: .singleLink, uiType: nil)
        singleTestUpdateData(by: .dateTime, uiType: nil)
        singleTestUpdateData(by: .location, uiType: nil)
        singleTestUpdateData(by: .text, uiType: BTFieldUIType.barcode.rawValue)
    }

    func testGenerateJSONString() {
        let optionJSON = BTFieldEditUtil.generateOptionJSON(options: [BTOptionModel(id: "1",
                                                                                    name: "1",
                                                                                    color: 1),

                                                                      BTOptionModel(id: "2",
                                                                                    name: "2",
                                                                                    color: 2)])
        XCTAssertTrue(optionJSON.count == 2)

        let colorIdsJSON = BTFieldEditUtil.generateColorIdsJSON(options: [BTOptionModel(id: "3",
                                                                                        name: "3",
                                                                                        color: 3),
                                                                          BTOptionModel(id: "3",
                                                                                        name: "3",
                                                                                        color: 4)])

        XCTAssertTrue(colorIdsJSON.toJSONString() == ["colors": [3, 4]].toJSONString())

        let optionIdsJSON = BTFieldEditUtil.generateOptionIdsJSON(options: [BTOptionModel(id: "4",
                                                                                          name: "4",
                                                                                          color: 4),
                                                                            BTOptionModel(id: "5",
                                                                                          name: "5",
                                                                                          color: 5)])
        XCTAssertTrue(optionIdsJSON.count == 2)

        let autoNumberPreString = BTFieldEditUtil.generateAutoNumberPreString(auotNumberRuleList: [BTAutoNumberRuleOption(id: "1",
                                                                                                                          fixed: true,
                                                                                                                          type: .systemNumber,
                                                                                                                          value: "3",
                                                                                                                          title: "",
                                                                                                                          description: "",
                                                                                                                          optionList: []),
                                                                                                   BTAutoNumberRuleOption(id: "2",
                                                                                                                          fixed: true,
                                                                                                                          type: .fixedText,
                                                                                                                          value: "CCM",
                                                                                                                          title: "",
                                                                                                                          description: "",
                                                                                                                          optionList: []),
                                                                                                   BTAutoNumberRuleOption(id: "3",
                                                                                                                          fixed: true,
                                                                                                                          type: .createdTime,
                                                                                                                          value: "20220310",
                                                                                                                          title: "",
                                                                                                                          description: "",
                                                                                                                          optionList: [])])
        XCTAssertTrue("001CCM20220310" == autoNumberPreString)

    }

    func testDataTransform() {
        do {
            let model = try mockFieldEditModel()
            XCTAssertNotNil(model)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }


    //关联字段是否选择关联表单测
    func testCommonDataProperty() {
        var fieldData: BTFieldEditModel?
        do {
            fieldData = try mockFieldEditModel()
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }

        XCTAssertNotNil(fieldData)

        if var fieldData = fieldData {
            fieldData.update(fieldType: .singleSelect, uiType: BTFieldUIType.singleSelect.rawValue)
            let fieldVC = BTFieldEditController(fieldEditModel: fieldData,
                                                commonData: BTCommonData(),
                                                currentMode: .edit,
                                                sceneType: "grid_board",
                                                baseContext: baseContext,
                                                dataService: dataService)

            fieldVC.didClickItem(viewIdentify: "dynamicOptionsConjunctionSelect",
                                 index: 0)

            XCTAssertTrue(fieldVC.viewModel.dynamicOptionRuleConjunction == "and")

            let fieldFormat = BTDateFieldFormat()
            var commonData = BTFieldCommonData(id: fieldFormat.id, name: "")
            fieldVC.viewModel.commonData.fieldConfigItem.commonDateTimeList = [fieldFormat]
            fieldVC.didSelectedItem(commonData,
                                    relatedItemId: "",
                                    relatedView: BTFieldCustomButton(),
                                    action: "updateDateFormat",
                                    viewController: UIViewController())

            XCTAssertTrue(fieldVC.viewModel.fieldEditModel.fieldProperty.isMapDateFormat(fieldFormat))

            commonData.id = "0.0"
            fieldVC.didSelectedItem(commonData,
                                    relatedItemId: "",
                                    relatedView: BTFieldCustomButton(),
                                    action: "updateNumberFormat",
                                    viewController: UIViewController())

            XCTAssertTrue(fieldVC.viewModel.fieldEditModel.fieldProperty.formatter == "0.0")

            commonData.id = "fakeTableID"
            fieldVC.didSelectedItem(commonData,
                                    relatedItemId: "",
                                    relatedView: BTFieldCustomButton(),
                                    action: "updateRelatedTable",
                                    viewController: UIViewController())

            XCTAssertTrue(fieldVC.viewModel.fieldEditModel.fieldProperty.tableId == "fakeTableID")

            commonData.id = "3#SingleSelect"
            fieldVC.didSelectedItem(commonData,
                                    relatedItemId: "",
                                    relatedView: nil,
                                    action: "updateFieldType",
                                    viewController: UIViewController())

            XCTAssertTrue(fieldVC.viewModel.fieldEditModel.compositeType.uiType == .singleSelect)

        }
    }
    
    func testInitData() {
        var fieldData: BTFieldEditModel?
        do {
            fieldData = try mockFieldEditModel()
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }

        XCTAssertNotNil(fieldData)

        if var fieldData = fieldData {
            fieldData.update(fieldType: .autoNumber, uiType: "")
            
            var newAutoNumberRuleModel = BTAutoNumberRuleOption()
            newAutoNumberRuleModel.title = "creatTime"
            newAutoNumberRuleModel.type = .createdTime
            newAutoNumberRuleModel.value = "20220301"
            newAutoNumberRuleModel.id = "1"
            fieldData.fieldProperty.ruleFieldOptions = [newAutoNumberRuleModel]
            
            var commonData = BTCommonData()
            commonData.fieldConfigItem.commonAutoNumberRuleTypeList = [BTAutoNumberRuleTypeList(isAdvancedRules: true,
                                                                                                title: "creatTime",
                                                                                                description: "",
                                                                                                ruleFieldOptions: [BTAutoNumberRuleOption(type: .createdTime,
                                                                                                                                          optionList: [BTAutoNumberRuleDateModel(format: "20220301",
                                                                                                                                                                                 text: "2022-03-01")]
                                                                                                                                         )]
                                                                                               )]
            let viewModel1 = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: commonData, dataService: dataService)

            XCTAssertTrue(viewModel1.auotNumberRuleList.count == 1)

            fieldData.update(fieldType: .singleLink, uiType: "")
            let viewModel2 = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)
            
            XCTAssertTrue(viewModel2.fieldEditModel.isLinkAllRecord)
        }
    }

    //关联字段是否选择关联表单测
    func testLinkTableVerify() {
        var fieldData: BTFieldEditModel?
        do {
            fieldData = try mockFieldEditModel()
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }

        XCTAssertNotNil(fieldData)

        if var fieldData = fieldData {
            fieldData.update(fieldType: .duplexLink, uiType: BTFieldUIType.duplexLink.rawValue)
            fieldData.fieldProperty.tableId = ""
            let viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)

            XCTAssertFalse(viewModel.verifyData())
        }
    }

    //自动编号规则单测
    func testAutoNumberVerify() {
        var fieldData: BTFieldEditModel?
        do {
            fieldData = try mockFieldEditModel()
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }

        XCTAssertNotNil(fieldData)

        if var fieldData = fieldData {
            fieldData.update(fieldType: .autoNumber, uiType: BTFieldUIType.autoNumber.rawValue)
            let viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)

            viewModel.editingFieldCellHasErrorIndexs = [1]

            XCTAssertFalse(viewModel.verifyData())
        }
    }

    private func mockFieldEditModel() throws -> BTFieldEditModel {
        return MockJSONDataManager.getHandyJSONModelByParseData(filePath: "JSONDatas/fieldEditData")
    }
}

extension BTFieldEditTest {
    //级联选项数据验证单测
    func testDynamicOptionsVerify() {
        var fieldData: BTFieldEditModel?
        do {
            fieldData = try mockFieldEditModel()
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }

        XCTAssertNotNil(fieldData)

        if var fieldData = fieldData {
            fieldData.update(fieldType: .singleSelect, uiType: BTFieldUIType.singleSelect.rawValue)
            fieldData.fieldProperty.optionsType = .dynamicOption
            
            var viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)

            let (buttons, errorMsg) = viewModel.configConditionButtons(viewModel.dynamicOptionsConditions[0])
            XCTAssertTrue(buttons.count == 3)
            XCTAssertFalse(errorMsg.isEmpty)

            fieldData.fieldProperty.optionsRule.targetTable = ""
            viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)

            XCTAssertFalse(viewModel.verifyTargetTable())


            fieldData.fieldProperty.optionsRule.targetField = ""
            viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)

            XCTAssertFalse(viewModel.verifyTargetField())

            viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)

            XCTAssertTrue(viewModel.verifyCondition())
        }
    }
    
    func testGetFieldOperators() {
        var fieldData: BTFieldEditModel?
        do {
            fieldData = try mockFieldEditModel()
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }

        XCTAssertNotNil(fieldData)

        if let fieldData = fieldData {
            let viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)
            viewModel.fieldEditModel.tableId = "mock"
            viewModel.dynamicOptionRuleTargetTable = "mock"

            let expect = expectation(description: "testGetFieldOperators")
            viewModel.getFieldOperators(tableId: "mock",
                                        fieldId: nil,
                                        needUpdate: true,
                                        completion: {
                expect.fulfill()
                XCTAssertTrue(viewModel.commonData.linkTableFieldOperators.count == 2)
                XCTAssertTrue(viewModel.commonData.currentTableFieldOperators.count == 2)
            })

            waitForExpectations(timeout: 0.2) { error in
                XCTAssertNil(error)
            }
        }
    }
    
    func testGetNewFieldID() {
        var fieldData: BTFieldEditModel?
        do {
            fieldData = try mockFieldEditModel()
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }

        XCTAssertNotNil(fieldData)

        if let fieldData = fieldData {
            let viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)
            
            let expect = expectation(description: "testGetFieldOperators")
            viewModel.getNewFieldID(tableID: "") { fieldId in
                expect.fulfill()
                XCTAssertTrue(fieldId == "mockFieldID")
            }

            waitForExpectations(timeout: 0.2) { error in
                XCTAssertNil(error)
            }
        }
    }
    
    func testAddOptionItem() {
        var fieldData: BTFieldEditModel?
        do {
            fieldData = try mockFieldEditModel()
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }

        XCTAssertNotNil(fieldData)

        if let fieldData = fieldData {
            let viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)
            
            viewModel.dynamicOptionsEnable = true
            viewModel.fieldEditModel.update(fieldType: .singleSelect, uiType: BTFieldUIType.singleSelect.rawValue)
            viewModel.fieldEditModel.fieldProperty.optionsType = .dynamicOption
            let expect = expectation(description: "testGetFieldOperators")
            expect.expectedFulfillmentCount = 2
            viewModel.didAddOptionItem() { itemId in
                expect.fulfill()
                XCTAssertTrue(itemId == "mockConditionId")
            }
            
            viewModel.fieldEditModel.fieldProperty.optionsType = .staticOption
            viewModel.didAddOptionItem() { itemId in
                expect.fulfill()
                XCTAssertTrue(itemId == "mockOptionId")
            }
            
            waitForExpectations(timeout: 0.4) { error in
                XCTAssertNil(error)
            }
        }
    }
    
    func startTestCommitChangeProperty(fieldType: BTFieldType, uiType: String?) {
        var fieldData = BTFieldEditModel()
        fieldData.update(fieldType: fieldType, uiType: uiType)
        let commonData = BTCommonData()
        let viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: commonData, dataService: dataService)
        let viewController = BTFieldEditController(fieldEditModel: fieldData, commonData: commonData, currentMode: .edit, sceneType: "", baseContext: baseContext, dataService: nil)
        viewModel.updateCurrentFieldEditConfig(viewController: viewController)
    
        var notNilParams: [String] = []
        switch fieldType {
        case .number:
            notNilParams = ["formatter"]
            if uiType == BTFieldUIType.currency.rawValue {
                notNilParams = ["currencyCode"]
            } else if uiType == BTFieldUIType.progress.rawValue {
                notNilParams.append("rangeCustomize")
                notNilParams.append("min")
                notNilParams.append("max")
            } else if uiType == BTFieldUIType.rating.rawValue {
                notNilParams.append("min")
                notNilParams.append("max")
                notNilParams.append("enumerable")
                notNilParams.append("rangeLimitMode")
                notNilParams.append("rating")
            }
        case .singleSelect:
            fieldData.fieldProperty.optionsType = .dynamicOption
            notNilParams = ["optionsRule"]
        case .dateTime:
            fieldData.fieldProperty.autoFill = false
            notNilParams = ["autoFill"]
        case .user:
            notNilParams = ["multiple"]
        case .attachment:
            notNilParams = ["capture"]
        case .duplexLink:
            fieldData.isLinkAllRecord = false
            fieldData.fieldProperty.filterInfo = BTFilterInfos()
            notNilParams = ["filterInfo"]
        case .location:
            notNilParams = ["inputType"]
        case .autoNumber:
            fieldData.fieldProperty.isAdvancedRules = true
            notNilParams = ["ruleFieldOptions"]
        default:
            break
        }
        
        viewModel.fieldEditModel = fieldData
        let params = viewModel.createNormalCommitChangeProperty()
        notNilParams.forEach { key in
            XCTAssertNotNil(params[key])
        }
        print("prevent release", viewController.currentMode)
    }
    
    func testCreateNormalCommitChangeProperty() {
        startTestCommitChangeProperty(fieldType: .dateTime, uiType: BTFieldUIType.dateTime.rawValue)
        startTestCommitChangeProperty(fieldType: .duplexLink, uiType: BTFieldUIType.duplexLink.rawValue)
        startTestCommitChangeProperty(fieldType: .autoNumber, uiType: BTFieldUIType.autoNumber.rawValue)
        startTestCommitChangeProperty(fieldType: .singleSelect, uiType: BTFieldUIType.singleSelect.rawValue)
        startTestCommitChangeProperty(fieldType: .attachment, uiType: BTFieldUIType.attachment.rawValue)
        startTestCommitChangeProperty(fieldType: .number, uiType: BTFieldUIType.number.rawValue)
        startTestCommitChangeProperty(fieldType: .user, uiType: BTFieldUIType.user.rawValue)
        startTestCommitChangeProperty(fieldType: .location, uiType: BTFieldUIType.location.rawValue)
        startTestCommitChangeProperty(fieldType: .number, uiType: BTFieldUIType.currency.rawValue)
        startTestCommitChangeProperty(fieldType: .number, uiType: BTFieldUIType.progress.rawValue)
        startTestCommitChangeProperty(fieldType: .number, uiType: BTFieldUIType.rating.rawValue)
    }
    
    func testProgressVerify() {
        var fieldData = BTFieldEditModel()
        fieldData.fieldProperty.rangeCustomize = true
        fieldData.fieldProperty.min = nil
        fieldData.fieldProperty.max = 100
        var viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)
        var result = viewModel.verifyProgress()
        XCTAssertFalse(result.isValid)
        
        fieldData.fieldProperty.min = 0
        fieldData.fieldProperty.max = nil
        viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)
        result = viewModel.verifyProgress()
        XCTAssertFalse(result.isValid)
        
        fieldData.fieldProperty.min = 100
        fieldData.fieldProperty.max = 100
        viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)
        result = viewModel.verifyProgress()
        XCTAssertFalse(result.isValid)
        
        fieldData.fieldProperty.min = 100
        fieldData.fieldProperty.max = 0
        viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)
        result = viewModel.verifyProgress()
        XCTAssertFalse(result.isValid)
        
        fieldData.fieldProperty.min = 0
        fieldData.fieldProperty.max = 100
        viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)
        result = viewModel.verifyProgress()
        XCTAssert(result.isValid)
    }
    
    func testResetNumberProperty() {
        var fieldData = BTFieldEditModel()
        fieldData.fieldProperty.formatter = "0.00%"
        var viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: commonData, dataService: dataService)
        viewModel.resetNumberFieldProperty()
        XCTAssertEqual(viewModel.fieldEditModel.fieldProperty.formatter, "0.0")
    }
    
    func testResetProgressProperty() {
        var fieldData = BTFieldEditModel()
        fieldData.fieldProperty.formatter = "0.00%"
        fieldData.fieldProperty.min = -100
        fieldData.fieldProperty.max = 1000
        fieldData.fieldProperty.rangeCustomize = true
        fieldData.fieldProperty.progress = BTProgressModel(color: BTColor(id: "xxx", name: "xxx"))
        
        var viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: commonData, dataService: dataService)
        viewModel.resetProgressFieldProperty()
        XCTAssertEqual(viewModel.fieldEditModel.fieldProperty.formatter, "0")
        XCTAssertEqual(viewModel.fieldEditModel.fieldProperty.min, 0)
        XCTAssertEqual(viewModel.fieldEditModel.fieldProperty.max, 100)
        XCTAssertEqual(viewModel.fieldEditModel.fieldProperty.rangeCustomize, false)
    }
    
    func testVerifyLinkFieldCommitData() {
        var fieldData = BTFieldEditModel()
        fieldData.update(fieldType: .duplexLink, uiType: BTFieldUIType.duplexLink.rawValue)
        fieldData.fieldProperty.tableId = "mock_tableId"
        fieldData.tableNameMap = [BTFieldRelatedForm(tableName: "mock", tableId: "mock_tableId")]
        fieldData.isLinkAllRecord = false
        fieldData.fieldProperty.filterInfo = BTFilterInfos(conditions: [BTFilterCondition(conditionId: "mock",
                                                                                          fieldId: "mock_fieldId",
                                                                                          fieldType: 21,
                                                                                         value: ["mock_recordId", "mock_recordId1"])])
        
        let viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)
        
        let (isValid, _) = viewModel.verifyLinkFieldCommitData()
        XCTAssertFalse(isValid)
    }
    
    func testAutoNumberShouldShowConfirmPanel() {
        var fieldData = BTFieldEditModel()
        fieldData.update(fieldType: .autoNumber, uiType: BTFieldUIType.autoNumber.rawValue)
        fieldData.fieldProperty.isAdvancedRules = true
        fieldData.fieldProperty.ruleFieldOptions = [BTAutoNumberRuleOption(id: "1",
                                                                           type: .fixedText,
                                                                           value: "mock1")]
        
        let viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)
        
        viewModel.fieldEditModel.fieldProperty.ruleFieldOptions = [BTAutoNumberRuleOption(id: "1",
                                                                                          type: .fixedText,
                                                                                          value: "mock2")]

        XCTAssertTrue(viewModel.autoNumberShouldShowConfirmPanel())
    }
    
    func testSetAutoNumberReformatExistingRecord() {
        var fieldData = BTFieldEditModel()
        fieldData.update(fieldType: .autoNumber, uiType: BTFieldUIType.autoNumber.rawValue)
        fieldData.fieldProperty.isAdvancedRules = true
        
        let viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)
        
        viewModel.fieldEditModel.fieldProperty.isAdvancedRules = false
        viewModel.setAutoNumberReformatExistingRecord()

        XCTAssertTrue(viewModel.fieldEditModel.fieldProperty.reformatExistingRecord)
    }
    
    func generateFieldEditViewModel(fieldData: BTFieldEditModel) -> BTFieldEditViewModel {
        var commonData = BTCommonData()
        commonData.fieldConfigItem.commonCurrencyCodeList = [BTCurrencyCodeList(currencyCode: "CNY",
                                                                                currencySymbol: "¥",
                                                                                name: "人民币",
                                                                                formatCode: "¥"),
                                                             BTCurrencyCodeList(currencyCode: "USD",
                                                                                currencySymbol: "$",
                                                                                name: "美元",
                                                                                formatCode: "$")]
        
        commonData.fieldConfigItem.commonCurrencyDecimalList = [BTNumberFieldFormat(formatCode: "#,##0.0",
                                                                                    name: "1位",
                                                                                    sample: "1000.0",
                                                                                    formatterName: "digital_round_1")]
        
        return BTFieldEditViewModel(fieldEditModel: fieldData,
                                    commonData: commonData,
                                    dataService: dataService)
    }
    
    func testInitCurrencyProperty() {
        var fieldData = BTFieldEditModel()
        fieldData.update(fieldType: .number, uiType: "Currency")
        
        let viewModel = generateFieldEditViewModel(fieldData: fieldData)
        viewModel.initCurrencyProperty()
        
        XCTAssertTrue(viewModel.fieldEditModel.fieldProperty.currencyCode == "CNY")
        XCTAssertTrue(viewModel.fieldEditModel.fieldProperty.formatter == "¥#,##0.0")
    }
    
    func testUpdateCurrencyProperty() {
        var fieldData = BTFieldEditModel()
        fieldData.update(fieldType: .number, uiType: "Currency")
        
        let viewModel = generateFieldEditViewModel(fieldData: fieldData)
        viewModel.initCurrencyProperty()
        
        viewModel.updateCurrencyProperty(formatter: "¥#,##0.0", currencyCode: "USD")
        
        XCTAssertTrue(viewModel.fieldEditModel.fieldProperty.currencyCode == "USD")
        XCTAssertTrue(viewModel.fieldEditModel.fieldProperty.formatter == "$#,##0.0")
    }
    
    func testNumberToCurrencyAndCurrency() {
        var fieldData = BTFieldEditModel()
        fieldData.update(fieldType: .number, uiType: BTFieldUIType.number.rawValue)
        
        let viewModel = generateFieldEditViewModel(fieldData: fieldData)
        viewModel.fieldEditModel.fieldProperty.formatter = "0.0"
        
        viewModel.covertNumberAndCurrency(fieldType: .number, uiType: "Currency")

        XCTAssertTrue(viewModel.fieldEditModel.fieldProperty.formatter == "¥#,##0.0")
    }
    func testFieldEditViewModelIsFunction() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.mobile.support_remote_compute", value: true)
        var fieldData: BTFieldEditModel?
        do {
            fieldData = try mockFieldEditModel()
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
        if var fieldData = fieldData {
            fieldData.update(fieldType: .duplexLink, uiType: BTFieldUIType.duplexLink.rawValue)
            fieldData.fieldProperty.tableId = ""
            let viewModel = BTFieldEditViewModel(fieldEditModel: fieldData, commonData: BTCommonData(), dataService: dataService)
            print(viewModel.isDynamicPartNoPerimission, viewModel.dynamicTableReadPerimission, viewModel.dynamicTableReadPerimission, viewModel.dynamicTableReadPerimission, viewModel.isDynamicFieldDenied, viewModel.isDynamicTablePartialDenied, viewModel.linkTableReadPerimission, viewModel.isLinkTablePartialDenied)
            XCTAssertFalse(false)
        }
    }
    func testExtendState() {
        var fieldData = BTFieldEditModel()
        fieldData.fieldExtendInfo = FieldExtendInfo(editable: false)
        var viewModel = generateFieldEditViewModel(fieldData: fieldData)

        viewModel.fieldEditModel.editNotice = .noExtendFieldPermForOwner
        XCTAssertTrue(viewModel.fieldExtendRefreshState == .disable)

        viewModel.fieldEditModel.editNotice = .noExtendFieldPermForUser
        XCTAssertTrue(viewModel.fieldExtendRefreshState == .disable)

        viewModel.fieldEditModel.editNotice = .originMultipleEnable
        XCTAssertTrue(viewModel.fieldExtendRefreshState == .disable)

        viewModel.fieldEditModel.editNotice = .originDeleteForOwner
        XCTAssertTrue(viewModel.fieldExtendRefreshState == .hidden)

        viewModel.fieldEditModel.editNotice = .originDeleteForUser
        XCTAssertTrue(viewModel.fieldExtendRefreshState == .hidden)

        viewModel.fieldEditModel.editNotice = nil
        viewModel.fieldEditModel.fieldExtendInfo = FieldExtendInfo(editable: true)
        XCTAssertTrue(viewModel.fieldExtendRefreshState == .hidden)

        viewModel.fieldEditModel.fieldExtendInfo = FieldExtendInfo(editable: false)
        XCTAssertTrue(viewModel.fieldExtendRefreshState == .hidden)
        
        viewModel.fieldEditModel.fieldId = "mockId"
        XCTAssertTrue(viewModel.fieldExtendRefreshState == .disable)

        fieldData = BTFieldEditModel()
        fieldData.fieldExtendInfo = FieldExtendInfo(editable: true)
        viewModel = generateFieldEditViewModel(fieldData: fieldData)
        viewModel.fieldEditModel.fieldId = "mockId"
        XCTAssertTrue(viewModel.fieldExtendRefreshState == .normal)

        let args = viewModel.getJSFieldInfoArgs(editMode: .add, fieldEditModel: fieldData)
        XCTAssertTrue(args.allowEditModes == fieldData.allowedEditModes)
        XCTAssertTrue(args.extendInfo == fieldData.fieldExtendInfo?.extendInfo)
    }
}


class MockSKCommonDependency: SKCommonDependency {
    
    var allDocsWebViews: [SKUIKit.DocsWebViewV2] {
        let config = WKWebViewConfiguration()
        return [DocsWebViewV2(frame: .zero, configuration: config)]
    }
    
    func createCompleteV2(token: String, type: SpaceInterface.DocsType, source: SKFoundation.FromSource?, ccmOpenType: SKFoundation.CCMOpenType?, templateCenterSource: SKCommon.SKCreateTracker.TemplateCenterSource?, templateSource: SKCommon.TemplateCenterTracker.TemplateSource?, moduleDetails: [String : Any]?, templateInfos: [String : Any]?, extra: [String : Any]?) -> UIViewController? {
        return nil
    }
    

    var currentEditorView: UIView? {
        return nil
    }

    var browsersStackIsEmptyObsevable: BehaviorRelay<Bool> {
        return BehaviorRelay(value: false)
    }

    var browserViewWidth: CGFloat {
        return 200
    }

    func changeVConsoleState(_ isOpen: Bool) {}

    func editorPoolDrainAndPreload() {}

    func createDefaultWebViewController(url: URL) -> UIViewController {
        return UIViewController()
    }
    
    func resetWikiDB() {}

    func getWikiStorageObserver() -> SimpleModeObserver? {
        return nil
    }

    func setWikiMeta(wikiToken: String, completion: @escaping (WikiInfo?, Error?) -> Void) {}

    func getSKOnboarding() -> Observable<[String: Bool]> {
        return .just([:])
    }

    func doneSKOnboarding(keys: [String]) {}
}
