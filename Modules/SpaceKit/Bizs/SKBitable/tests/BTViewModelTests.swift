//
//  BTViewModelTests.swift
//  SKBitable_Tests-Unit-_Tests
//
//  Created by ZhangYuanping on 2022/4/27.
//  swiftlint:disable file_length


import XCTest
@testable import SKBitable
import RxSwift
import RxCocoa
import SKCommon
import SKFoundation
import SKBrowser
@testable import SKFoundation

class DataService: BTDataService {
    func triggerRecordSubscribeForSubmitIfNeeded(recordId: String) {}
    
    var holdDataProvider: SKBitable.BTHoldDataProvider?
    
    func quickAddViewClick(args: SKBitable.BTSaveFieldArgs) {
    }
    
    func fetchLinkCardList(args: BTJSFetchLinkCardArgs,
                           resultHandler: @escaping (SKBitable.BTTableValue?, Error?) -> Void) {
        
    }
    
    var isRecordEmpty: Bool = false
    var isLoading: Bool = false
    
    var mockTableValue: BTTableValue {
        var value = BTTableValue()
        if let _value = try? mockGetTableValue() {
            value = _value
        }
        if isRecordEmpty {
            value.records = []
        }
        return value
    }
    
    var mockTableMeta: BTTableMeta {
        var meta = BTTableMeta()
        if let _meta = try? mockGetTableMeta() {
            meta = _meta
        }
        return meta
    }

    func getTableRecordIDList(baseID: String, tableID: String, fieldID: String, resultHandler: @escaping (BTTableRecordIDList?, Error?) -> Void) {
        resultHandler(BTTableRecordIDList(), nil)
    }
    
    func searchRecordsByKeyword(args: BTJSSearchRecordsArgs, resultHandler: @escaping ([String]?, Error?) -> Void) {
        resultHandler(args.fieldIDs, nil)
    }
    
    func fetchRecords(baseID: String,
                      tableID: String,
                      recordIDs: [String],
                      fieldIDs: [String]?,
                      resultHandler: @escaping (BTTableValue?, Error?) -> Void) {
        if isRecordEmpty {
            resultHandler(BTTableValue(loaded: true), nil)
            return
        }
        
        if isLoading {
            resultHandler(BTTableValue(loaded: false), nil)
            return
        }
        
        resultHandler(BTTableValue(loaded: true, records: mockTableValue.records), nil)
    }
    
    func fetchTableMeta(baseID: String, tableID: String, viewID: String, viewMode: BTViewMode, fieldIds: [String], resultHandler: @escaping (BTTableMeta?, Error?) -> Void) {
        resultHandler(mockTableMeta, nil)
    }
    
    func getViewType(tableID: String?, viewID: String?, resultHandler: @escaping (String?) -> Void) {
        resultHandler("form")
    }
    
    func executeCommands(args: BTExecuteCommandArgs, resultHandler: @escaping (BTExecuteFailReson?, Error?) -> Void) {
        resultHandler(nil, nil)
    }
    func getViewMeta(viewId: String, tableId: String, extra: [String: Any]?, responseHandler: @escaping (Result<BTViewMeta, Error>) -> Void) {
        let dic1: [String: Any] = [
            "property": ""
        ]
        let data1: Data = try! JSONSerialization.data(withJSONObject: dic1)
        let decode1 = JSONDecoder()
        let viewMeta1: BTViewMeta = try! decode1.decode(BTViewMeta.self, from: data1)
        responseHandler(.success(viewMeta1))
    }
    
    func checkConfirmAPI(args: BTCheckConfirmAPIArgs, resultHandler: @escaping (Result<CheckConfirmResult, Error>) -> Void) {
        resultHandler(.success(CheckConfirmResult(type: .SetFieldAttr, extra: nil)))
    }
    
    func showAiConfigFormAPI(args: BTShowAiConfigFormArgs, completion:  @escaping () -> Void) {

    }
    
    func hideAiConfigFormAPI(args: BTHideAiConfigFormArgs, completion:  @escaping () -> Void) {
        
    }
    
    func checkFieldTypeChangeAPI(args: BTFieldTypeChangeArgs, completion:  @escaping ([String: Any]) -> Void) {
        
    }
    
    func openAiPrompt() {
        
    }
    
    func getBitableCommonData(args: BTGetBitableCommonDataArgs, resultHandler: @escaping (Any?, Error?) -> Void) {
        switch args.type {
        case .getNewFieldId:
            resultHandler(["fieldId": "mockFieldID"], nil)
        case .getFieldList:
            resultHandler([["id": "mockID1",
                            "name": "mockName1",
                            "type": "1",
                            "isDeniedField": false],
                           ["id": "mockID2",
                            "name": "mockName2",
                            "type": "1",
                            "isDeniedField": false]], nil)
        case .getNewConditionIds:
            resultHandler(["mockConditionId"], nil)
        case .getNewOptionId:
            resultHandler(["mockOptionId"], nil)
        case .colorList:
            resultHandler(["ColorList": ["color": "", "id": 0, "textColor": ""]], nil)
        case .buttonColorList:
            resultHandler(["buttonColorList": ["name": "", "id": 0]], nil)
        default:
            resultHandler(nil, nil)
        }
    }
    
    func getPermissionData(args: BTGetPermissionDataArgs, resultHandler: @escaping (Any?, Error?) -> Void) {
        resultHandler(nil, nil)
    }
    
    func saveField(args: BTSaveFieldArgs) {

    }
    
    func createAndLinkRecord(args: BTCreateAndLinkRecordArgs, resultHandler: ((Result<Any?, Error>) -> Void)?) {
        resultHandler?(.success(nil))
    }
    
    func toggleHiddenFieldsDisclosure(args: BTHiddenFieldsDisclosureArgs) {
        
    }
    
    func deleteRecord(args: BTDeleteRecordArgs) {
        
    }
    
    func saveNotifyStrategy(notifiesEnabled: Bool) {
        
    }
    
    func obtainLastNotifyStrategy() -> Bool {
        return true
    }
    
    func obtainGroupData(anchorId: String, childrenAnchorId: String?, direction: String, tableId: String, resultHandler: @escaping (SKBitable.BTGroupingStatisticsObtainGroupData?, Error?) -> Void) {
        resultHandler(BTGroupingStatisticsObtainGroupData(), nil)
    }
    
    func asyncJsRequest(biz: AsyncJSRequestBiz,
                        funcName: DocsJSCallBack,
                        baseId: String,
                        tableId: String,
                        params: [String: Any],
                        overTimeInterval: Double?,
                        responseHandler: @escaping(Result<BTAsyncResponseModel, BTAsyncRequestError>) -> Void,
                        resultHandler: ((Result<Any?, Error>) -> Void)?) {
        resultHandler?(.success(nil))
        if funcName == .asyncToolbarJsRequest {
            if (params["router"] as? String) == "getFieldUserOptions" {
                responseHandler(.success(BTAsyncResponseModel(result: 0, data: ["data": [
                    ["userId": "mockUser",
                     "name": "mockUser",
                     "enName": "mockUser",
                     "avatarUrl": "mockUrl"]
                ]])))
            } else if (params["router"] as? String) == "getFieldLinkByRecordIds" {
                responseHandler(.success(BTAsyncResponseModel(result: 0, data: ["options": [
                    ["id": "mockRecordId",
                     "text": "mockText"]
                ]])))
            } else if (params["router"] as? String) == "getFieldLinkOptions" {
                responseHandler(.success(BTAsyncResponseModel(result: 0, data: ["options": [
                    ["id": "mockRecordId",
                     "text": "mockText"]
                ]])))
            } else if (params["router"] as? String) == "getFieldGroupOptions" {
                responseHandler(.success(BTAsyncResponseModel(result: 0, data: ["options": [
                    ["id": "mockGroup",
                     "name": "mockGroup",
                     "enName": "mockGroup",
                     "avatarUrl": "mockUrl",
                     "linkToken": "linkToken"]
                ]])))
            }
            
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            let error = BTAsyncRequestError(code: .requestTimeOut,
                                            domain: "bitable",
                                            description: "request time out")
            responseHandler(.failure(error))
        }
    }
    
    func fetchCardList(args: BTJSFetchCardArgs,
                       resultHandler: @escaping (BTTableValue?, Error?) -> Void) {
        if isRecordEmpty {
            resultHandler(BTTableValue(loaded: true), nil)
            return
        }
        
        if isLoading {
            resultHandler(BTTableValue(loaded: false), nil)
            return
        }
        
        resultHandler(BTTableValue(loaded: true, records: mockTableValue.records), nil)
    }
    
    func getFieldChatterOptions() {
        
    }
    
    func triggerPassiveRecordSubscribeIfNeeded(recordId: String) {
        
    }
    
    func getItemViewData(type: BTItemViewDataType,
                         tableId: String,
                         payload: [String: Any],
                         resultHandler: ((Result<Any?, Error>) -> Void)?) {
        resultHandler?(.success(["data": ["stageItemViewData": ["recordId": "recWIh2U94",
                                                                "stageDatas": ["stageFieldId": "recWIh2U94",
                                                                               "optionDatas": ["optionId": "mockOptionId",
                                                                                               "requiredFields": [],
                                                                                               "stageConvert": true]]]]]))
    }
    
    var isInVideoConference: Bool = true
    
    var hostDocInfo: DocsInfo = DocsInfo(type: .bitable, objToken: "")
    
    var hostChatId: String?
    
    var jsFuncService: SKExecJSFuncService?

    var hostDocUrl: URL?
    
}

extension BTViewModel {
    func fetchShareLinkToken(with chatID: String) -> Observable<String> {
        return .just("linkToken")
    }
}

class BTViewModelTests: XCTestCase {
    var sut: BTViewModel?
    var normalViewModel: BTViewModel?
    var dataService = DataService()
    let baseContext = BaseContextImpl(baseToken: "", service: nil, permissionObj: nil, from: "")
    lazy var vc = BTController(actionTask: BTCardActionTask(), delegate: nil, uploader: nil, geoFetcher: nil, baseContext: baseContext, dataService: nil)
    var mockPlayloadModel = BTPayloadModel(baseId: "", tableId: "", viewId: "", recordId: "recWIh2U94", bizType: "", fieldId: "fldw2xSLeG", topFieldId: "",
                                           highLightType: .none, colors: [], showConfirm: false, showCancel: false,
                                           forbiddenSubmit: true, forbiddenSubmitReason: ForbiddenSubmitReason(), fields: [:])

    private var context: BTContext {
        return BTContext(
            id: UUID().uuidString,
            shouldShowItemViewTabs: false,
            shouldShowAttachmentCover: false,
            shouldShowItemViewCatalogue: false,
            openRecordTraceId: "openRecordTraceId",
            openBaseTraceId: "openBaseTraceId"
        )
    }

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.enable_edit_form_banner", value: false)
        resetNormalViewModel()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func resetNormalViewModel() {
        let mockActionParamsModel = BTActionParamsModel(action: .submitResult, data: mockPlayloadModel, callback: "", timestamp: 0,
                                                        transactionId: "", originBaseID: "", originTableID: "")
        normalViewModel = BTViewModel(mode: .card, dataService: dataService, cardActionParams: mockActionParamsModel, baseContext: baseContext, context: context)
        sut = BTViewModel(mode: .form, dataService: nil, cardActionParams: mockActionParamsModel, baseContext: baseContext, context: context)
    }
    
    func startTestResopnseAction(_ action: BTActionFromJS) {
        let mockActionParamsModel = BTActionParamsModel(action: action, data: mockPlayloadModel, callback: "", timestamp: 0,
                                                        transactionId: "", originBaseID: "", originTableID: "")
        var mockActionTask = BTCardActionTask()
        mockActionTask.actionParams = mockActionParamsModel                                                
        mockActionTask.setCompleted {
            print("BT CompltedBlock")
        }
        sut?.respond(to: mockActionTask)
        sut?.updateActionParams(mockActionParamsModel)
        XCTAssertTrue(sut?.actionParams.action == action)
    }

    func testResponseToAction() {
        startTestResopnseAction(.showCard)
        startTestResopnseAction(.updateField)
        startTestResopnseAction(.updateRecord)
        startTestResopnseAction(.recordFiltered)
        startTestResopnseAction(.linkTableChanged)
        startTestResopnseAction(.submitResult)
        startTestResopnseAction(.showLinkCard)
        startTestResopnseAction(.setCardHidden)
        startTestResopnseAction(.setCardVisible)
    }
    
    func testRespondNothing() {
        // 标记当前卡片正在退出, 不对参数做处理
        sut?.markDismissing()
        var notRespond = false
        let mockActionParamsModel = BTActionParamsModel(action: .submitResult, data: mockPlayloadModel, callback: "", timestamp: 0,
                                                        transactionId: "", originBaseID: "", originTableID: "")
        var mockActionTask = BTCardActionTask()
        mockActionTask.actionParams = mockActionParamsModel                                                
        mockActionTask.setCompleted {
            print("BT CompltedBlock")
            notRespond = true
        }
        sut?.respond(to: mockActionTask)
        XCTAssertTrue(notRespond)
    }
    
    func testActionTaskDesc() {
        let cardActionTask = BTCardActionTask()
        XCTAssertEqual(cardActionTask.description, "cardAction \(cardActionTask.actionParams.action)")
        
        let baseActionTask = BTBaseActionTask()
        XCTAssertEqual(baseActionTask.description, "baseAction")
        
        let groupingActionTask = BTGroupingActionTask()
        XCTAssertEqual(groupingActionTask.description, "groupingAction \(groupingActionTask.groupingModel.type)")
    }
    
    func testDeinitComplete() {
        let expect = expectation(description: "actionTaskCompleteWhenDeinit")
        if true {
            // 需要放在一个 block 里，这样退出栈的时候才会释放局部变量触发 deinit
            let actionTask = BTBaseActionTask()
            actionTask.setCompleted {
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 2)
        XCTAssertTrue(true)    // 证明 actionTask deinit 时会自动释放
    }
    
    func testTaskQueue() {
        let expect = expectation(description: "actionTaskCompleteWhenDeinit")
        
        let taskQueue = BTTaskQueueManager()
        
        // 需要放在一个 block 里，这样退出栈的时候才会释放局部变量触发 deinit
        let actionTask = BTBaseActionTask()
        taskQueue.addTask(task: actionTask)
        
        let actionTask1 = BTBaseActionTask()
        taskQueue.addTask(task: actionTask1)
        actionTask1.setCompleted {
            expect.fulfill()
        }
        
        actionTask.completedBlock()
        actionTask1.completedBlock()
        
        wait(for: [expect], timeout: 2)
        XCTAssertTrue(true)    // 证明 actionTask1 会被执行
    }
    
    func testBitableReadyAction() {
        let actionModel = BTActionParamsModel(action: .bitableIsReady, data: mockPlayloadModel, callback: "", timestamp: 0, transactionId: "", originBaseID: "", originTableID: "")
        let expect = expectation(description: "testBitableReady")
        
        var task = BTCardActionTask()
        task.actionParams = actionModel                                                
        task.setCompleted {
            expect.fulfill()
            XCTAssertTrue(self.normalViewModel?.bitableIsReady == true)
        }
        normalViewModel?.respond(to: task)
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testViewModelInit() {
        let actionModel = BTActionParamsModel(action: .bitableIsReady, data: mockPlayloadModel, callback: "", timestamp: 0, transactionId: "", originBaseID: "", originTableID: "")
        let viewmodel = BTViewModel(mode: .card, dataService: dataService, cardActionParams: actionModel, baseContext: baseContext, bitableIsReady: true, context: context)
        viewmodel.getCommonData()
        XCTAssertTrue(viewmodel.bitableIsReady)
    }
    
    func testSetBitableReady() {
        let actionModel = BTActionParamsModel(action: .showCard, data: mockPlayloadModel, callback: "", timestamp: 0, transactionId: "", originBaseID: "", originTableID: "")
        let viewmodel = BTViewModel(mode: .card, dataService: dataService, cardActionParams: actionModel, baseContext: baseContext, bitableIsReady: false, context: context)
        viewmodel.bitableIsReady = true
        XCTAssertTrue(viewmodel.bitableIsReady == true)
    }
    
    func testConfirm() {
        let args = BTCheckConfirmAPIArgs(tableID: "",
                                         viewID: "",
                                         fieldInfo: BTJSFieldInfoArgs(allowEditModes: AllowedEditModes()),
                                         property: nil,
                                         extraParams: nil)
        normalViewModel?.dataService?.checkConfirmAPI(args: args) { _ in
            XCTAssertTrue(true)
        }
    }
    
    func testJsExecuteCommands() {
        normalViewModel?
            .jsExecuteCommands(
                command: .setFieldAttr,
                field: BTBaseField(),
                property: nil,
                extraParams: nil,
                resultHandler: { _, err in
                    if let err = err {
                        XCTAssertNil(err)
                    } else {
                        XCTAssertTrue(true)
                    }
                }
            )
    }
    
    func testAsyncRequest() {
        normalViewModel?.asyncJsRequest(router: .getBitableFieldOptions,
                                        data: nil,
                                        overTimeInterval: nil,
                                        responseHandler: { result in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
            default:
                break
            }
        },
                                        resultHandler: { result in
            switch result {
            case .success(let data):
                XCTAssertNil(data)
            default:
                break
            }
        })
    }
    
    func testFinishWithoutModify() {
        let expect = expectation(description: "testDidModifyURLContent")
        self.normalViewModel?.constructCardRequest(.initialize(true)) { [weak self] _ in
            self?.normalViewModel?.didFinishEditingWithoutModify(fieldID: "")
            XCTAssertTrue(self?.normalViewModel?.tableModel.records.count == 11)
            expect.fulfill()
        }
        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
    }

    func testUpdateProAddSubmitTopTipShowed() {
        guard let model = normalViewModel else {
            return
        }
        model.updateProAddSubmitTopTipShowed(true)
        XCTAssertTrue(model.tableMeta.submitTopTipShowed)
        XCTAssertTrue(model.tableModel.submitTopTipShowed)
    }
    
    func testIsNormalShowRecord() {
        guard let model = normalViewModel else {
            return
        }
        
        XCTAssertTrue(model.mode.isNormalShowRecord)
    }
    
}

extension BTViewModelTests {
    enum SetFetchParam {
        case empty
        case success(count: Int) //count record的数量
        case loading(waitingCount: Int) //waitingCount等待队列中请求的个数
    }
    
    func startTestFetchRecords(by type: BTCardFetchType, fetchParam: SetFetchParam, mode: BTViewMode) {
        let expect = expectation(description: "testFetchRecords fetchParam:\(fetchParam) type:\(type) mode:\(mode)")
        let isLoading = dataService.isLoading
        let isRecordEmpty = dataService.isRecordEmpty
        var shouldBeSuccess: Bool = false
        switch mode {
        case .form, .stage:
            shouldBeSuccess = !isLoading
        case .link, .card, .submit, .indRecord, .addRecord:
            if type == .left {
                shouldBeSuccess = !isLoading
            } else if type == .right {
                if case .link = mode {
                    shouldBeSuccess = !isLoading && !isRecordEmpty
                } else {
                    shouldBeSuccess = !isLoading
                }
            } else {
                if case .success(_) = fetchParam {
                    shouldBeSuccess = true
                }
            }
        }
        
        var successRecordCount = 0
        if case let .success(count) = fetchParam {
            successRecordCount = count
        }
        
        if case .initialize(_) = type {
            if case .loading(_) = fetchParam {
                shouldBeSuccess = true
            }
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        self.normalViewModel?.constructCardRequest(type, overTimeInterval: 0) { [weak self] success in
            let endTime = CFAbsoluteTimeGetCurrent()
            debugPrint("zj startTestFetchRecords success:\(success) shouldBeSuccess:\(shouldBeSuccess) fetchParam:\(fetchParam) type:\(type) costTime:\((endTime - startTime) * 1000)ms")
            expect.fulfill()
            if success {
                XCTAssertTrue(shouldBeSuccess)
                if !isLoading {
                    XCTAssertTrue(self?.normalViewModel?.fetchDataManager.cardListRequestWaitingQueue.count == 0)
                    XCTAssertTrue(self?.normalViewModel?.tableModel.records.count == successRecordCount)
                }
            } else {
                XCTAssertTrue(!shouldBeSuccess)
            }
        }
        
        waitForExpectations(timeout: 30) { error in
            XCTAssertNil(error)
        }
    }
    
    func judgeByMode(_ mode: BTViewMode, fetchParam: SetFetchParam) {
        switch fetchParam {
        case .empty:
            dataService.isRecordEmpty = true
            dataService.isLoading = false
        case .loading(_):
            dataService.isLoading = true
            dataService.isRecordEmpty = false
        default:
            dataService.isLoading = false
            dataService.isRecordEmpty = false
        }
        
        normalViewModel?.mode = mode
        
        startTestFetchRecords(by: .initialize(true), fetchParam: fetchParam, mode: mode)
        startTestFetchRecords(by: .update, fetchParam: fetchParam, mode: mode)
        startTestFetchRecords(by: .onlyData, fetchParam: fetchParam, mode: mode)
        startTestFetchRecords(by: .left, fetchParam: fetchParam, mode: mode)
        startTestFetchRecords(by: .right, fetchParam: fetchParam, mode: mode)
        startTestFetchRecords(by: .filteredOnlyOne, fetchParam: fetchParam, mode: mode)
    }
    
    /// 测试请求
    func testRecordsFetchEmpty() {
        let actionModel = BTActionParamsModel(action: .showCard, data: mockPlayloadModel, callback: "", timestamp: 0, transactionId: "", originBaseID: "", originTableID: "")
        normalViewModel = BTViewModel(mode: .card, dataService: dataService, cardActionParams: actionModel, baseContext: baseContext, context: context)


        judgeByMode(.form, fetchParam: .empty)
        judgeByMode(.submit, fetchParam: .empty)
        judgeByMode(.card, fetchParam: .empty)
        judgeByMode(.link, fetchParam: .empty)
    }
    
    func testRecordsFetchSuccess() {
        let actionModel = BTActionParamsModel(action: .showCard, data: mockPlayloadModel, callback: "", timestamp: 0, transactionId: "", originBaseID: "", originTableID: "")
        normalViewModel = BTViewModel(mode: .card, dataService: dataService, cardActionParams: actionModel, baseContext: baseContext, context: context)
        
        judgeByMode(.form, fetchParam: .success(count: 11))
        judgeByMode(.submit, fetchParam: .success(count: 11))
        judgeByMode(.card, fetchParam: .success(count: 11))
        judgeByMode(.link, fetchParam: .success(count: 11))
    }
    
    func testRecordsFetchLoading() {
        let actionModel = BTActionParamsModel(action: .showCard, data: mockPlayloadModel, callback: "", timestamp: 0, transactionId: "", originBaseID: "", originTableID: "")
        normalViewModel = BTViewModel(mode: .card, dataService: dataService, cardActionParams: actionModel, baseContext: baseContext, context: context)
        
        judgeByMode(.form, fetchParam: .loading(waitingCount: 1))
        judgeByMode(.submit, fetchParam: .loading(waitingCount: 1))
        judgeByMode(.card, fetchParam: .loading(waitingCount: 1))
        judgeByMode(.link, fetchParam: .loading(waitingCount: 1))
    }
    
    /// 测试判断空数据处理是否正确
    func testHandleEmptyRecordsWhenGetTableData() {
        let actionModel = BTActionParamsModel(action: .showCard, data: mockPlayloadModel, callback: "", timestamp: 0, transactionId: "", originBaseID: "", originTableID: "")
        normalViewModel = BTViewModel(mode: .card, dataService: dataService, cardActionParams: actionModel, baseContext: baseContext, context: context)
        
        let mode = normalViewModel?.mode ?? .form
        let isRecordsEmpety = dataService.isRecordEmpty

        func judgeByMode(_ mode: BTViewMode) {
            dataService.isRecordEmpty = true
            normalViewModel?.mode = mode
            let needHandle: Bool
            switch mode {
            case .form, .stage:
                needHandle = false
            case .link, .card, .submit, .indRecord, .addRecord:
                needHandle = true
            }
            let result = normalViewModel?.handleEmptyRecordsWhenGetTableData(result: dataService.mockTableValue, emptyBlock: { _ in

            })
            XCTAssertTrue(needHandle == result)
        }

        judgeByMode(.form)
        judgeByMode(.submit)
        judgeByMode(.card)
        judgeByMode(.link)
        normalViewModel?.mode = mode
        dataService.isRecordEmpty = isRecordsEmpety
    }
}

/// EditAgent
extension BTViewModelTests {
    
    func testDidModifyURLContent() {
        resetNormalViewModel()
        let expect = expectation(description: "testDidModifyURLContent")
        self.normalViewModel?.constructCardRequest(.initialize(true)) { _ in
            expect.fulfill()
        }
        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
     
        func testWithContent(_ content: String) {
            let aText = NSAttributedString(string: content)
            normalViewModel?.didModifyURLContent(fieldID: "fldw2xSLeG", modifyType: .editAtext(aText: aText, link: "", finish: true))
            let field = normalViewModel?.tableModel.records.first(where: { $0.recordID == "recWIh2U94" })?.wrappedFields.first { $0.fieldID == "fldw2xSLeG" }
            let text = field?.textValue.first?.text ?? ""
            XCTAssertTrue(text == content)
        }
        
        testWithContent("http://baidu.com")
        testWithContent("")
    }
    
    func testDidModifyTextContent() {
        resetNormalViewModel()
        let expect = expectation(description: "testDidModifyTextContent")
        self.normalViewModel?.constructCardRequest(.initialize(true)) { _ in
            expect.fulfill()
        }
        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
     
        func testWithContent(_ content: String) {
            let aText = NSAttributedString(string: content)
            normalViewModel?.didModifyText(fieldID: "fldw2xSLeG", attText: aText, finish: true, editType: .scan)
            let field = normalViewModel?.tableModel.records.first(where: { $0.recordID == "recWIh2U94" })?.wrappedFields.first { $0.fieldID == "fldw2xSLeG" }
            let text = field?.textValue.first?.text ?? ""
            let editType = field?.textValue.first?.editType
            XCTAssertTrue(text == content)
            XCTAssertNotNil(editType)
        }
        testWithContent("http://baidu.com")
    }
    
    func testAddNewLinkedRecord() {
        let sourceLocation = BTFieldLocation(originBaseID: "sourceOriginBaseId",
                                             originTableID: "sourceOriginTableId",
                                             baseID: "sourceBaseId",
                                             tableID: "sourceTableId",
                                             viewID: "sourceViewId",
                                             recordID: "sourceRecordId",
                                             fieldID: "sourceFieldId")
        
        let targetLocation = BTFieldLocation(originBaseID: "targetOriginBaseId",
                                             originTableID: "targetOriginTableId",
                                             baseID: "targetBaseId",
                                             tableID: "targetTableId",
                                             viewID: "targetViewId",
                                             recordID: "targetRecordId",
                                             fieldID: "targetFieldId")
        
        normalViewModel?.addNewLinkedRecord(fromLocation: sourceLocation, toLocation: targetLocation, value: nil, resultHandler: { result in
            switch result {
            case .success(let data):
                XCTAssertNil(data)
            default:
                break
            }
        })
    }
    
    func testDidSelectChatter() {
        let trackInfo = BTTrackInfo()
        let chatter = BTUserModel(chatterId: "chatterId", notify: false, name: "name", enName: "enName", avatarUrl: "avatarUrl")
        normalViewModel?.didSelectChatters(with: "fieldID", chatterInfo: BTSelectChatterInfo(type: .user, chatters: [], currentChatter: chatter), trackInfo: trackInfo, noUpdateChatterData: false, completion: {
            (model, error) in
            XCTAssert(model == nil || (model?.chatterId == chatter.chatterId))
        })
        let model = BTGroupModel.deserialize(from: ["id": "chatterId", "name": "name", "avatarUrl": "avatarUrl", "linkToken": "token"])
        XCTAssert(model?.chatterId == "chatterId")
        let capsuleModel = model?.asCapsuleModel(isSelected: true)
        XCTAssert(capsuleModel?.isSelected == true)
        let json = [model!].toJSON()
        XCTAssertNotNil(json)
        let model1 = BTGroupModel.deserialize(from: ["id": "chatterId", "name": "name", "avatarUrl": "avatarUrl", "linkToken": "token"])
        let json1 = [model1!].toJSON()
        XCTAssertNotNil(json1)
    }
    
    func testGetFormBannerURL() {
        normalViewModel?.getFormBannerURL(viewId: "", tableId: "") { _ in
        }
        sut?.getFormBannerURL(viewId: "", tableId: "") { _ in
        }
    }
    
    func testUpdateForm() {
        let mockActionParamsModel = BTActionParamsModel(action: .submitResult, data: mockPlayloadModel, callback: "", timestamp: 0,
                                                        transactionId: "", originBaseID: "", originTableID: "")
        let model1 = BTViewModel(mode: .card, dataService: dataService, cardActionParams: mockActionParamsModel, baseContext: baseContext, context: context)
        model1.mode = .form
        let model2 = BTViewModel(mode: .form, dataService: nil, cardActionParams: mockActionParamsModel, baseContext: baseContext, context: context)
        model2.mode = .submit
        model1.updateForm()
        model2.updateForm()
    }
    
    func testBTViewMode() {
        XCTAssertEqual(BTViewMode.card.trackValue, "card")
        XCTAssertEqual(BTViewMode.link.trackValue, "link")
        XCTAssertEqual(BTViewMode.submit.trackValue, "submit")
        XCTAssertEqual(BTViewMode.form.trackValue, "form")
        XCTAssertEqual(BTViewMode.indRecord.trackValue, "indRecord")
        XCTAssertEqual(BTViewMode.stage(origin: .card).trackValue, "stage")
        XCTAssertEqual(BTViewMode.addRecord.trackValue, "addRecord")
        
        XCTAssertTrue(BTViewMode.stage(origin: .card).isStage)
        XCTAssertTrue(BTViewMode.stage(origin: .indRecord).isStage)
        XCTAssertTrue(BTViewMode.stage(origin: .addRecord).isStage)
        XCTAssertFalse(BTViewMode.card.isStage)
        XCTAssertFalse(BTViewMode.indRecord.isStage)
    }
    
    func testShouldShowItemViewCatalogue() {
        XCTAssertFalse(BTViewMode.card.shouldShowItemViewCatalogue)
        XCTAssertTrue(BTViewMode.indRecord.shouldShowItemViewCatalogue)
        XCTAssertTrue(BTViewMode.addRecord.shouldShowItemViewCatalogue)
        XCTAssertFalse(BTViewMode.stage(origin: .card).shouldShowItemViewCatalogue)
        XCTAssertTrue(BTViewMode.stage(origin: .indRecord).shouldShowItemViewCatalogue)
        XCTAssertTrue(BTViewMode.stage(origin: .addRecord).shouldShowItemViewCatalogue)
        
        let mockActionParamsModel = BTActionParamsModel(action: .submitResult, data: mockPlayloadModel, callback: "", timestamp: 0,
                                                        transactionId: "", originBaseID: "", originTableID: "")
        let model = BTViewModel(mode: .indRecord, dataService: dataService, cardActionParams: mockActionParamsModel, baseContext: baseContext, context: context)
        XCTAssertFalse(model.shouldShowItemViewCatalogue)
        
        let model1 = BTViewModel(mode: .addRecord, dataService: dataService, cardActionParams: mockActionParamsModel, baseContext: baseContext, context: context)
        XCTAssertFalse(model1.shouldShowItemViewCatalogue)
        
        let model2 = BTViewModel(mode: .card, dataService: dataService, cardActionParams: mockActionParamsModel, baseContext: baseContext, context: context)
        XCTAssertFalse(model2.shouldShowItemViewCatalogue)
    }
}

extension BTViewModelTests {
    func testTrackInfo() {
        let actionModel = BTActionParamsModel(action: .showIndRecord, data: mockPlayloadModel, callback: "", timestamp: 0, transactionId: "", originBaseID: "", originTableID: "")
        let vm = BTViewModel(mode: .indRecord, dataService: dataService, cardActionParams: actionModel, baseContext: baseContext, context: context)
        XCTAssertTrue(!vm.modeTrackInfo.isEmpty)
    }
    
    func testOpenType() {
        XCTAssertEqual(BTViewMode.card.openType, BTStatisticOpenFileType.main)
        XCTAssertEqual(BTViewMode.indRecord.openType, BTStatisticOpenFileType.share_record)
        XCTAssertEqual(BTViewMode.addRecord.openType, BTStatisticOpenFileType.base_add)
    }
    
    func testIsCard() {
        XCTAssertTrue(BTViewMode.card.isCard)
    }
}
