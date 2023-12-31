//
//  InlineAIPanelViewModelTests.swift
//  LarkAIInfra-Unit-Tests
//
//  Created by huayufan on 2023/10/30.
//  


import XCTest
import RxSwift
import RxCocoa
@testable import LarkAIInfra
import AppContainer
import LarkContainer
import RustPB
import LarkKeyboardKit
import LarkBaseKeyboard
import BootManager
import LarkContainer
import LarkModel

final class InlineAIPanelViewModelTests: XCTestCase {
    
    var aiModule: LarkInlineAISDK?
    
    var aiUIModule: LarkInlineAIUISDK?
    
    lazy var testVC = UIViewController()
    
    var outputs: [InlineAIPanelViewModel.Output] = []
    
    var disposeBag = DisposeBag()
    
    var eventRelay = PublishRelay<InlineAIEvent>()
    
    var historyText: String?
    
    var textChange: String?
    var clickPromp: LarkAIInfra.InlineAIPanelModel.Prompt?
    var deletePrompt: LarkAIInfra.InlineAIPanelModel.Prompt?
    var clickSubPrompt: LarkAIInfra.InlineAIPanelModel.Prompt?
    var clickOperation: LarkAIInfra.InlineAIPanelModel.Operate?
    var clickSheetOperation: Bool = false
    var clickStop: Bool = false
    var clickFeedbackLike: Bool?
    var clickPre: Bool?
    var clickMaskArea: Bool?
    var keyboardChange: Bool?
    var swipHidePanel: Bool?
    var panelDismiss: Bool = false
    var downloadImageResults: [InlineAIImageDownloadResult]?
    
    var viewModel: InlineAIPanelViewModel? {
        return (aiModule as? LarkInlineAIModule)?.viewModel
    }
    
    var uiViewModel: InlineAIPanelViewModel? {
        return (aiUIModule as? LarkInlineAIModule)?.panelVC?.viewModel
    }

    class InlineAIMentionUserServiceImp: InlineAIMentionUserService {
        func showMentionUserPicker(title: String, callback: @escaping ([LarkModel.PickerItem]?) -> Void) {
            callback(nil)
        }
        
        func onClickUser(chatterId: String, fromVC: UIViewController) {
            
        }
        
        func setRecommendUsersLoader(firstPageLoader: RxSwift.Observable<LarkModel.PickerRecommendResult>, moreLoader: RxSwift.Observable<LarkModel.PickerRecommendResult>) {
            
        }
    }

    override func setUp() {
        super.setUp()
        BootLoader.container.register(InlineAIMentionUserService.self, factory: { _ in InlineAIMentionUserServiceImp() })
        initFulModule()
    }
    
    override func tearDown() {
        super.tearDown()
        self.disposeBag = DisposeBag()
        self.status = .empty
        self.outputs = []
        self.historyText = nil
        
        self.textChange = nil
        self.clickPromp = nil
        self.clickSubPrompt = nil
        self.clickOperation = nil
        self.clickSheetOperation = false
        self.clickStop = false
        self.clickFeedbackLike = nil
        self.clickPre = nil
        self.clickMaskArea = nil
        self.keyboardChange = nil
        self.swipHidePanel = nil
        self.panelDismiss = false
        self.downloadImageResults = nil
        self.model = nil
        eventRelay = PublishRelay<InlineAIEvent>()
    }
    
    var model: InlineAIPanelModel?

    func initFulModule() {
        var config = InlineAIConfig(captureAllowed: true,
                                    scenario: .groupChat,
                                    maskType: .aroundPanel,
                                    panelMargin: .init(bottomWithKeyboard: 10, bottomWithoutKeyboard: 30, leftAndRight: 30),
                                    userResolver: Container.shared.getCurrentUserResolver())
        
        config.update(supportLastPrompt: true)
        config.update(debug: true)
        aiModule = LarkInlineAIModuleGenerator.createAISDK(config: config, customView: nil, delegate: self)
        if let viewModel = self.viewModel {

            viewModel.output.subscribe(onNext: { [weak self] in
                self?.outputs.append($0)
                switch $0 {
                case .show(let modelWrapper):
                    self?.model = modelWrapper.panelModel
                default:
                    break
                }
            }).disposed(by: disposeBag)
            
            eventRelay.bind(to: viewModel.eventRelay).disposed(by: disposeBag)
        }
    }
    
    func initUIModule(mentionTypes: [InlineAIMentionType] = [.doc]) {
        disposeBag = DisposeBag()
        let config = InlineAIConfig(captureAllowed: true,
                                    mentionTypes: mentionTypes,
                                    scenario: .docX,
                                    userResolver: Container.shared.getCurrentUserResolver())
        aiUIModule = LarkInlineAIModuleGenerator.createUISDK(config: config, customView: nil, delegate: self)
    }
    
    
    
    
    func existButtonFunc() -> OperateButton {
        return OperateButton(key: "a", text: "退出", isPrimary: false) { [weak self] _, _ in
            guard let self = self else { return }
            self.aiModule?.hidePanel(quitType: "click_button_on_result_page")
        }
    }
    
    enum Status {
        case empty
        case onStart
        case onMessage
        case onError
        case onFinish
    }
    
    var status: Status = .empty
    
    func testPrompt(text: String, isTemplate: Bool = false) -> AIPrompt {
        let id = UUID().uuidString
        let title = text

        var templates: PromptTemplates?
        if isTemplate {
            templates = PromptTemplates(templatePrefix: "我是前缀", templateList: [PromptTemplate(templateName: "templateName", key: "key", placeHolder: "placeHolder", defaultUserInput: "defaultUserInput")])
        }
        return AIPrompt(id: id, localId: id, icon: "", text: title, templates: templates, callback:
                            AIPrompt.AIPromptCallback(onStart: {
            self.status = .onStart
            return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: [:])
        }, onMessage: { [weak self] _ in
            guard let self = self else { return }
            self.status = .onMessage
        }, onError: { [weak self] _ in
            guard let self = self else { return }
            self.status = .onError
        }, onFinish: { [weak self] _ in
            guard let self = self else { return [] }
            self.status = .onFinish
            return [self.retryButtonFunc()]
        }))
    }
    
    var testGroup: [AIPromptGroup] {
        var prompts: [AIPrompt] = []
        for i in 0..<5 {
            prompts.append(testPrompt(text: "\(i)"))
        }
        return [AIPromptGroup(title: "测试", prompts: prompts)]
    }

    func showPromptGroups() {
        self.aiModule?.showPanel(promptGroups: testGroup)
        viewModel?.isShowing.accept(true)
    }
    
    
    func createTaskRecord(text: String, sendPrompt: AIPrompt? = nil, isFinishStatus: Bool = false, finishStatus: String = "success") {
        if self.viewModel?.aiState.status == .finished {
            let id = self.viewModel?.aiState.promptGroups.first?.prompts.first?.id ?? ""
            self.viewModel?.choosePromptInFullMode(prompt: .init(id: id, localId: id, icon: "", text: "test"))
        } else {
            self.aiModule?.sendPrompt(prompt: sendPrompt ?? testPrompt(text: "test"), promptGroups: testGroup)
        }
        
        // AI输出中
        var response = Space_Doc_V1_InlineAITaskStatusPushResponse()
        var taskStatus = Space_Doc_V1_InlineAITaskStatus()
        taskStatus.taskStatus = "processing"
        taskStatus.content = "123"
        let taskId = self.viewModel?.aiState.currentTaskId ?? ""
        taskStatus.uniqueTaskID = taskId
        response.inlineAiTaskStatus = taskStatus
        self.outputs = []
        PushDispatcher.shared.pushResponse.accept(response)
        
        // 进入结果页
        var taskStatus2 = Space_Doc_V1_InlineAITaskStatus()
        taskStatus2.taskStatus = finishStatus
        taskStatus2.content = "123\(text)"
        taskStatus2.uniqueTaskID = taskId
        response.inlineAiTaskStatus = taskStatus2
        PushDispatcher.shared.pushResponse.accept(response)
    }

    func testShowPanel() {
        showPromptGroups()
        var find = false
        for output in self.outputs {
            switch output {
            case let .show(model):
                XCTAssertEqual(model.panelModel.input?.status ?? -1, 0)
                find = true
            default:
                break
            }
        }
        XCTAssertTrue(find)
    }
    
// MARK: - 数据层

    func testSend() {
        // loading中
        self.aiModule?.sendPrompt(prompt: testPrompt(text: "test"), promptGroups: testGroup)
        XCTAssertEqual(self.status, .onStart)
        
        
        // AI输出中
        var response = Space_Doc_V1_InlineAITaskStatusPushResponse()
        var taskStatus = Space_Doc_V1_InlineAITaskStatus()
        taskStatus.taskStatus = "processing"
        taskStatus.content = "12345"
        let taskId = self.viewModel?.aiState.currentTask?.taskId ?? UUID().uuidString
        taskStatus.uniqueTaskID = taskId
        response.inlineAiTaskStatus = taskStatus
        self.outputs = []
        PushDispatcher.shared.pushResponse.accept(response)
        
        let expect = expectation(description: "testSend")
        

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            XCTAssertEqual(self.status, .onMessage)
            var find = false
            for output in self.outputs {
                switch output {
                case let .show(model):
                    XCTAssertEqual(model.panelModel.content, taskStatus.content)
                    find = true
                default:
                    break
                }
            }
            XCTAssertTrue(find)
    
            // 结果页
            var taskStatus = Space_Doc_V1_InlineAITaskStatus()
            taskStatus.taskStatus = "success"
            taskStatus.content = "123456789"
            taskStatus.uniqueTaskID = taskId
            response.inlineAiTaskStatus = taskStatus
            PushDispatcher.shared.pushResponse.accept(response)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                expect.fulfill()
                XCTAssertEqual(self.status, .onFinish)
            }
        }
        
        let expect2 = expectation(description: "test history")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            XCTAssertNil(self.historyText)
            self.createTaskRecord(text: "record2")
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                // 切换历史记录
                self.eventRelay.accept(.clickPrePage)
                XCTAssertEqual(self.historyText ?? "", "123456789")
                self.eventRelay.accept(.clickNextPage)
                XCTAssertEqual(self.historyText ?? "", "123record2")
                expect2.fulfill()
            }
        }
        
        wait(for: [expect, expect2], timeout: 5)
    }
    
    func testRichTextContentSend() {
        let prompt = testPrompt(text: "我是模版指令", isTemplate: true)
        let testGroup = [AIPromptGroup(title: "测试", prompts: [prompt])]
        self.aiModule?.showPanel(promptGroups: testGroup)
        viewModel?.isShowing.accept(true)
        
        XCTAssertNil(self.model?.input?.textContentList)
        
        (self.aiModule as? LarkInlineAIModule)?.panelVC?.disposeBag = DisposeBag()

        // 选中模版指令
        eventRelay.accept(.choosePrompt(prompt: prompt.toInternalPrompt()))
    
        if let textContentList = self.model?.input?.textContentList {
            var quickAction = InlineAIPanelModel.QuickAction(displayName: textContentList.displayName, displayContent: "", paramDetails: [])
            for detail in textContentList.paramDetails {
                let paramDetail = InlineAIPanelModel.ParamDetail(name: "", key: detail.key, content: detail.content ?? "")
                quickAction.paramDetails.append(paramDetail)
            }

            let richTextData: RichTextContent.DataType = .quickAction(quickAction)
            XCTAssertEqual(self.status, .empty)

            eventRelay.accept(.keyboardDidSend(.init(data: richTextData, attributedString: .init(string: ""))))
            XCTAssertEqual(self.status, .onStart)
            
        } else {
            XCTFail("testRichTextContentSend textContentList is nil")
        }
    }
    
    func testFreeInputSend() {
        showPromptGroups()
        XCTAssertEqual(self.status, .empty)
        let text = "test test"
        let sendContent = RichTextContent.DataType.freeInput(components: [InlineAIPanelModel.ParamContentComponent.plainText(text)])
        eventRelay.accept(.keyboardDidSend(.init(data: sendContent, attributedString: .init(string: text))))
        XCTAssertEqual(self.status, .onStart)
    }
    
    // 返回指令列表页
    func testWaitingStop() {
        self.aiModule?.sendPrompt(prompt: testPrompt(text: "test"), promptGroups: testGroup)

        self.eventRelay.accept(.stopGenerating)
        let showPrompt = self.model?.prompts?.show ?? false
        let count = self.model?.prompts?.data.first?.prompts.count ?? 0
        XCTAssertTrue(showPrompt)
        XCTAssertTrue(count > 0)
    }
    
    
    // 进结果页
    func testWritingStop() {
        self.aiModule?.sendPrompt(prompt: testPrompt(text: "test"), promptGroups: testGroup)
        // AI输出中
        var response = Space_Doc_V1_InlineAITaskStatusPushResponse()
        var taskStatus = Space_Doc_V1_InlineAITaskStatus()
        taskStatus.taskStatus = "processing"
        taskStatus.content = "123"
        let taskId = self.viewModel?.aiState.currentTaskId ?? ""
        taskStatus.uniqueTaskID = taskId
        response.inlineAiTaskStatus = taskStatus
        self.outputs = []
        PushDispatcher.shared.pushResponse.accept(response)
    
        self.eventRelay.accept(.stopGenerating)
        let showPrompt = self.model?.prompts?.show ?? false
        XCTAssertFalse(showPrompt)
        XCTAssertEqual(self.model?.content ?? "", taskStatus.content)
    }
    
    
    // 返回结果页
    func testFinishStop() {
        showPromptGroups()
        createTaskRecord(text: "123")
        let expect = expectation(description: "testFinishStop")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            XCTAssertTrue(self.viewModel?.aiState.status == .finished)
            
            let id = self.viewModel?.aiState.promptGroups.first?.prompts.first?.id ?? ""
            self.viewModel?.choosePromptInFullMode(prompt: .init(id: id, localId: id, icon: "", text: "test"))
            var totalTasksCount = self.viewModel?.aiState.totalTasksCount ?? -1
            XCTAssertEqual(totalTasksCount, 2)
            self.eventRelay.accept(.stopGenerating)
            totalTasksCount = self.viewModel?.aiState.totalTasksCount ?? -1
            XCTAssertEqual(totalTasksCount, 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5)
    }
    
    // 返回结果页
    func testEmptyStop() {
        self.aiModule?.sendPrompt(prompt: testPrompt(text: "test"), promptGroups: [])
        
        self.eventRelay.accept(.stopGenerating)
        
        var containDismissPanel = false
        for output in outputs {
            if case .dismissPanel = output {
                containDismissPanel = true
                break
            }
        }
        XCTAssertTrue(containDismissPanel)
    }

    func testThumb() {
        self.createTaskRecord(text: "456")
        self.eventRelay.accept(.clickThumbUp(isSelected: true))
        
        XCTAssertEqual(self.viewModel?.aiState.currentTask?.feedbackChoice, .like)
        
        
        self.eventRelay.accept(.clickThumbUp(isSelected: false))
        XCTAssertEqual(self.viewModel?.aiState.currentTask?.feedbackChoice, .unselected)
        
        
        self.eventRelay.accept(.clickThumbDown(isSelected: true))
        XCTAssertEqual(self.viewModel?.aiState.currentTask?.feedbackChoice, .dislike)
        
        var find = false
        for output in self.outputs {
            switch output {
            case .showFeedbackAlert:
                find = true
            default:
                break
            }
        }
        XCTAssertTrue(find)
        
        
        self.eventRelay.accept(.clickThumbDown(isSelected: false))
        XCTAssertEqual(self.viewModel?.aiState.currentTask?.feedbackChoice, .unselected)
    }
    
    func testChooseOperator() {
        let expect = expectation(description: "testChooseOperator")
        self.createTaskRecord(text: "456")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            expect.fulfill()
            self.eventRelay.accept(.chooseOperator(operate: InlineAIPanelModel.Operate(text: "",
                                                                                      type: "retry",
                                                                                      btnType: "")))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                XCTAssertEqual(self.viewModel?.aiState.totalTasksCount ?? 0, 2)
            }
        }
        wait(for: [expect], timeout: 5)
    }
    
    func testHistory() {
        let expect = expectation(description: "testChooseOperator")
        self.createTaskRecord(text: "456")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.createTaskRecord(text: "789")
        }
    
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            guard let viewModel = self.viewModel else { return }
            XCTAssertEqual(viewModel.aiState.totalTasksCount, 2)
            XCTAssertEqual(viewModel.aiState.taskIndex, 1)
            self.eventRelay.accept(.clickPrePage)
            XCTAssertEqual(viewModel.aiState.taskIndex, 0)
            self.eventRelay.accept(.clickPrePage)
            XCTAssertEqual(viewModel.aiState.taskIndex, 0)
            
            self.eventRelay.accept(.clickNextPage)
            XCTAssertEqual(viewModel.aiState.taskIndex, 1)
            self.eventRelay.accept(.clickNextPage)
            XCTAssertEqual(viewModel.aiState.taskIndex, 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5)
    }
    
    
    func testFailure() {
        self.createTaskRecord(text: "xx", finishStatus: "failed")
        
        let expect = expectation(description: "testFailure")

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            guard let model = self.model else { return }
            XCTAssertTrue(model.operates?.data.first?.type == "exit")
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5)
    }
    
    func testTnsBlock() {
        self.createTaskRecord(text: "", finishStatus: "tns_block")
        let expect = expectation(description: "tesTnsBlock")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            guard let model = self.model else { return }
            XCTAssertTrue(model.operates?.data.first?.type == "exit")
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5)
    }
    
    
    func testRecentPromptSend() {
        showPromptGroups()
        viewModel?.getRecentPrompt()
        var action = RecentAction()
        action.id = "2334"
        action.userPrompt = "test"
        viewModel?.historyPrompts = [action]
        viewModel?.reloadHistoryPrompts()
        
        guard let recentGroup = self.viewModel?.aiState.promptGroups.last,
        let recentPrompt = recentGroup.prompts.first else {
            XCTFail("recent group is nil")
            return
        }
        self.createTaskRecord(text: "xxxxxx", sendPrompt: recentPrompt)
        eventRelay.accept(.keyboardDidSend(RichTextContent(data: .freeInput(components: [InlineAIPanelModel.ParamContentComponent.plainText(action.userPrompt)]), attributedString: .init(string: action.userPrompt))))
        
        // AI输出中
        var response = Space_Doc_V1_InlineAITaskStatusPushResponse()
        var taskStatus = Space_Doc_V1_InlineAITaskStatus()
        taskStatus.taskStatus = "processing"
        taskStatus.content = "123"
        let taskId = self.viewModel?.aiState.currentTaskId ?? ""
        taskStatus.uniqueTaskID = taskId
        response.inlineAiTaskStatus = taskStatus
        self.outputs = []
        PushDispatcher.shared.pushResponse.accept(response)
    
        // 进入结果页
        var taskStatus2 = Space_Doc_V1_InlineAITaskStatus()
        taskStatus2.taskStatus = "success"
        taskStatus2.content = "123"
        taskStatus2.uniqueTaskID = taskId
        response.inlineAiTaskStatus = taskStatus2
        PushDispatcher.shared.pushResponse.accept(response)
        
        let expect = expectation(description: "testRecentPromptSend")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            XCTAssertNotNil(self.model)
            let operatesCount = self.model?.operates?.data.count ?? 0
            XCTAssertTrue(operatesCount > 0)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3)
    }
    
    func testTextChangeSearch() {
        showPromptGroups()
        
        for i in 0..<5 {
            eventRelay.accept(.textViewDidChange(text: "\(i)"))
            guard let model = self.model else {
                XCTFail("")
                return
            }
            XCTAssertEqual(model.prompts?.data.count ?? -1, 1)
            XCTAssertEqual( model.prompts?.data.first?.prompts.count, 1)
            let text = model.prompts?.data.first?.prompts.first?.text ?? "nil"
            XCTAssertEqual(text, "\(i)")
        }
    }
    
    func testRecentPromptDelete() {
        showPromptGroups()
        viewModel?.getRecentPrompt()
        var action = RecentAction()
        action.id = "999"
        action.userPrompt = "test"
        viewModel?.historyPrompts = [action]
        viewModel?.reloadHistoryPrompts()
        
        guard let recentGroup = self.viewModel?.aiState.promptGroups.last,
        let recentPrompt = recentGroup.prompts.first else {
            XCTFail("recent group is nil")
            return
        }

        viewModel?.handelDeleteHistoryPrompt(prompt: recentPrompt.toInternalPrompt())
        viewModel?.deleteLocalHistoryPrompt(by: recentPrompt.localId ?? "")
    
        XCTAssertEqual(self.viewModel?.aiState.promptGroups.count ?? 0, 1)
    }
    
    func testMoreRecentPromptDelete() {
        showPromptGroups()
        viewModel?.getRecentPrompt()
        var actions: [RecentAction] = []
        for i in 0..<6 {
            var action = RecentAction()
            action.id = "\(i)"
            action.userPrompt = "test_\(i)"
            actions.append(action)
        }
        viewModel?.historyPrompts = actions
        viewModel?.reloadHistoryPrompts()
        
        let groupCount = self.viewModel?.aiState.promptGroups.count ?? 0
        guard groupCount == 2,
              let recentGroup = self.viewModel?.aiState.promptGroups.last,
              let morePrompt = recentGroup.prompts.last else {
            XCTFail("recent group is nil")
            return
        }

        XCTAssertEqual(morePrompt.children.count, 1, "subpanel has 1 child")
        viewModel?.deleteLocalHistoryPrompt(by: "5")
        
        guard let lastRecentPrompt = self.viewModel?.aiState.promptGroups.last?.prompts.last else {
            XCTFail("recent prompt is nil")
            return
        }
        XCTAssertEqual(lastRecentPrompt.children.count, 0)
    }
    
    func testInternalOperator() {
        createTaskRecord(text: "123", finishStatus: "failed")
        
        // 最后一个是debug按钮
        let expect = expectation(description: "testInternalOperator")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800)) {
            XCTAssertNotNil(self.model)
            guard let data = self.model?.operates?.data else {
                XCTFail("operates data is nil")
                return
            }
            XCTAssertEqual(data.count, 2)
            self.eventRelay.accept(.chooseOperator(operate: data[1]))
            self.eventRelay.accept(.chooseOperator(operate: data[0]))
            //
            var containDebug = false
            var containDismissPanel = false
            for output in self.outputs {
                if case .debugInfo = output {
                    containDebug = true
                } else if case .dismissPanel = output {
                    containDismissPanel = true
                    break
                }
            }
            XCTAssertTrue(containDebug)
            XCTAssertTrue(containDismissPanel)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3)
    }
    

    
// MARK: - UI层
    enum UIStatus {
        case prepare
        case waiting
        case writing
        case finish
    }
    
    
    var imageDatas: [InlineAIPanelModel.ImageData] {
        return [.init(url: "https://www.baidu.com1", id: "1", checkable: true),
                 .init(url: "https://www.baidu.com2", id: "2", checkable: true),
                 .init(url: "https://www.baidu.com3", id: "3", checkable: true),
                 .init(url: "https://www.baidu.com4", id: "4", checkable: true)]
    }

    func constrcutPanelModel(show: Bool = true, showImage: Bool = false, status: UIStatus) -> InlineAIPanelModel {
        var showList = false
        var showContent = false
        var showInput = false
        var showOperation = false
        var showHistory = false
        var showFeedBack = false
        switch status {
        case .prepare:
            showList = true
            showInput = true
        case .waiting:
            showInput = true
        case .writing:
            showInput = true
        case .finish:
            showContent = true
            showHistory = true
            showOperation = true
            showInput = true
            showFeedBack = true
        }
        
        
        let dragBar = InlineAIPanelModel.DragBar(show: true, doubleConfirm: true)
        let tips = InlineAIPanelModel.Tips(show: showFeedBack, text: "AI can be inaccurate or misleading")
        let feedBack = InlineAIPanelModel.Feedback(show: showFeedBack, like: true, unlike: false)
        let history = InlineAIPanelModel.History(show: showHistory, total: 8, curNum: 5, leftArrowEnabled: true, rightArrowEnabled: false)
        let ops = [InlineAIPanelModel.Operate(text: "replace1", btnType: "primary"),
                   InlineAIPanelModel.Operate(text: "replace2", btnType: "default"),
                   InlineAIPanelModel.Operate(text: "replace3", btnType: "default"),
                   InlineAIPanelModel.Operate(text: "replace4", btnType: "default"),
                   InlineAIPanelModel.Operate(text: "replace5", btnType: "default"),
                   InlineAIPanelModel.Operate(text: "replace6", btnType: "default")]
       let prompts = [InlineAIPanelModel.Prompt(id: "0", icon: "", text:"name1"),
                     InlineAIPanelModel.Prompt(id: "1", icon: "", text: "name2"),
                     InlineAIPanelModel.Prompt(id: "2", icon: "", text: "name3"),
                     InlineAIPanelModel.Prompt(id: "3", icon: "", text: "name4"),
                     InlineAIPanelModel.Prompt(id: "4", icon: "", text: "name5"),
                      InlineAIPanelModel.Prompt(id: "9", icon: "", text: "name6")]
        let groups = [InlineAIPanelModel.PromptGroups(title: "Basic Basic", prompts: prompts),
                     InlineAIPanelModel.PromptGroups(title: "Basic Basic", prompts: prompts)]
        let pm = InlineAIPanelModel.Prompts(show: showList, overlap: false, data: groups)
        let operates = InlineAIPanelModel.Operates(show: showOperation, data: ops)
        
        let images = InlineAIPanelModel.Images(show: showImage, status: showImage ? 1 : 0, data: imageDatas, checkList: [])
        let input = InlineAIPanelModel.Input(show: showInput, status: 0, text: "", placeholder: "AI Guide copy for the first time", writingText:"AI is writing...", showStopBtn: false, showKeyboard: false)
        let range = InlineAIPanelModel.SheetOperate(show: false, text: "12344", enable: true, suffixIcon: nil)
        let model =  InlineAIPanelModel(show: true, dragBar: dragBar, content: showContent ? "With the emergence of ChatGPT, AIGC has entered a more extensive practical stage. In the field of documents, many peers at home and abroad have realized or are in the process of the combination of document creation and Al. Specifically, it can be seen that the analysis of AIGC products of this document is the direct comparison of the concept of flying book documents" : nil, images: images, prompts: pm, operates: operates, input: input, tips: tips, feedback: feedBack, history: history, range: range, conversationId: "", taskId: "")
        return model
    }

    func testOutput() {
        initUIModule()
        let model = constrcutPanelModel(status: .prepare)
        aiUIModule?.showPanel(panel: model)
        if let viewModel = self.uiViewModel {
            viewModel.output.subscribe(onNext: { [weak self] in
                self?.outputs.append($0)
            }).disposed(by: disposeBag)
            eventRelay.bind(to: viewModel.eventRelay).disposed(by: disposeBag)
        }
        
        
        eventRelay.accept(.textViewDidBeginEditing)
        
        eventRelay.accept(.textViewDidEndEditing)
        
        
        eventRelay.accept(.autoActiveKeyboard)

        
        let firstPrommpt = model.prompts?.data.first?.prompts.first
        XCTAssertNotNil(firstPrommpt)
        if let prompt = firstPrommpt {
            eventRelay.accept(.choosePrompt(prompt: prompt))
            XCTAssertEqual(clickPromp?.id ?? "", prompt.id)
            
            eventRelay.accept(.deleteHistoryPrompt(prompt: prompt))
            XCTAssertEqual(deletePrompt?.id ?? "", prompt.id)
            
            self.clickPromp = nil
            eventRelay.accept(.sendRecentPrompt(prompt: prompt))
            XCTAssertEqual(clickPromp?.id ?? "", prompt.id)
        }
        
        eventRelay.accept(.clickMaskErea)
        XCTAssertTrue(self.clickMaskArea == true)
        
        eventRelay.accept(.clickPrePage)
        XCTAssertTrue(self.clickPre == true)
        
        eventRelay.accept(.clickNextPage)
        XCTAssertTrue(self.clickPre == false)
        
        eventRelay.accept(.clickThumbUp(isSelected: true))
        XCTAssertTrue(self.clickFeedbackLike == true)
        
        eventRelay.accept(.clickThumbDown(isSelected: true))
        XCTAssertTrue(self.clickFeedbackLike == false)

        eventRelay.accept(.stopGenerating)
        XCTAssertTrue(self.clickStop)
    }
    
    func testUIImage() {
        initUIModule()
    
        let model = constrcutPanelModel(showImage: true, status: .prepare)
        aiUIModule?.showPanel(panel: model)
        
        for imageModel in imageDatas {
            let img = UIImage()
            uiViewModel?.aiImageDownloadSuccess(with: .init(checkNum: 0, source: .image(img), id: imageModel.id), image: img)
        }
        
        if let viewModel = self.uiViewModel {
            viewModel.output.subscribe(onNext: { [weak self] in
                self?.outputs.append($0)
                switch $0 {
                case .show(let modelWrapper):
                    self?.model = modelWrapper.panelModel
                default:
                    break
                }
            }).disposed(by: disposeBag)
            eventRelay.bind(to: viewModel.eventRelay).disposed(by: disposeBag)
        }
    
        XCTAssertNotNil(downloadImageResults)
        
        // 模拟刷新图片
        aiUIModule?.showPanel(panel: model)
        
        
        // 选中
        eventRelay.accept(.clickCheckbox(InlineAICheckableModel(checkNum: 0, source: .image(UIImage()), id: "1")))
        
        var checkList = uiViewModel?.currentModel?.panelModel.images?.checkList ?? []
        XCTAssertEqual(checkList.count, 1)
        XCTAssertEqual(checkList[0], "1")
    
        // 反选
        eventRelay.accept(.clickCheckbox(InlineAICheckableModel(checkNum: 1, source: .image(UIImage()), id: "1")))
        checkList = uiViewModel?.currentModel?.panelModel.images?.checkList ?? []
        XCTAssertTrue(checkList.isEmpty)
        
        
        // 选中
        let checkModel = InlineAICheckableModel(checkNum: 0, source: .image(UIImage()), id: "2")
        eventRelay.accept(.clickCheckbox(checkModel))
        self.outputs.removeAll()
        eventRelay.accept(.clickAIImage(checkModel))
        
        if case let .presentVC(vc) = self.outputs.last,
           vc.isKind(of: InlineImageBrowserViewController.self) {
            XCTAssertTrue(true)
        } else {
            XCTFail("present vc fail")
        }
    }
    
    func testClickAtDoc() {
        initUIModule()
        let model = constrcutPanelModel(status: .waiting)
        aiUIModule?.showPanel(panel: model)
        if let viewModel = self.uiViewModel {
            viewModel.output.subscribe(onNext: { [weak self] in
                self?.outputs.append($0)
            }).disposed(by: disposeBag)
            eventRelay.bind(to: viewModel.eventRelay).disposed(by: disposeBag)
        }
        
        eventRelay.accept(.clickAt(selectedRange: NSRange()))
        
        XCTAssertTrue(findInsertPickerItems())
    }
    
    func findInsertPickerItems() -> Bool {
        for output in self.outputs {
            if case .insertPickerItems = output {
                return true
            }
        }
        return false
    }

    func testClickAtUser() {
        initUIModule(mentionTypes: [.user])
        let model = constrcutPanelModel(status: .waiting)
        aiUIModule?.showPanel(panel: model)
        if let viewModel = self.uiViewModel {
            viewModel.output.subscribe(onNext: { [weak self] in
                self?.outputs.append($0)
            }).disposed(by: disposeBag)
            eventRelay.bind(to: viewModel.eventRelay).disposed(by: disposeBag)
        }

        eventRelay.accept(.clickAt(selectedRange: NSRange()))
        
        XCTAssertTrue(findInsertPickerItems())
    }

    func testSubpanel() {
        initUIModule()
        let model = constrcutPanelModel(status: .waiting)
        aiUIModule?.showPanel(panel: model)
        if let viewModel = self.uiViewModel {
            viewModel.output.subscribe(onNext: { [weak self] in
                self?.outputs.append($0)
            }).disposed(by: disposeBag)
            eventRelay.bind(to: viewModel.subPromptEventRelay).disposed(by: disposeBag)
        }
        guard let prompt = model.prompts?.data.first?.prompts.first else {
            XCTFail("prompt is nil")
            return
        }
        XCTAssertNil(clickSubPrompt)
        eventRelay.accept(.choosePrompt(prompt: prompt))
        XCTAssertNotNil(clickSubPrompt)
        
        
        XCTAssertNil(deletePrompt)
        eventRelay.accept(.deleteHistoryPrompt(prompt: prompt))
        XCTAssertNotNil(deletePrompt)
    }
}

extension InlineAIPanelViewModelTests: LarkInlineAISDKDelegate {
    
    public func getBizReportCommonParams() -> [AnyHashable : Any] {
        return [:]
    }
    
    
    public func getShowAIPanelViewController() -> UIViewController {
        return testVC
    }
    
    /// 横竖屏切换样式，目前iPhone不支持横屏，只有iPad会根据这个来设定，不返回默认不支持横屏
    public var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? { return nil }
    
    
    public func onHistoryChange(text: String) {
        self.historyText = text
    }
    
    /// 面板高度变化时通知业务方
    public func onHeightChange(height: CGFloat) {
        
    }

    func testPrompt2(text: String) -> AIPrompt {
        let templates =  PromptTemplates(templatePrefix: "我是前缀", templateList: [PromptTemplate(templateName: "templateName", key: "key", placeHolder: "placeHolder", defaultUserInput: "defaultUserInput")])
        return AIPrompt(id: "520", localId: "520", icon: "", text: text, templates: templates, callback: .init(onStart: {
            return AIPrompt.PromptConfirmOptions(isPreviewMode: false, param: [:])
        }, onMessage: { _ in
            
        }, onError: { error in
            
        }, onFinish: { _ in
            return []
        }))
    }
    
    func retryButtonFunc() -> OperateButton {
        return OperateButton(key: "retry", text: "重试", isPrimary: false) { [weak self] _, _ in
            self?.aiModule?.retryCurrentPrompt()
            self?.createTaskRecord(text: "重试")
        }
    }
    
    public func getUserPrompt() -> AIPrompt {
        
        let retryButton = retryButtonFunc()
        
        let group = AIPromptGroup(title: "测试1", prompts: [testPrompt(text: "ABC"),
                                               testPrompt(text: "DEF"),
                                               testPrompt(text: "GHI"),
                                               testPrompt(text: "JKL"),
                                               testPrompt(text: "MNO")])
        let showSubPanelButton = OperateButton(key: "c", text: "二级面板", isPrimary: false, promptGroups: [group, group]) { _, _ in

        }
        
        let existButton = existButtonFunc()
        
        
        return AIPrompt(id: nil, icon: "", text: "", templates: nil, callback: AIPrompt.AIPromptCallback(onStart: { [weak self] in
            self?.status = .onStart
            return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: [:])
        }, onMessage: { [weak self] _ in
            self?.status = .onMessage
        }, onError: { [weak self] _ in
            self?.status = .onError
        }, onFinish: { [weak self] _ in
            self?.status = .onFinish
            return [existButton, showSubPanelButton, retryButton]
        }))
    }
    
    func getEncryptId() -> String? {
        return nil
    }
}


// MARK: -  LarkInlineAIUIDelegate
extension InlineAIPanelViewModelTests: LarkInlineAIUIDelegate {
    
    func onClickAtPicker(callback: @escaping (PickerItem?) -> Void) {
        callback(nil)
    }

    func onInputTextChange(text: String) {
        textChange = text
    }
    
    func onClickPrompt(prompt: LarkAIInfra.InlineAIPanelModel.Prompt) {
        clickPromp = prompt
    }
    
    func onClickSubPrompt(prompt: LarkAIInfra.InlineAIPanelModel.Prompt) {
        clickSubPrompt = prompt
    }
    
    func onClickOperation(operate: LarkAIInfra.InlineAIPanelModel.Operate) {
        clickOperation = operate
    }
    
    func onClickSheetOperation() {
        clickSheetOperation = true
    }
    
    func onClickStop() {
        clickStop = true
    }
    
    func onClickFeedback(like: Bool, callback: ((LarkAIInfra.LarkInlineAIFeedbackConfig) -> Void)?) {
        clickFeedbackLike = like
    }
    
    func onClickHistory(pre: Bool) {
        clickPre = pre
    }
    
    func onClickMaskArea(keyboardShow: Bool) {
        clickMaskArea = true
    }
    
    func keyboardChange(show: Bool) {
        keyboardChange = show
    }
    
    func onSwipHidePanel(keyboardShow: Bool) {
        swipHidePanel = true
    }
    
    func panelDidDismiss() {
        panelDismiss = true
    }
    
    func onDeleteHistoryPrompt(prompt: InlineAIPanelModel.Prompt) {
        deletePrompt = prompt
    }
    
    func imagesDownloadResult(results: [InlineAIImageDownloadResult]) {
        downloadImageResults = results
    }
    
    func onExtraOperation(type: String, data: Any?) {
        
    }
}
