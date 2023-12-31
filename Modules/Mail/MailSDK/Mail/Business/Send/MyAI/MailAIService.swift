//
//  MailAIService.swift
//  MailSDK
//
//  Created by tanghaojin on 2023/6/1.
//


import UIKit
import RustPB
import LarkAIInfra
import RxSwift
import WebKit
import LarkWebViewContainer
import LarkModel
import LarkContainer

typealias QuickAction = Email_Client_V1_QuickAction
typealias QuickActionReq = Email_Client_V1_MailAIGetQuickActionRequest
typealias QuickActionResp = Email_Client_V1_MailAIGetQuickActionResponse
typealias PromptActionType = Email_Client_V1_PromptActionType
typealias CreateTaskReq = Email_Client_V1_MailAICreateTaskRequest
typealias CreateTaskResp = Email_Client_V1_MailAICreateTaskResponse
typealias TaskStatusReq = Email_Client_V1_MailAIGetTaskStatusRequest
typealias TaskStatusResp = Email_Client_V1_MailAIGetTaskStatusResponse
typealias TaskStatus = Email_Client_V1_MailAITaskStatus
typealias StopTaskReq = Email_Client_V1_MailAICancelTaskRequest
typealias StopTaskResp = Email_Client_V1_MailAICancelTaskResponse

protocol MailAIServiceDelegate: AnyObject {
    func getShowAIPanelViewController() -> UIViewController
    func showAIStopAlert(quiteBlock: @escaping (() -> Void))
    func getEditorContent(needSelect: Bool, processContent: @escaping (([String: Any]) -> Void))
    func getEditorHisoryContent(processContent: @escaping ((String) -> Void))
    func insertEditorContent(content: String, preview: Bool, toTop: Bool)
    func clearAIBg(needSelect: Bool)
    func clearAIContent()
    func quiteAI(insertContent: Bool)
    func openQuickActionPanel()
    func clickAiPanel(click: String, commandType: String)
    func updateMyAIPanelHeight(height: CGFloat)
    func applyEditorContent(dataSet: [String: Any],
                            operate: String,
                            bottomOffset: CGFloat?,
                            topOffset: CGFloat?,
                            aiHeight: CGFloat)
    func adjuestOffset(operate: String,
                       bottomOffset: CGFloat?,
                       topOffset: CGFloat?,
                       aiHeight: CGFloat)
    func adjuestWebViewInset(inset: UIEdgeInsets)
//    func setMockSelection(isMock: Bool)
}

class MailAIService: NSObject {
    private var observation: NSKeyValueObservation?
    lazy var webView: MailSendWebView = {
        let view = self.accountContext.sharedServices.editorLoader.AIEditor
        view.sendWebViewDelegate = self
        view.scrollView.isScrollEnabled = true
        view.disableScroll = false
        view.scrollView.delegate = self
        view.sendVCJSHandlerInited = true
        view.isMyAIPreview = true
        view.backgroundColor = UIColor.ud.bgFloat
        view.isOpaque = false
        return view
    }()
    
    lazy var inlineAIModule: LarkInlineAIUISDK = {
        let config = InlineAIConfig(captureAllowed: true, userResolver: accountContext.sharedServices.provider.resolver)
        return LarkInlineAIModuleGenerator.createUISDK(config: config,
                                                       customView: self.webView,
                                                       delegate: self)
    }()
    struct AITask {
        enum TaskStatus: Int {
            case start = -1
            case success = 0
            case fail = 1
            case stop = 2
            case process = 3
        }
        var taskId: String?
        let displayContent: String
        var action: QuickAction?
        var uniqueId: String?
        var seqId: Int64 = -1
        var status: TaskStatus = TaskStatus.start
        var content: String?
        var params: [String: String] = [:]
        var userPrompt: String?
        let subPanelContent: String //subpannel输入的内容
        var like: Bool? // nil 表示没设置；true表示点赞；false表示点踩；
    }
    struct MyAIContext {
        var contentOffset: CGPoint?
        var viewHeight: CGFloat = 0
        var observation: NSKeyValueObservation?
        var selection: NSString?
        var alreadyMockSelection: Bool = false
        var isCollapsed: Bool = false
        var isCollapsedBegin: Bool = false
        var selectionBottomOffset: CGFloat?
        var selectionTopOffset: CGFloat?
        var bgNeedToTop: Bool = false
        var sceneType: String = "unselect_content"
        var mailContent: String = "false"
        var hasHistory: Bool = false
        var userSelect: Bool = false
        var inAIMode: Bool = false
        var inWeakAIMode: Bool = false
        var frozenFrame: Bool = false
        var frozenKeyboard = false
        var forceScroll = false
        var aiModeOffsetY: CGFloat?
        var draftId: String = ""
        var draftToNames: String = ""
    }
    let disposeBag = DisposeBag()
    let accountContext: MailAccountContext
    var task: AITask?
    var sessionId: String?
    var reportId: String = ""
    var title: String = ""
    var actions: [QuickAction]?
    var curPage: Int = -1
    var pageContent: [AITask] = []
    var confirmType: QuickAction.ConfirmType?
    var sendText: String?  // 默认不设置，点击发送保留内容，点击指令给“”
    var onclickSend: Bool = false
    var scrollByUser: Bool = false
    var scrollContentHeight: CGFloat = 0.0
    var totalPage: Int {
        return self.pageContent.count
    }
    var myAIContext: MyAIContext = MyAIContext()
    var weakModeScrollByUser = false {
        didSet {
            if oldValue == true && weakModeScrollByUser == false {
                // 退出滚动模式
                self.delegate?.adjuestWebViewInset(inset: UIEdgeInsets(top: 0,
                                                                       left: 0,
                                                                       bottom: 0,
                                                                       right: 0))
            } else if oldValue == false && weakModeScrollByUser == true {
                // 设置为滚动
                self.delegate?.adjuestWebViewInset(inset: UIEdgeInsets(top: 0,
                                                                       left: 0,
                                                                       bottom: self.myAIContext.viewHeight,
                                                                       right: 0))
                
            }
        }
    }
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    static let TitleKey = "title"
    static let ContentKey = "ContentKey"
    static let SelectionKey = "selectionKey"
    static let AIEmptyKey = "aiEmptyKey"
    static let AIUserSelect = "aiUserSelect"
    static let AIHasHistoryKey = "aiHasHistoryKey"
    static let RestContentKey = "restContent"
    static let PreviewInsertKey = "insert"
    static let PreviewReplaceKey = "replace"
    let regionNonCompliance = 13020
    let brandNonCompliance = 13021
    
    init(accountContext: MailAccountContext ) {
        self.accountContext = accountContext
        super.init()
        PushDispatcher
            .shared
            .$mailAITaskStatusPush
            .wrappedValue
            .observeOn(MainScheduler.instance)
            .subscribe({ [weak self] change in
                if let statusChange = change.element {
                    self?.handlePush(change: statusChange)
                }
            }).disposed(by: disposeBag)
    }
    
    weak var delegate: MailAIServiceDelegate?
    
    func showAIPanel(params: [String: Any], subPanel: Bool = false) {
        do {
            if params.isEmpty {
                return
            }
            let decoder = JSONDecoder()
            let data = try JSONSerialization.data(withJSONObject: params)
            self.myAIContext.inAIMode = true
            if !subPanel {
                let model = try decoder.decode(InlineAIPanelModel.self, from: data)
                inlineAIModule.showPanel(panel: model)
            } else {
                let model = try decoder.decode(InlineAISubPromptsModel.self, from: data)
                inlineAIModule.showSubPromptsPanel(prompts: model)
            }
            
        } catch {
            MailLogger.error("[MailAI] decode InlineAI model error:\(error)")
        }
    }
    deinit {
        MailLogger.info("[MailAI] service deinit")
        stopObserving()
    }
}

// 构造面板显示数据
extension MailAIService {
    //首次进入生成快捷指令面板
    func genQuickActionPanel(actions: [QuickAction],
                             highlight: Bool = false,
                             keyWord: String = "",
                             showKeyboard: Bool = false) -> [String: Any] {
        var params: [String: Any] = genBasic(show: true,
                                             maskType: "fullScreen",
                                             content: "")
        params["input"] = genInput(status: 0,
                                   show: true,
                                   text: keyWord,
                                   placeHolder: BundleI18n.MailSDK.Mail_MyAI_EnterToUseAI_EnterQuestions_HelperText,
                                   showKeyboard: showKeyboard)
        var filterActions = actions
        if self.myAIContext.mailContent == "false" {
            filterActions = filterActions.filter({ action in
                return action.groupType != .basic
            })
        }
        if !self.myAIContext.hasHistory {
            filterActions = filterActions.filter({ action in
                return action.groupType != .draftReply &&
                action.groupType != .draftReplyCustom
            })
        }
        params["prompts"] = genPrompts(actions: filterActions,
                                       show: true,
                                       overLap: false,
                                       hightlight: highlight,
                                       keyWord: keyWord)
        
        params["dragBar"] = genDragBar(show: filterActions.contains { $0.groupType == .basic || $0.groupType == .template } ? true : false,
                                       doubleConfirm: false)
        return params
    }
    //调整，进入二级指令面板
    func genQuickActionSubPanel(arrowPannel: Bool) -> [String: Any] {
        guard let actions = self.actions else { return [:] }
        var params: [String: Any] = [:]
        params["dragBar"] = genDragBar(show: true,
                                       doubleConfirm: true)
        params["data"] = genPromptData(actions: actions,
                                       subPanel: true,
                                       arrowPanel: arrowPannel)
        return params
    }
    //获取内容后的面板更新
    func genContentPanel(content: String,
                         isProcessing: Bool,
                         preview: Bool,
                         keyWord: String = "",
                         like: Bool? = nil) -> [String: Any] {
        let maskType = preview ? "fullScreen" : "aroundPanel"
        let lock = preview || isProcessing
        var params: [String: Any] = genBasic(show: true,
                                             maskType: maskType,
                                             content: preview ? content : nil,
                                             lock: lock)
        if keyWord.isEmpty {
            params["input"] = genInput(status: isProcessing ? 1 : 0,
                                       show: true,
                                       placeHolder: isProcessing ? "" : BundleI18n.MailSDK.Mail_MyAI_EnterToUseAI_EnterQuestions_HelperText,
                                       writingText: isProcessing ? BundleI18n.MailSDK.Mail_MyAINickname_AIWritingNow_Text : BundleI18n.MailSDK.Mail_MyAI_EnterToUseAI_EnterQuestions_HelperText,
                                       showStopBtn: isProcessing ? true : false,
                                       showKeyboard: false )
        } else {
            params["input"] = genInput(status: 0,
                                       show: true,
                                       text: keyWord,
                                       showStopBtn: false,
                                       showKeyboard: true)
        }
        
        var show = false
        if preview && !content.isEmpty {
            show = true
        }
        params["dragBar"] = genDragBar(show: show,
                                       doubleConfirm: true)
        if !isProcessing {
            params["operates"] = genOperations(show: true, preview: preview)
            params["tips"] = genTip(show: true, text: BundleI18n.MailSDK.Mail_MyAI_ChatboxEnter_AIDisclaimer_Placeholder)
            if let like = like {
                params["feedback"] = genFeedback(show: true, like: like, unlike: !like)
            } else {
                params["feedback"] = genFeedback(show: true)
            }
        }
        if self.totalPage > 1 && !isProcessing {
            params["history"] = genHistory(show: true, total: self.totalPage, cur: self.curPage, leftArrowEnabled: self.curPage > 0, rightArrowEnabled: self.curPage < self.totalPage - 1)
        }
        return params
    }
    // 点击了模板类型的action，弹出的面板
    func genTemplatePanel(prefix: String) -> [String: Any] {
        var params: [String: Any] = genBasic(show: true,
                                             maskType: "fullScreen",
                                             content: "")
        params["input"] = genInput(status: 0,
                                   show: true,
                                   text: prefix,
                                   showStopBtn: false,
                                   showKeyboard: true)
        params["dragBar"] = genDragBar(show: false,
                                       doubleConfirm: true)
        return params
    }
    private func genDragBar(show: Bool,
                            doubleConfirm: Bool) -> [String: Any] {
        var dragBar: [String: Any] = [:]
        dragBar["show"] = show
        dragBar["doubleConfirm"] = doubleConfirm
        return dragBar
    }
    private func genTip(show: Bool, text: String) -> [String: Any] {
        var tip: [String: Any] = [:]
        tip["show"] = show
        tip["text"] = text
        return tip
    }
    private func genFeedback(show: Bool,
                             like: Bool = false,
                             unlike: Bool = false) -> [String: Any] {
        var feedback: [String: Any] = [:]
        feedback["show"] = show
        feedback["like"] = like
        feedback["unlike"] = unlike
        return feedback
    }
    private func genBasic(show: Bool,
                          maskType: String,
                          content: String?,
                          lock: Bool? = nil) -> [String: Any] {
        var params: [String: Any] = [:]
        params["show"] = show
        params["maskType"] = maskType
        if let content = content, !content.isEmpty {
            params["content"] = content
        }
        params["taskId"] = self.task?.taskId ?? ""
        params["conversationId"] = ""
        if let lock = lock {
            params["lock"] = lock
        }
        
        return params
    }
    
    private func genInput(status: Int,
                          show: Bool,
                          text: String? = nil,
                          placeHolder: String? = nil,
                          writingText: String? = nil,
                          showStopBtn: Bool? = nil,
                          showKeyboard: Bool) -> [String: Any] {
        var input: [String: Any] = [:]
        input["status"] = status
        input["show"] = show
        input["text"] = text ?? ""
        input["placeholder"] = placeHolder ?? ""
        input["writingText"] = writingText ?? ""
        input["showStopBtn"] = showStopBtn ?? false
        // 需要展示keyboard再设置
        if showKeyboard {
            input["showKeyboard"] = showKeyboard
        }
        
        return input
    }
    
    private func genPrompts(actions: [QuickAction],
                            show: Bool,
                            overLap: Bool,
                            hightlight: Bool = false,
                            keyWord: String = "") -> [String: Any] {
        var prompts: [String: Any] = [:]
        prompts["show"] = show
        prompts["overlap"] = overLap
        if !show {
            return prompts
        }
        prompts["data"] = genPromptData(actions: actions,
                                        subPanel: false,
                                        highlight: hightlight,
                                        keyWord: keyWord)
        return prompts
    }
    func genPromptData(actions: [QuickAction],
                       subPanel: Bool,
                       highlight: Bool = false,
                       keyWord: String = "",
                       arrowPanel: Bool = false) -> [[String: Any]] {
        func mapIconKey(iconKey: String) -> String {
            if iconKey == "icon_slides_animation_outlined" {
                return "SlidesAnimationOutlined"
            } else if iconKey == "icon_ccm_edit_continue_outlined" {
                return "CcmEditContinueOutlined"
            } else if iconKey == "icon_addexpand_outlined" {
                return "AddexpandOutlined"
            } else if iconKey == "icon_abbreviation_outlined" {
                return "AbbreviationOutlined"
            } else if iconKey == "icon_effects_outlined" {
               return "EffectsOutlined"
            }
            return iconKey
        }
        var basicGroupArray: [[String: Any]] = []
        var replyGroupArray: [[String: Any]] = []
        var templateGroupArray: [[String: Any]] = []
        var subChangeToneArray: [[String: Any]] = []
        var subBasicArray: [[String: Any]] = []
        //var draftMailArray: [[String: Any]] = []
        for action in actions {
            var prompt: [String: Any] = [:]
            prompt["id"] = String(action.id)
            prompt["icon"] = mapIconKey(iconKey: action.iconKey)
            let color = UIColor.ud.textTitle.hex6 ?? "#1f2329"
            let colorStyle = "<span style='color: \(color)'>"
            let name = self.getActionName(action: action)
            if highlight {
                if let range = name.range(of: keyWord) {
                    let pre = name[..<range.lowerBound]
                    let last = name[range.upperBound...]
                    let mid = "<span style='color: #1456F0'>" + keyWord + "</span>"
                    prompt["text"] = pre + mid + last
                } else {
                    prompt["text"] = colorStyle + name + "</span>"
                }
            } else {
                prompt["text"] = colorStyle + name + "</span>"
            }
            prompt["rightArrow"] = false
            // 外部
            if !subPanel {
                switch action.groupType {
                case .basic:
                    basicGroupArray.append(prompt)
                case .draftReply, .draftReplyCustom:
                    replyGroupArray.append(prompt)
                case .template:
                    templateGroupArray.append(prompt)
                @unknown default:
                    break
                }
            } else if arrowPanel {
                if action.groupType == .changeTone {
                    subChangeToneArray.append(prompt)
                }
            } else if action.secondAction != .disallow {
                // sub prompt
                switch action.groupType {
                case .basic:
                    subBasicArray.append(prompt)
                case .none, .chatInput:
                    if action.childType == .changeTone {
                        // 存在下一级菜单
                        prompt["rightArrow"] = true
                    }
                    subBasicArray.append(prompt)
                @unknown default:
                    break
                }
            }
            
        }
        var promptsData: [[String: Any]] = []
        if !subPanel {
            genPromptGroup(array: basicGroupArray, title: BundleI18n.MailSDK.Mail_MyAI_BasicFeatures_Tag, output: &promptsData)
            genPromptGroup(array: replyGroupArray, title: BundleI18n.MailSDK.Mail_MyAI_GenerateDraft_Title, output: &promptsData)
            genPromptGroup(array: templateGroupArray, title: BundleI18n.MailSDK.Mail_MyAI_Templates_Tag, output: &promptsData)
        } else if arrowPanel {
            genPromptGroup(array: subChangeToneArray, title: "", output: &promptsData)
        } else {
            genPromptGroup(array: subBasicArray, title: "", output: &promptsData)
        }
        return promptsData
    }
    func genPromptGroup(array: [[String: Any]],
                        title: String,
                        output: inout [[String: Any]]) {
        if array.count > 0 {
            var group: [String: Any] = [:]
            if !title.isEmpty {
                group["title"] = title
            }
            group["prompts"] = array
            output.append(group)
        }
    }
    
    enum OperationType: String {
        case complete
        case replace
        case insertBelow
        case insert
        case change
        case retry
        case quit
        case unknow
    }
    
    func genOperations(show: Bool, preview: Bool) -> [String: Any] {
        var operations: [String: Any] = [:]
        operations["show"] = show
        if !show {
            return operations
        }
        let complete = genOperation(text: BundleI18n.MailSDK.Mail_MyMI_ChatbotCompose_Done_Button,
                                    type: .complete, btnType: "primary")
        let replace = genOperation(text: BundleI18n.MailSDK.Mail_MyAI_Editing_Replace_Bttn,
                                   type: .replace, btnType: "primary")
        let insertBelow = genOperation(text: BundleI18n.MailSDK.Mail_MyAI_Editing_InsertBelow_Bttn,
                                  type: .insertBelow, btnType: "default")
        let insert = genOperation(text: BundleI18n.MailSDK.Mail_MyAI_Insert_Button,
                                  type: .insert, btnType: "primary")
        let change = genOperation(text: BundleI18n.MailSDK.Mail_MyAI_EditingCommand_Adjust_Button,
                                  type: .change, btnType: "default")
        let retry = genOperation(text: BundleI18n.MailSDK.Mail_MyAI_Editing_Retry_Bttn,
                                 type: .retry, btnType: "default")
        let quit = genOperation(text: BundleI18n.MailSDK.Mail_MyAI_Editing_Leave_Bttn,
                                type: .quit, btnType: "default")
        if preview {
            if self.myAIContext.isCollapsed {
                // 没有选区
                operations["data"] = [insert, retry, change, quit]
            } else {
                // 有选区
                operations["data"] = [replace, insertBelow, retry, change, quit]
            }
        } else {
            operations["data"] = [complete, retry, change, quit]
        }
        return operations
    }
    func genOperation(text: String, type: OperationType, btnType: String) -> [String: Any] {
        var operation: [String: Any] = [:]
        operation["text"] = text
        operation["btnType"] = btnType
        operation["type"] = type.rawValue
        return operation
    }
    func genHistory(show: Bool,
                    total: Int,
                    cur: Int,
                    leftArrowEnabled: Bool,
                    rightArrowEnabled: Bool) -> [String: Any] {
        var history: [String: Any] = [:]
        if !show {
            return history
        }
        history["show"] = show
        history["total"] = total
        history["curNum"] = cur + 1
        history["leftArrowEnabled"] = leftArrowEnabled
        history["rightArrowEnabled"] = rightArrowEnabled
        return history
    }
}

extension MailAIService {
    // 初始化面板
    func initAITask(draftMail: Bool = false,
                    title: String = "",
                    hasContent: Bool = true,
                    hasHistory: Bool = false,
                    userSelect: Bool = false,
                    draftId: String,
                    toNames: String) {
        self.title = title.removeAllSpaceAndNewlines
        self.myAIContext.mailContent = hasContent ? "true" : "false"
        self.myAIContext.hasHistory = hasHistory
        self.myAIContext.userSelect = userSelect
        self.myAIContext.draftId = draftId
        self.myAIContext.draftToNames = toNames
        self.reportId = UUID().uuidString
        self.reportAIInvoke(scene: draftMail ? "editor_button" : "toolbar")
        // 已经请求过快捷指令的不重复请求
        if let actions = self.actions {
            if draftMail {
                self.onClickDraftMail(hasHistory: hasHistory)
            } else {
                self.delegate?.openQuickActionPanel()
                self.showAIPanel(params: genQuickActionPanel(actions: actions))
            }
        } else {
            MailDataServiceFactory.commonDataService?.mailAIGetQuickActionRequest().subscribe( onNext: { [weak self]  actions in
                guard let `self` = self else { return }
                self.actions = actions
                if draftMail {
                    self.onClickDraftMail(hasHistory: hasHistory)
                } else {
                    self.delegate?.openQuickActionPanel()
                    self.showAIPanel(params: self.genQuickActionPanel(actions: actions))
                }
            }, onError: { [weak self] (error) in
                MailLogger.error("initAITask error \(error)")
                guard let `self` = self else { return }
                self.showErrorToast()
            }).disposed(by: disposeBag)
        }
    }
    func reportQuickAction(action: QuickAction) {
        let name = action.reportName
        self.delegate?.clickAiPanel(click: "quick_command", commandType: name)
    }
    // 创建一个快捷指令任务
    func createQuickActionTask(action: QuickAction,
                               displayContent: String,
                               params: [String: String],
                               actionType: PromptActionType,
                               needCurrentContent: Bool = false,
                               userPrompt: String?,
                               subPanelContent: String = "",
                               isRetry: Bool = false) {
        self.scrollByUser = false
        self.weakModeScrollByUser = false
        let taskId = UUID().uuidString
        let task = AITask(taskId: taskId,
                          displayContent: displayContent,
                          params: params,
                          userPrompt: userPrompt,
                          subPanelContent: subPanelContent)
        self.task = task
        self.onclickSend = false
        // 模板类，回复类指令，如果userSelect选中态，强制使用强确认模式
        if self.confirmType == nil &&
            self.myAIContext.userSelect &&
            (action.groupType == .template ||
             action.groupType == .draftReply ||
             action.groupType == .draftReplyCustom) {
            self.confirmType = .hard
        }
        var preview = action.confirmType == .hard
        if let type = self.confirmType {
            preview = type == .hard
        } else {
            self.confirmType = action.confirmType
        }
        self.myAIContext.inWeakAIMode = !preview
        let content = needCurrentContent ? getCurrentContent() : ""
        self.showAIPanel(params: self.genContentPanel(content: content,
                                                      isProcessing: true,
                                                      preview: preview))
        var actionId: Int64? = action.id
        if action.groupType == .chatInput {
            actionId = nil
        }
        if self.accountContext.featureManager.open(.promptOptAI, openInMailClient: false) {
            MailDataServiceFactory.commonDataService?.getTaskContext(hasHistory: self.myAIContext.hasHistory, id: self.myAIContext.draftId, names: self.myAIContext.draftToNames)
                .subscribe( onNext: { [weak self]  context in
                guard let `self` = self else { return }
                var copy_params = params
                copy_params["mail_context"] = context
                self.sendCreateTask(taskId: taskId,
                                    displayContent: displayContent,
                                    action: action,
                            actionType: actionType,
                            actionId: actionId,
                            params: copy_params,
                            userPrompt: userPrompt,
                                    isRetry: isRetry)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                //点击创建任务，失败后，UI更新
                MailLogger.error("getTaskContext error \(error)")
                self.sendCreateTask(taskId: taskId,
                            displayContent: displayContent,
                                    action: action,
                                    actionType: actionType,
                            actionId: actionId,
                            params: params,
                            userPrompt: userPrompt,
                                    isRetry: isRetry)
            }).disposed(by: disposeBag)
        } else {
            self.sendCreateTask(taskId: taskId,
                        displayContent: displayContent,
                                action: action,
                                actionType: actionType,
                        actionId: actionId,
                        params: params,
                        userPrompt: userPrompt,
                                isRetry: isRetry)
        }
        
    }
    func sendCreateTask(taskId: String,
                        displayContent: String,
                        action: QuickAction,
                     actionType: PromptActionType,
                     actionId: Int64?,
                     params: [String: String],
                        userPrompt: String?,
                        isRetry: Bool) {
        MailDataServiceFactory.commonDataService?.mailAICreateTaskRequest(taskId: taskId,
                                                                          displayContent: displayContent,
                                                                          sessionId: self.sessionId,
                                                                          actionType: actionType,
                                                                          actionId: actionId,
                                                                          params: params,
                                                                          userPrompt: userPrompt).subscribe( onNext: { [weak self]  resp in
            guard let `self` = self else { return }
            if resp.statusCode == 0 {
                self.startTask(uniqueId: taskId, action: action)
                self.sessionId = resp.sessionID
                self.reportAICreate(taskId: taskId, isRetry: isRetry)
            } else if resp.statusCode == self.regionNonCompliance {
                //地区不合规
                
                self.showErrorToast(toast: BundleI18n.MailSDK.Mail_MyAI_AINotAvailable_aiName_SystemText(self.getAIDefaultName())
)
            } else if resp.statusCode == self.brandNonCompliance {
                //客户端品牌不合规
                self.showErrorToast(toast: BundleI18n.MailSDK.Mail_MyAI_UseLarkAccessAI_aiName_SystemText(self.getAIDefaultName()))
            }
        }, onError: { [weak self] (error) in
            guard let `self` = self else { return }
            //点击创建任务，失败后，UI更新
            MailLogger.error("createQuickActionTask error \(error)")
            self.showErrorToast()
        }).disposed(by: disposeBag)
    }
    func getAIDefaultName() -> String {
        return self.accountContext.provider.myAIServiceProvider?.aiDefaultName ?? ""
    }
    // 处理push
    func handlePush(change: MailAITaskStatusPushChange) {
        guard let curTask = self.task, (curTask.status == .start ||
                                        curTask.status == .process) else { return }
        guard let localId = curTask.uniqueId, localId == change.taskStatus.uniqueTaskID else { return }
        guard let action = curTask.action else { return }
        var actionType = action.confirmType
        if let type = self.confirmType {
            actionType = type
        }
        switch change.taskStatus.status {
        case .failed:
            self.showErrorToast()
        case .success:
            // 生成内容
            let content = curTask.subPanelContent + change.taskStatus.content
            self.taskSuccess(content: content)
            var preview = true
            if actionType == .weak || actionType == .weakAppend {
                // 直接显示在屏幕上
                self.delegate?.insertEditorContent(content: content,
                                                   preview: false,
                                                   toTop: false)
                preview = false
            } else {
                self.insertPreviewContent(content: content)
            }
            let param = self.genContentPanel(content: content,
                                             isProcessing: false,
                                             preview: preview)
            if !change.taskStatus.content.isEmpty {
                self.sendText = nil
            }
            self.showAIPanel(params: param)
            self.feedbackGenerator.impactOccurred()
        case .processing:
            // 生成内容
            if change.taskStatus.seqID > curTask.seqId {
                self.task?.seqId = change.taskStatus.seqID
                self.task?.content = change.taskStatus.content
                self.task?.status = .process
                var preview = true
                let content = curTask.subPanelContent + change.taskStatus.content
                if actionType == .weak || actionType == .weakAppend {
                    self.delegate?.insertEditorContent(content: content,
                                                       preview: false,
                                                       toTop: false)
                    preview = false
                } else {
                    self.insertPreviewContent(content: content)
                }
                let param = self.genContentPanel(content: content,
                                                 isProcessing: true,
                                                 preview: preview)
                if !change.taskStatus.content.isEmpty {
                    self.sendText = nil
                }
                self.showAIPanel(params: param)
            }
        case .offline:
            // 直接退出
            self.showErrorToast()
        case .tnsblock:
            MailLogger.info("[MailAI] tnsblock, type \(String(describing: self.confirmType))")
            self.task?.status = .fail
            self.sendText = nil
            if self.confirmType == .hard {
                self.insertPreviewContent(content: BundleI18n.MailSDK.Mail_MyAI_ChatboxWrongAnswer_TryAgain_Text)
                let param = self.genContentPanel(content: BundleI18n.MailSDK.Mail_MyAI_ChatboxWrongAnswer_TryAgain_Text,
                                                 isProcessing: false,
                                                 preview: true)
                self.showAIPanel(params: param)
            } else {
                self.delegate?.insertEditorContent(content: BundleI18n.MailSDK.Mail_MyAI_ChatboxWrongAnswer_TryAgain_Text,
                                                       preview: false,
                                                       toTop: false)
                let param = self.genContentPanel(content: BundleI18n.MailSDK.Mail_MyAI_ChatboxWrongAnswer_TryAgain_Text,
                                                 isProcessing: false,
                                                 preview: false)
                self.showAIPanel(params: param)
            }
        @unknown default:
            break
        }
    }
    func showErrorToast(toast: String? = nil) {
        if let view = self.delegate?.getShowAIPanelViewController().view  {
            if let toast = toast {
                MailRoundedHUD.showFailure(with: toast,
                                           on: view)
            } else {
                var title = BundleI18n.MailSDK.Mail_MyAI_ServiceUnavailable_Retry_aiName_Toast(self.getAIDefaultName())
                if let nickName = self.accountContext.provider.myAIServiceProvider?.aiNickName, !nickName.isEmpty {
                    title = BundleI18n.MailSDK.Mail_MyAINickname_ServiceUnavailable_Retry_Toast(nickName)
                }
                MailRoundedHUD.showFailure(with: title,
                                           on: view)
            }
        }
        self.task?.status = .fail
        if self.pageContent.isEmpty {
            //失败的时候，如果没有历史记录，直接退出
            self.quiteAI(insertContent: false)
        } else if let task = self.task {
            var preview = true
            if let type = self.confirmType, type == .weak {
                preview = false
            }
            var resTask: AITask? = task
            if !task.content.isEmpty {
                // 已经输出了内容的要保留
                self.updatePageContent(task: task)
            } else {
                // 没有输出内容的，要用前一个记录的内容
                resTask = getCurrentTask()
            }
            let param = self.genContentPanel(content: resTask?.content ?? "",
                                             isProcessing: false,
                                             preview: preview,
                                             keyWord: self.sendText ?? "")
            self.showAIPanel(params: param)
        }
        self.cancelTask()
    }
    func showQuiteAlert(clickMask: Bool, needAlert: Bool = true) {
        if let task = self.task {
            if self.confirmType == .weak && (task.status == .success ||
                                                     task.status == .stop ) {
                var insertContent = false
                if clickMask {
                    insertContent = true
                } else {
                    self.delegate?.clearAIContent()
                }
                self.quiteAI(insertContent: insertContent)
            } else {
                if !needAlert {
                    alertTodo(showAlert: needAlert)
                } else {
                    self.delegate?.showAIStopAlert(quiteBlock: { [weak self] in
                        self?.alertTodo(showAlert: needAlert)
                    })
                }
            }
        } else {
            self.quiteAI(insertContent: false)
        }
    }
    func alertTodo(showAlert: Bool) {
        self.cancelTask()
        var insertContent = false
        if self.confirmType == .hard {
            self.insertPreviewContent(content: "")
        } else {
            /// 弱确认模式，点击退出，不保留内容
            ///  点击空白，弹出alert，点退出，保留内容
            if showAlert {
                insertContent = true
            } else {
                self.delegate?.clearAIContent()
            }
        }
        self.quiteAI(insertContent: insertContent)
    }
    func quiteAI(insertContent: Bool,
                 needBlur: Bool = false,
                 needClearAiBg: Bool = true) {
        if insertContent {
            self.reportAIApply()
        }
        self.reportAIFeedback()
        self.clearPageContent()
        self.task = nil
        self.sessionId = nil
        self.reportId = ""
        var needSelect = false
        if self.confirmType == .weak && needBlur == false {
            needSelect = true
        }
        self.confirmType = nil
        self.myAIContext.inWeakAIMode = false
        self.myAIContext.inAIMode = false
        self.myAIContext.userSelect = false
        //self.myAIContext.frozenFrame = false
        self.myAIContext.forceScroll = false
        self.title = ""
        self.sendText = nil
        self.scrollByUser = false
        self.weakModeScrollByUser = false
        self.inlineAIModule.hidePanel(animated: true)
        self.delegate?.quiteAI(insertContent: insertContent)
//        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) { [weak self] in
        if needClearAiBg {
            self.delegate?.clearAIBg(needSelect: needSelect)
        }
        
//        }
    }
    
    func clickOperate(type: OperationType) {
        switch type {
            case .complete:
                self.quiteAI(insertContent: true, needBlur: true)
            case .replace:
                self.delegate?.clickAiPanel(click: "replace", commandType: "")
                self.applyPreviewContent(operate: MailAIService.PreviewReplaceKey,
                                         offsetOperate: MailAIService.PreviewReplaceKey)
                self.quiteAI(insertContent: true, needClearAiBg: false)
            case .insert:
                self.delegate?.clickAiPanel(click: "insert", commandType: "")
                self.applyPreviewContent(operate: MailAIService.PreviewReplaceKey,
                                         offsetOperate: MailAIService.PreviewInsertKey)
                self.quiteAI(insertContent: true, needClearAiBg: false)
            case .insertBelow:
                self.delegate?.clickAiPanel(click: "insert_below", commandType: "")
                self.applyPreviewContent(operate: MailAIService.PreviewInsertKey,
                                     offsetOperate: MailAIService.PreviewInsertKey)
                self.quiteAI(insertContent: true, needClearAiBg: false)
            case .change:
                self.delegate?.clickAiPanel(click: "adjust", commandType: "")
                let param = genQuickActionSubPanel(arrowPannel: false)
                self.showAIPanel(params: param, subPanel: true)
            case .retry:
                self.delegate?.clickAiPanel(click: "try_again", commandType: "")
                self.retryTask()
            case .quit:
                self.showQuiteAlert(clickMask: false, needAlert: false)
            case .unknow:
                break
            @unknown default:
                break
        }
    }
    func clearPageContent() {
        self.curPage = -1
        self.pageContent = []
    }
    func updatePageContent(task: AITask) {
        self.pageContent.append(task)
        self.curPage = self.totalPage - 1
    }
    func taskSuccess(content: String) {
        self.task?.content = content
        self.task?.status = .success
        if let task = self.task {
            self.updatePageContent(task: task)
        }
        
    }
    func startTask(uniqueId: String, action: QuickAction) {
        self.task?.uniqueId = uniqueId
        self.task?.action = action
    }
    func cancelTask() {
        guard let task = self.task, task.status != .stop else { return }
        guard let id = task.taskId, !id.isEmpty else { return }
        self.task?.status = .stop
        MailDataServiceFactory.commonDataService?.stopTask(taskId: id).subscribe( onNext: { _ in
            MailLogger.info("[MailAI] cancelTask success \(id)")
        }, onError: { (error) in
            MailLogger.error("[MailAI] cancelTask error \(error)")
        }).disposed(by: disposeBag)
    }
    func retryTask() {
        guard let task = self.getCurrentTask() else {
            MailLogger.error("[MailAI] current task is empty")
            return
        }
        guard let action = task.action else {
            MailLogger.error("[MailAI] current action is nil")
            return
        }
        self.createQuickActionTask(action: action,
                                   displayContent: task.displayContent,
                                   params: task.params,
                                   actionType: task.userPrompt.isEmpty ? .quickAction : .userPrompt,
                                   needCurrentContent: true,
                                   userPrompt: task.userPrompt,
                                   subPanelContent: task.subPanelContent,
                                   isRetry: true)
    }
    
    func getCurrentContent() -> String {
        return getCurrentTask()?.content ?? ""
    }
    func getCurrentTask() -> AITask? {
        if self.curPage >= 0 && self.curPage < self.pageContent.count {
            return self.pageContent[self.curPage]
        }
        return nil
    }
    func getActionName(action: QuickAction) -> String {
        let i18nName = getI18nName(i18nKey: action.nameI18NKey)
        return i18nName.isEmpty ? action.name : i18nName
    }
    func getI18nName(i18nKey: String) -> String {
        let map = ["Mail_MyAI_BasicFeatures_Continue_Dropdown": "gqw",
                   "Mail_MyAI_BasicFeatures_Expand_Dropdown": "xfI",
                   "Mail_MyAI_BasicFeatures_Shorten_Dropdown":"trk",
                   "Mail_MyAI_BasicFeatures_Polish_Dropdown":"DVE",
                   "Mail_MyAI_EditingStyleChange_MoreConfident":"UM0",
                   "Mail_MyAI_EditingStyleChange_MoreDirect":"N1A",
                   "Mail_MyAI_EditingStyleChange_MoreFormal":"fVk",
                   "Mail_MyAI_EditingStyleChange_MoreLively":"epQ",
                   "Mail_MyAI_Templates_SalesEmail":"wsk",
                   "Mail_MyAI_Templates_ToDoList":"17w",
                   "Mail_MyAI_Templates_EventEmail":"pbg",
                   "Mail_MyAI_WriteSalesEmail_Prompt_Text":"H/s",
                   "Mail_MyAI_WriteTodoList_Prompt_Text":"jHQ",
                   "Mail_MyAI_WriteEventEmail_Prompt_Text":"1qM",
                   "Mail_MyAI_WriteWithAI_HelpWriteTopic_Text":"Xh8",
                   "Mail_MyAI_Editing_Adjust_Bttn":"5XI",
                   "Mail_MyAI_GenerateDraft_PositiveTone_Button":"xrc",
                   "Mail_MyAI_GenerateDraft_NegativeTone_Button":"9HI",
                   "Mail_MyAI_GenerateDraft_ExpressGratitude_Button":"l30",
                   "Mail_MyAI_GenerateDraft_CustomizeSubject_Button":"K3M",
                   "Mail_MyAI_GenerateDraft_DraftReply_Text":"bCM"]
        if let key = map[i18nKey] {
            let res = BundleI18n.LocalizedString(key: key, originalKey: i18nKey)
            if !res.isEmpty {
                return res
            }
        }
        return i18nKey
    }
}

extension MailAIService: LarkInlineAIUIDelegate {
   
    func getShowAIPanelViewController() -> UIViewController {
        return self.delegate?.getShowAIPanelViewController() ?? UIViewController()
    }
    
    // 横竖屏切换样式，目前iPhone不支持横屏，只有iPad会根据这个来设定，不返回默认不支持横屏
    var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? {
        return nil
    }
    
    // 输入框文本变化
    func onInputTextChange(text: String) {
        if let _ = self.getCurrentTask() {
            return
        }
        if self.onclickSend {
            return
        }
        if let task = self.task,
            (task.status == .start || task.status == .process) {
            return
        }
        self.weakModeScrollByUser = false
        textChangeShowPanel(text: text)
    }
    func textChangeShowPanel(text: String, showKeyboard: Bool = true) {
        var filterActions = self.actions
        if !text.isEmpty {
            filterActions = actions?.filter({ action in
                return self.getActionName(action: action).contains(text)
            })
        }
        self.showAIPanel(params: self.genQuickActionPanel(actions: filterActions ?? [],
                                                          highlight: true,
                                                          keyWord: text,
                                                          showKeyboard: showKeyboard))
    }
    
    //输入、点击'@'弹出picker选择框
    func onClickAtPicker(callback: @escaping (PickerItem?) -> Void) {
        //
    }
    
    // 点击sheet操作
    func onClickSheetOperation() {}
    
    // 点击键盘的发送按键
    func onClickSend(text: String) {
        guard let actions = self.actions else { return }
        self.sendText = text
        self.onclickSend = true
        self.delegate?.clickAiPanel(click: "send", commandType: "")
        // 判断是否符合模板类指令
        for action in actions where (action.groupType == .template ||
                                     action.groupType == .draftMail ||
                                     action.groupType == .draftReplyCustom) {
            let prefixText = getI18nName(i18nKey: action.prefixI18NKey)
            if (!prefixText.isEmpty &&
                text.hasPrefix(prefixText)) {
                // 构造模板类指令
                if action.groupType == .draftReplyCustom {
                    let userInput = text.substring(from: prefixText.count)
                    self.delegate?.getEditorHisoryContent(processContent: { [weak self] (info) in
                        guard let `self` = self else { return }
                        self.createQuickActionTask(action: action,
                                                   displayContent: action.name,
                                                   params: ["history_quote_content": info,
                                                            "user_completion": userInput
                                                           ],
                                                   actionType: .quickAction,
                                                   userPrompt: nil)
                    })
                } else {
                    let content = text.substring(from: prefixText.count)
                    self.createQuickActionTask(action: action,
                                               displayContent: text,
                                               params: ["content": content],
                                               actionType: .quickAction,
                                               userPrompt: nil)
                }
                return
            }
        }
        // 没有匹配模板类指令，则走自由指令
        var chatInputAction = QuickAction()
        chatInputAction.groupType = .chatInput
        chatInputAction.confirmType = .hard
        self.delegate?.getEditorContent(needSelect: false,
                                        processContent: { [weak self] info in
            guard let `self` = self else { return }
            let content = info[MailAIService.ContentKey] as? String ?? ""
            var jsonStr = ""
            if let stringData = try? JSONSerialization.data(withJSONObject: ["text": content], options: []),
               let JSONString = NSString(data: stringData, encoding: String.Encoding.utf8.rawValue) {
                jsonStr = JSONString as String
            }
            let params = ["selected_text": jsonStr]
            self.createQuickActionTask(action: chatInputAction,
                                       displayContent: "",
                                       params: params,
                                       actionType: .userPrompt,
                                       userPrompt: text)
        })
            
        
    }
    func onClickDraftMail(hasHistory: Bool) {
        
        let action = self.actions?.first(where: { action in
            if hasHistory {
                return action.groupType == .draftReplyCustom
            } else {
                return action.groupType == .draftMail
            }
        })
        if let draftMailAction = action {
            var prefixText = getI18nName(i18nKey: draftMailAction.prefixI18NKey)
            if !self.title.isEmpty && draftMailAction.groupType == .draftMail {
                prefixText = prefixText + self.title
            }
            let param = self.genTemplatePanel(prefix: prefixText)
            self.showAIPanel(params: param)
        }
    }
    
    // 点击指令
    func onClickPrompt(prompt: InlineAIPanelModel.Prompt) {
        let currentAction = self.actions?.first(where: { action in
            return String(action.id) == prompt.id
        })
        if let action = currentAction {
            self.sendText = ""
            // 内容需要editor传回来
            let prefixText = getI18nName(i18nKey: action.prefixI18NKey)
            if prefixText.isEmpty {
                if currentAction?.groupType == .draftReply {
                    self.delegate?.getEditorHisoryContent(processContent: { [weak self] (info) in
                        guard let `self` = self else { return }
                        self.createQuickActionTask(action: action,
                                                   displayContent: action.name,
                                                   params: ["history_quote_content": info],
                                                   actionType: .quickAction,
                                                   userPrompt: nil)
                    })
                } else {
                    self.delegate?.getEditorContent(needSelect: false,
                                                    processContent: { [weak self] (info) in
                        guard let `self` = self else { return }
                        var content = info[MailAIService.ContentKey] as? String ?? ""
                        self.createQuickActionTask(action: action,
                                                   displayContent: action.name,
                                                   params: ["content": content],
                                                   actionType: .quickAction,
                                                   userPrompt: nil)
                    })
                }
            } else {
                // 模板类型，需要用户补充文案
                let param = self.genTemplatePanel(prefix: prefixText)
                self.showAIPanel(params: param)
            }
        }
    }
    
    // 点击二级面板指令
    func onClickSubPrompt(prompt: InlineAIPanelModel.Prompt) {
        if prompt.rightArrow {
            let param = genQuickActionSubPanel(arrowPannel: true)
            self.showAIPanel(params: param, subPanel: true)
        } else {
            let currentAction = self.actions?.first(where: { action in
                return String(action.id) == prompt.id
            })
            if var action = currentAction {
                let content = getCurrentContent()
                if !content.isEmpty {
                    let subContent = action.secondAction == .allowContinue ? content : ""
                    self.createQuickActionTask(action: action,
                                               displayContent: action.name,
                                               params: ["content": content],
                                               actionType: .quickAction,
                                               needCurrentContent: true,
                                               userPrompt: nil,
                                               subPanelContent: subContent)
                } else {
                    MailLogger.info("[MailAI] no content")
                }
            }
        }
    }
    
    // 点击操作
    func onClickOperation(operate: InlineAIPanelModel.Operate) {
        self.clickOperate(type: OperationType(rawValue: operate.type ?? "unknow") ?? .unknow)
    }
    
    // 点击停止（AI内容生成过程中）
    func onClickStop() {
        self.delegate?.clickAiPanel(click: "stop", commandType: "")
        self.cancelTask()
        var preview = true
        if let type = self.confirmType, type == .weak {
            preview = false
        }
        if let task = self.task, task.content.isEmpty {
            //停止的时候如果还没有输出内容
            if let lastTask = self.getCurrentTask() {
                //有历史记录的
                let param = self.genContentPanel(content: lastTask.content ?? "",
                                                 isProcessing: false,
                                                 preview: preview,
                                                 keyWord: self.sendText ?? "")
                self.showAIPanel(params: param)
            } else if let text = self.sendText {
                // 没有历史记录的
                self.textChangeShowPanel(text: text, showKeyboard: !text.isEmpty)
                self.sendText = nil
            } else {
                self.textChangeShowPanel(text: "", showKeyboard: false)
                self.sendText = nil
            }
        } else {
            if let task = self.task {
                self.updatePageContent(task: task)
            }
            let param = self.genContentPanel(content: self.task?.content ?? "",
                                             isProcessing: false,
                                             preview: preview)
            self.showAIPanel(params: param)
        }
    }
    
    // 点击反馈按钮
    // true：点赞；false：点踩
    // callback: 反馈回调, 业务方保存后续调用时传入config
    func onClickFeedback(like: Bool, callback: ((LarkInlineAIFeedbackConfig) -> Void)?) {
        updateLikeStatus(like: like)
        let content = self.getCurrentTask()?.userPrompt ?? self.getCurrentTask()?.displayContent ?? ""
        let config = LarkInlineAIFeedbackConfig.init(isLike: like,
                                                     aiMessageId: self.getCurrentTask()?.uniqueId ?? "",
                                                     scenario: "EMAIL",
                                                     queryRawdata: content,
                                                     answerRawdata: self.getCurrentTask()?.content ?? "")
        if let callback = callback {
            callback(config)
        }
    }
    
    func updateLikeStatus(like: Bool) {
        guard let task = getCurrentTask() else { return }
        for (index, page) in pageContent.enumerated() where task.taskId == page.taskId {
            if let originLike = pageContent[index].like {
                if originLike == like { //说明点赞/踩又取消了
                    pageContent[index].like = nil
                } else {
                    // 切换了状态
                    pageContent[index].like = like
                }
            } else {
                pageContent[index].like = like
            }
        }
    }

    // 点击历史记录
    // true：上一页；false：下一页
    func onClickHistory(pre: Bool) {
        var nextPage = self.curPage + 1
        if pre {
            nextPage = self.curPage - 1
        }
        if nextPage < self.pageContent.count && nextPage >= 0 {
            self.curPage = nextPage
            let preview = self.confirmType == .hard
            let content = self.pageContent[nextPage].content ?? ""
            let like = self.pageContent[nextPage].like
            if preview {
                self.insertPreviewContent(content: content, needScroll: false)
            } else {
                self.delegate?.insertEditorContent(content: content,
                                                   preview: false,
                                                   toTop: true)
            }
            self.showAIPanel(params: genContentPanel(content: content,
                                                     isProcessing: false,
                                                     preview: preview,
                                                     like: like))
        }
    }
    
    // 点击遮罩区域
    func onClickMaskArea(keyboardShow: Bool) {
        self.showQuiteAlert(clickMask: true)
    }
    
    func keyboardChange(show: Bool) {
    }
    
    // 滑动达到阈值，关闭面板
    func onSwipHidePanel(keyboardShow: Bool) {
    }
    
    func onHeightChange(height: CGFloat) {
//        if self.inlineAIModule.isShowing {
//            self.myAIContext.frozenFrame = false
//        }
        self.delegate?.updateMyAIPanelHeight(height: height)
    }
    
    func panelDidDismiss() {
        if self.myAIContext.inAIMode {
            self.quiteAI(insertContent: false)
        }
    }
    // 通知业务方AI onBoarding是否设置完成的状态
    func onNeedOnBoarding(needOnBoarding: Bool) {
        
    }
      
      // Onboarding流程中途退出的回调
      // code = 0 表示用户主动退出，其他表示异常退出
    func onUserQuitOnboarding(code: Int, error: Swift.Error?) {
        self.quiteAI(insertContent: false)
    }
}
/// preview 相关操作
extension MailAIService: MailSendWebViewDelegate, UIScrollViewDelegate {
    private func startObserving() {
        if let ob = observation {
            ob.invalidate()
        }
        observation = self.webView.scrollView.observe(\.frame,
                                            options: [.new, .old],
                                            changeHandler: { [weak self] (_, change) in
            if change.newValue != nil {
                self?.scrollToBottom(frameChange: true)
            }
        })
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isTracking || scrollView.isDecelerating {
            self.scrollByUser = true
        }
    }
    private func stopObserving() {
        observation?.invalidate()
    }
    func scrollToBottom(frameChange: Bool = false) {
        guard self.scrollByUser == false else { return }
        if frameChange &&
            self.scrollContentHeight < self.webView.scrollView.bounds.size.height {
            // 文字高度不足frameHeight，无需滚动
            return
        }
        let point = CGPointMake(0, self.webView.scrollView.contentSize.height - self.webView.scrollView.bounds.size.height)
        if point.y > 0 {
            self.webView.scrollView.setContentOffset(point, animated: false)
        }
    }
    func insertPreviewContent(content: String, needScroll: Bool = true) {
        guard self.webView.renderDone else { return }
        let preview = true
        let jsStr = "window.command.insertMDContent(`\(content)`, \(preview))"
        self.webView.evaluateJavaScript(jsStr) { (_, err) in
            if let err = err {
                MailLogger.error("[MailAI] insertPreviewContent err \(err)")
            }
        }
        if needScroll {
            scrollToBottom()
        }
    }
    func applyPreviewContent(operate: String, offsetOperate: String) {
        let bottomOffset = self.myAIContext.selectionBottomOffset
        let topOffset = self.myAIContext.selectionTopOffset
        let aiHeight = self.myAIContext.viewHeight
        self.delegate?.adjuestOffset(operate: offsetOperate,
                                     bottomOffset: bottomOffset,
                                     topOffset: topOffset,
                                     aiHeight: aiHeight)
        let jsStr = "window.command.getDeltaSet()"
        self.webView.evaluateJavaScript(jsStr, completionHandler: { [weak self] (data, err) in
            guard let `self` = self else { return }
            if let data = data as? [String: Any] {
                self.delegate?.applyEditorContent(dataSet: data,
                                                  operate: operate,
                                                  bottomOffset: bottomOffset,
                                                  topOffset: topOffset,
                                                  aiHeight: aiHeight)
            }
            if let err = err {
                MailLogger.error("[MailAI] applyPreviewContent err \(err)")
            }
        })
    }
    func updateContentHeight(_ height: CGFloat) {
        self.scrollContentHeight = height
    }
    func renderDone(_ status: Bool, _ param: [String: Any]) {
        self.webView.renderDone = true
    }
    func gotoOtherPage(url: URL) {
        
    }
    func presentPage(vc: UIViewController) {
        
    }
    func cacheSetToolBar(params: [String: Any]) {
        
    }
    func webViewReady() {
        // 初始化
        let config = self.accountContext.sharedServices.editorLoader.getDomainJavaScriptString(isOOO: false,                                                                                  editable: false, bgTransparent: true)
        let renderParam = ["html": "<br/>"] as [String: Any]
        guard let data = try? JSONSerialization.data(withJSONObject: renderParam, options: []),
            let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { mailAssertionFailure("fail to serialize json")
                return
        }
        
        let script = "window.command.render(\(JSONString), \(config))"
        self.webView.evaluateJavaScript(script) { (_, error) in
            if let error = error {
                MailLogger.error("[MailAI] render error: \(error)")
            }
        }
        startObserving()
    }
}

extension MailAIService {
    func reportAIInvoke(scene: String) {
        guard !self.reportId.isEmpty else { return }
        AIReport(event: .email_draft_ai_invoke,
                 params: ["scene": scene,
                          "report_id": self.reportId])
    }
    func reportAIApply() {
        let params = AIReportParam(isCreate: false)
        guard !params.isEmpty else { return }
        AIReport(event: .email_draft_ai_content_accept,
                 params: params)
    }
    func reportAIFeedback() {
        for task in self.pageContent where task.like != nil {
            let taskId = task.taskId
            let reportId = self.reportId
            let like = task.like ?? false
            var actionName = task.action?.reportName ?? ""
            if task.action?.groupType == .chatInput {
                actionName = "chat"
            }
            if !taskId.isEmpty && !reportId.isEmpty && !actionName.isEmpty {
                AIReport(event: .email_draft_ai_task_feedback,
                         params: ["report_id": reportId,
                                  "task_id": taskId,
                                  "like": like,
                                  "action_name":actionName])
            }
        }
    }
    func reportAICreate(taskId: String, isRetry: Bool) {
        var params = AIReportParam(isCreate: true)
        guard !params.isEmpty else { return }
        params["is_retry"] = isRetry
        params["task_id"] = taskId
        AIReport(event: .email_draft_ai_task_create,
                 params: params)
    }
    func AIReportParam(isCreate: Bool) -> [String: Any] {
        var params:[String: Any] = [:]
        guard !self.reportId.isEmpty else { return params }
        var task = self.getCurrentTask()
        if isCreate {
            task = self.task
        }
        guard let task = task else { return params }
        guard let taskAction = task.action else { return params }
        var taskNum = self.pageContent.count
        if isCreate {
            taskNum = taskNum + 1
        }
        var actionName = taskAction.reportName
        if taskAction.groupType == .chatInput {
            actionName = "chat"
        }
        return ["report_id": self.reportId,
                "action_name": actionName,
                "task_num": taskNum]
    }
    // ai数据上报
    func AIReport(event: NewCoreEvent.EventName, params: [String: Any]) {
        let event = NewCoreEvent(event: event)
        event.params = params
        event.post()
    }
}
/// 相关请求
extension DataService {
    // 获取快捷指令
    func mailAIGetQuickActionRequest() -> Observable<[QuickAction]> {
        let request = QuickActionReq()
        return sendAsyncRequest(request, transform: { (response: QuickActionResp) -> [QuickAction] in
            return response.actions
        }).observeOn(MainScheduler.instance)
    }
    // 创建快捷指令 or 自由指令
    func mailAICreateTaskRequest(taskId: String,
                                 displayContent: String,
                                 sessionId: String?,
                                 actionType: PromptActionType,
                                 actionId: Int64?,
                                 params: [String: String]?,
                                 userPrompt: String?) -> Observable<CreateTaskResp> {
        var request = CreateTaskReq()
        request.uniqueTaskID = taskId
        request.actionType = actionType
        if let id = actionId {
            request.actionID = id
        }
        request.displayContent = displayContent
        if let session = sessionId {
            request.sessionID = session
        }
        if let params = params {
            request.params = params
        }
        if let prompt = userPrompt {
            request.userPrompt = prompt
        }
        return sendAsyncRequest(request, transform: { (response: CreateTaskResp) -> CreateTaskResp in
            return response
        }).observeOn(MainScheduler.instance)
    }
    // 轮询或者补偿
    func mailAIGetTaskStatusRequest(taskId: String) -> Observable<TaskStatus> {
        var request = TaskStatusReq()
        request.uniqueTaskID = taskId
        
        return sendAsyncRequest(request, transform: { (response: TaskStatusResp) -> TaskStatus in
            return response.mailAiTaskStatus
        }).observeOn(MainScheduler.instance)
    }
    func stopTask(taskId: String) -> Observable<StopTaskResp> {
        var req = StopTaskReq()
        req.uniqueTaskID = taskId
        return sendAsyncRequest(req, transform: { (response: StopTaskResp) -> StopTaskResp in
            return response
        }).observeOn(MainScheduler.instance)
    }
    func getTaskContext(hasHistory: Bool,
                        id: String,
                        names: String) -> Observable<String> {
        var req = Email_Client_V1_MailAIGetThreadContextRequest()
        if hasHistory {
            req.scene = .aiReply
        } else {
            req.scene = .aiNewDraft
        }
        if !id.isEmpty {
            req.messageID = id
        }
        if !names.isEmpty {
            req.receiver = names
        }
        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailAIGetThreadContextResponse) -> String in
            return response.context
        }).observeOn(MainScheduler.instance)
    }
}

