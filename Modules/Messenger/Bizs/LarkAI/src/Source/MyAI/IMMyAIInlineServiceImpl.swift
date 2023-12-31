//
//  IMMyAIInlineService.swift
//  LarkAI
//
//  Created by ByteDance on 2023/7/17.
//

import Foundation
import EENavigator
import LarkAIInfra
import RustPB
import LarkContainer
import LKCommonsLogging
import LarkMessengerInterface
import LarkSDKInterface
import RxSwift
import RxCocoa
import LarkMessageCore
import ServerPB
import UniverseDesignDialog
import UniverseDesignToast
import ThreadSafeDataStructure
import LarkCore
import LarkModel
import LKCommonsTracker
import LarkUIKit

public class IMMyAIInlineServiceImpl: IMMyAIInlineService, LarkInlineAISDKDelegate, UserResolverWrapper {
    struct Config {
        static let clientParamKey = "client_param"
        struct ClientParamKey {
            static let imChatChatId = "im_chat_chat_id"
            static let imChatChatName = "im_chat_chat_name"
            static let imChatHistoryMessageClient = "im_chat_history_message_client"
            static let imChatInlineOutputContent = "im_chat_inline_output_content"
        }

        static let decorateGroupKey = "im_chat_inline_group_decorate_response"

        static let pasteboardToken = "LARK-PSDA-im_myai_inline_copy_prompt_response_ios"
    }
    static let logger = Logger.log(IMMyAIInlineServiceImpl.self,
                                   category: "LarkAI.IMMyAIInlineService")
    weak private var delegate: IMMyAIInlineServiceDelegate?
    public let userResolver: UserResolver
    @ScopedInjectedLazy private var myAiAPI: MyAIAPI?
    @ScopedInjectedLazy private var myAIService: MyAIService?
    private let disposeBag = DisposeBag()

    public var alreadySummarizedMessageByMyAI: Bool = false
    public var alreadyTrackSummarizedMessageByMyAIView: Bool = false

    lazy var inlineAISDK: LarkInlineAISDK = {
        let name = myAIService?.info.value.name ?? ""
        let placeHolder: PlaceHolder = .init(BundleI18n.LarkAI.MyAI_IM_MessageName_Placeholder(name), //指令选择页面
                                             BundleI18n.LarkAI.MyAI_IM_GeneratingResponse_Placeholder, //AI生成中
                                             BundleI18n.LarkAI.MyAI_IM_MessageName_Placeholder(name)) //AI结果页(目前和「指令选择页面」是同一个placeholder)
        var config = InlineAIConfig(captureAllowed: true,
                                    scenario: self.scenarioType,
                                    placeHolder: placeHolder,
                                    maskType: Display.pad ? .aroundPanel : .default,
                                    lock: .default,
                                    quitConfirmDialogConfigProvider: self,
                                    userResolver: userResolver)
        config.update(needQuitConfirm: false)
        if self.userResolver.fg.dynamicFeatureGatingValue(with: "lark.my_ai.debug_mode") {
            config.update(debug: true)
        }
        return LarkInlineAIModuleGenerator.createAISDK(config: config,
                                                       customView: nil, delegate: self)
    }()

    private var quickActions: [InlineAIQuickAction] = [] {
        didSet {
            quickActions.forEach { quickAction in
                let prompt = transQuickActionToPrompt(quickAction, ignoreSecondaryPrompts: true)
                cachePrompt(value: .init(prompt: prompt, extraMap: quickAction.extraMap))
                handlePromptMapChildren()
            }
        }
    }
    private let scenarioType: InlineAIConfig.ScenarioType
    private var _currentContent: SafeAtomic<String> = "" + .semaphore
    private var currentContent: String {
        get {
            return _currentContent.value
        }
        set {
            _currentContent.value = newValue
        }
    }
    private var _currentSource: SafeAtomic<IMMyAIInlineSource?> = nil + .readWriteLock
    private var currentSource: IMMyAIInlineSource? {
        get {
            return _currentSource.value
        }
        set {
            _currentSource.value = newValue
        }
    }

    //key:group key; value: 该group下的prompts列表
    private var promptsMap: [String?: [PromptWithExtraMap]] = [:]
    private var groupInfos: [GroupInfo] = []
    private var promptGroups: [AIPromptGroup] {
        return groupInfos.compactMap { info in
            guard info.isVisible else { return nil }
            guard let promptWithExtraMap = promptsMap[info.key] else { return nil }
            return .init(title: info.title, prompts: promptWithExtraMap.compactMap({ return $0.prompt }))
        }
    }

    public required init(userResolver: UserResolver, delegate: IMMyAIInlineServiceDelegate, scenarioType: InlineAIConfig.ScenarioType) {
        self.userResolver = userResolver
        self.delegate = delegate
        self.scenarioType = scenarioType
        if userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.my_ai_inline") {
            // 只在fg开时拉快捷指令，减少请求量。
            // bad case:进群时没拉到fg，后来拉到了，会导致能用ai浮窗自由对话但快捷指令为空。重进群可恢复，问题不大。
            inlineAISDK.getPrompt(triggerParamsMap: [:]) { [weak self] result in
                switch result {
                case.failure(let error):
                    Self.logger.error("inlineAISDK getPrompt fail", error: error)
                case .success(let quickActions):
                    self?.quickActions = quickActions
                }
            }
        }
    }

    //source、chat仅用于埋点
    public func openMyAIInlineMode(source: IMMyAIInlineSource) {
        self.currentSource = source
        self.inlineAISDK.showPanel(promptGroups: self.promptGroups)
        self.trackInlineAiEntranceClick(source, quickAction: nil)
    }

    public func openMyAIInlineModeWith(quickAction: QuickActionProtocol, params: [String: String], source: IMMyAIInlineSource) {
        self.currentSource = source
        self.inlineAISDK.sendPrompt(prompt: transQuickActionToPrompt(quickAction, ignoreSecondaryPrompts: false, extraParams: params),
                                    promptGroups: self.promptGroups)
        self.trackInlineAiEntranceClick(source, quickAction: quickAction)
    }

    public func generateParamsForMessagesInfo(startPosition: Int32, direction: MyAIInlineServiceParamMessageDirection) -> (key: String, value: String)? {
        guard let delegate = delegate else { return nil }
        let chatId = delegate.getChat().id
        let json: [String: Any] = ["chat_id": chatId,
                                   "start_position": startPosition,
                                   "direction": direction.rawValue]
        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []),
           let value = String(data: jsonData, encoding: .utf8) {
            return (Config.ClientParamKey.imChatHistoryMessageClient, value)
        }
        return nil
    }

    private func transQuickActionToPrompt(_ quickAction: QuickActionProtocol, ignoreSecondaryPrompts: Bool = true, extraParams: [String: String] = [:]) -> AIPrompt {
        var children: [AIPrompt] = []
        if !ignoreSecondaryPrompts {
            let extraMap = quickAction.extraMap
            if let childGroupKey = getChildGroupKeyFor(extraMap: extraMap),
               let promptWithExtraMap = self.promptsMap[childGroupKey] {
                children = promptWithExtraMap.compactMap({ return $0.prompt })
            }
        }
        var templates: PromptTemplates?
        if !quickAction.paramDetailsWhichNeedConfirm.isEmpty {
            templates = .init(templatePrefix: quickAction.name,
                              templateList: quickAction.paramDetailsWhichNeedConfirm.compactMap({ paramDetail -> PromptTemplate in
                return .init(templateName: paramDetail.displayName,
                             key: paramDetail.name,
                             placeHolder: paramDetail.placeHolder)
            }))
        }
        return .init(id: quickAction.id, icon: getIconKeyOfExtraMap(extraMap: quickAction.extraMap) ?? "", text: quickAction.name,
                     type: getCommandTypeOfExtraMap(extraMap: quickAction.extraMap) ?? "",
                     templates: templates,
                     children: children,
                     callback: .init(onStart: { [weak self] in
            var param = self?.getPromptParam(quickAction: quickAction) ?? [:]
            for (key, value) in extraParams {
                //extraParams里的值覆盖getPromptParam(quickAction:_)里的值
                param[key] = value
            }
            return .init(isPreviewMode: true, param: param)
        }, onMessage: { [weak self] message in
            self?.currentContent = message
        }, onError: { error in
            Self.logger.error("quick action error, id: \(quickAction.id)", error: error)
        }, onFinish: { [weak self] state in
            guard let self = self,
                  state == 0 else { return [] }
            return self.getOperateButtons()
        }))
    }

    private func cachePrompt(value: PromptWithExtraMap) {
        guard let group = getGroupOfExtraMap(extraMap: value.extraMap) else {
            Self.logger.error("cachePrompt fail, getGroupOfExtraMap return nil, promptID: \(value.prompt.id)")
            return
        }

        var array = promptsMap[group.key] ?? []
        array.append(value)
        promptsMap[group.key] = array

        if !groupInfos.contains(where: {
            return group.key == $0.key
        }) {
            groupInfos.append(group)
        }
    }

    private func handlePromptMapChildren() {
        //当前方案下不支持children嵌套（不支持三级指令、四级指令等）。
        for array in self.promptsMap.values {
            for item in array {
                if let childGroupKey = getChildGroupKeyFor(extraMap: item.extraMap),
                   let children = self.promptsMap[childGroupKey] {
                    item.prompt.children = children.compactMap({ promptWithExtraMap -> AIPrompt in
                        return promptWithExtraMap.prompt
                    })
                }
            }
        }
    }

    private func getChildGroupKeyFor(extraMap: [String: String]) -> String? {
        let commentMap = self.getCommentOfExtraMap(extraMap: extraMap)
        return commentMap["group_entry"] as? String
    }

    private func getCommentOfExtraMap(extraMap: [String: String]) -> [String: Any] {
        guard let jsonString = extraMap["Comment"] else { return [:] }
        if let jsonData = jsonString.data(using: .utf8) {
           return (try? JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? [String: Any]) ?? [:]
        }
        return [:]
    }

    private func getGroupOfExtraMap(extraMap: [String: String]) -> GroupInfo? {
        let commentMap = getCommentOfExtraMap(extraMap: extraMap)
        guard let groupMap = commentMap["group"] as? [String: Any] else {
            //这个case表示默认的group，是正常case；后面几个gurad let是异常case
            Self.logger.info("getGroupOfExtraMap group not found. extraMap: \(extraMap)")
            return .init(key: nil, title: "", isVisible: true)
        }
        guard let key = groupMap["key"] as? String else {
            Self.logger.error("getGroupOfExtraMap fail, key not found. extraMap: \(extraMap)")
            return nil
        }
        guard let isVisible = groupMap["is_visible"] as? Bool else {
            Self.logger.error("getGroupOfExtraMap fail, is_visible not found. extraMap: \(extraMap)")
            return nil
        }
        let title = groupMap["title"] as? String ?? ""
        return GroupInfo(key: key, title: title, isVisible: isVisible)
    }

    private func getIconKeyOfExtraMap(extraMap: [String: String]) -> String? {
        let commentMap = getCommentOfExtraMap(extraMap: extraMap)
        if let icon = commentMap["icon"] as? String {
            return icon
        }
        //没配置或配置错误时展示兜底icon
        return PromptIcon.imDefault.rawValue
    }

    //用于浮窗组件埋点
    private func getCommandTypeOfExtraMap(extraMap: [String: String]) -> String? {
        let commentMap = getCommentOfExtraMap(extraMap: extraMap)
        return commentMap["command_type"] as? String
    }

    lazy var copyOperateButton: OperateButton = {
        return OperateButton(key: "copy",
                             text: BundleI18n.LarkAI.MyAI_IM_SummarizeUnread_Copy_Button,
                             isPrimary: true,
                             callback: { [weak self] _, content in
            guard let self = self else { return }
            self.myAiAPI?.transformMarkdownToRichText(markdown: content)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (res) in
                    CopyToPasteboardManager.copyToPasteboardFormRichText(richText: res, pasteboardToken: Config.pasteboardToken)
                    if let window = self?.delegate?.getDisplayVC().currentWindow() {
                        UDToast.showSuccess(with: BundleI18n.LarkAI.Lark_Legacy_JssdkCopySuccess, on: window)
                    }
                }, onError: { error in
                    Self.logger.error("copyOperateButton transformMarkdownToRichText fail", error: error)
            }).disposed(by: self.disposeBag)
            Self.logger.info("copyOperateButton tapped")
        })
    }()
    lazy var insertOperateButton: OperateButton = {
        return OperateButton(key: "insert",
                             text: BundleI18n.LarkAI.MyAI_IM_SummarizeUnread_Insert_Button,
                             callback: { [weak self] _, content in
            guard let self = self else { return }
            self.myAiAPI?.transformMarkdownToRichText(markdown: content)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (res) in
                    self?.delegate?.onInsertInMyAIInline(content: res)
                    self?.inlineAISDK.hidePanel(quitType: QuitType.click_other_command_button.rawValue)
                }, onError: { error in
                    Self.logger.error("insertOperateButton transformMarkdownToRichText fail", error: error)
            }).disposed(by: self.disposeBag)
            Self.logger.info("insertOperateButton tapped")
        })
    }()

    //调整语气Button
    var decorateOperateButton: OperateButton? {
        var promptGroups: [AIPromptGroup] = []
        if let promptWithExtraMap = self.promptsMap[Config.decorateGroupKey] {
            var title: String = ""
            for groupInfo in groupInfos {
                if groupInfo.key == Config.decorateGroupKey {
                    title = groupInfo.title
                    break
                }
            }
            promptGroups.append(.init(title: title, prompts: promptWithExtraMap.compactMap({ return $0.prompt })))
        }
        if promptGroups.isEmpty {
            //产品体验后决定下掉这个button，但研发讨论后决定先在代码上保留，通过修改快捷指令平台配置（promptGroups为空）来隐藏这个button的展示。 7.1版本 @贾潇
            return nil
        } else {
            let button = OperateButton(key: "decorate",
                                       text: BundleI18n.LarkAI.MyAI_IM_ChangeTone_Button,
                                       promptGroups: promptGroups,
                                       callback: { _, _ in
                Self.logger.info("decorateOperateButton tapped")
            })
            return button
        }
    }

    lazy var retryOperateButton: OperateButton = {
        return OperateButton(key: "retry",
                             text: BundleI18n.LarkAI.MyAI_IM_SummarizeUnread_Retry_Button,
                             callback: { [weak self] _, _ in
            self?.inlineAISDK.retryCurrentPrompt()
            Self.logger.info("retryOperateButton tapped")
        })
    }()

    lazy var quitOperateButton: OperateButton = {
        return OperateButton(key: "quit",
                             text: BundleI18n.LarkAI.MyAI_IM_SummarizeUnread_Quit_Button,
                             callback: { [weak self] _, _ in
            self?.inlineAISDK.hidePanel(quitType: QuitType.click_button_on_result_page.rawValue)
            Self.logger.info("quitOperateButton tapped")
        })
    }()

    func getOperateButtons() -> [OperateButton] {
        return [self.copyOperateButton, self.insertOperateButton, self.decorateOperateButton, self.retryOperateButton, self.quitOperateButton].compactMap { $0 }
    }

    // MARK: - LarkInlineAISDKDelegate
    public func getShowAIPanelViewController() -> UIViewController {
        guard let vc = delegate?.getDisplayVC() else {
            assertionFailure("no delegate")
            return UIViewController()
        }
        return vc
    }

    public var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask?

    public func onHistoryChange(text: String) {
        self.currentContent = text
    }

    public func onHeightChange(height: CGFloat) {
    }

    //浮窗组件的埋点公参接口
    public func getBizReportCommonParams() -> [AnyHashable: Any] {
        var params: [AnyHashable: Any] = [:]
        if let source = self.currentSource {
            params["from_entrance"] = source.rawValue
        }
        params["product_type"] = self.getSceneValueForTrack()
        if let chat = self.delegate?.getChat() {
            params += IMTracker.Param.chat(chat)
        }
        return params
    }

    public func getUserPrompt() -> LarkAIInfra.AIPrompt {
        return .init(id: nil, icon: "", text: "",
                     type: "user_prompt",//仅用于埋点
                     callback: .init(onStart: { [weak self] in
            var params: [String: String] = [:]
            if let self = self {
                params[Config.ClientParamKey.imChatHistoryMessageClient] = self.getImChatHistoryMessageClient()
            }
            return .init(isPreviewMode: true, param: params)
        }, onMessage: { [weak self] message in
            self?.currentContent = message
        }, onError: { error in
            Self.logger.error("user prompt error", error: error)
        }, onFinish: { [weak self] state in
            guard let self = self,
                  state == 0 else { return [] }
            return self.getOperateButtons()
        }))
    }
}

// MARK: - PromptParam
extension IMMyAIInlineServiceImpl {
    private func getPromptParam(quickAction: QuickActionProtocol) -> [String: String] {
        var res: [String: String] = [:]
        var paramsKeys: [String] = quickAction.params

        let commentMap = getCommentOfExtraMap(extraMap: quickAction.extraMap)
        if let clientParam = commentMap[Config.clientParamKey] as? [String] {
            paramsKeys.append(contentsOf: clientParam)
        }

        for item in paramsKeys {
            switch item {
            case Config.ClientParamKey.imChatChatId:
                res[item] = getImChatChatId()
            case Config.ClientParamKey.imChatChatName:
                res[item] = getImChatChatName()
            case Config.ClientParamKey.imChatHistoryMessageClient:
                res[item] = getImChatHistoryMessageClient()
            case Config.ClientParamKey.imChatInlineOutputContent:
                res[item] = getImChatInlineOutputContent()
            default:
                Self.logger.error("getPromptParam unknown param key: \(item)")
            }
        }

        return res
    }

    private func getImChatChatId() -> String {
        return delegate?.getChat().id ?? ""
    }

    private func getImChatChatName() -> String {
        return delegate?.getChat().name ?? ""
    }

    private func getImChatHistoryMessageClient() -> String {
        guard let delegate = delegate else { return "" }
        let chatId = delegate.getChat().id
        let (startPosition, direction) = delegate.getUnreadMessagesInfo()
        let json: [String: Any] = ["chat_id": chatId,
                                   "start_position": startPosition,
                                   "direction": direction.rawValue]
        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) {
            return String(data: jsonData, encoding: .utf8) ?? ""
        }
        return ""
    }

    private func getImChatInlineOutputContent() -> String {
        return self.currentContent
    }
}

extension IMMyAIInlineServiceImpl: QuitConfirmDialogConfigProvider {
    public func provideDialogConfig() -> InlineAIConfig.DialogConfig {
        return .init(title: BundleI18n.LarkAI.MyAI_IM_QuitWithoutSave_Title,
                     content: BundleI18n.LarkAI.MyAI_IM_QuitWithoutSave_Desc(self.myAIService?.info.value.name ?? ""),
                     cancelButton: BundleI18n.LarkAI.MyAI_IM_QuitWithoutSave_Stay_Button,
                     confirmButton: BundleI18n.LarkAI.MyAI_IM_SummarizeUnread_Quit_Button)
    }
}

//track
extension IMMyAIInlineServiceImpl {
    public func trackInlineAIEntranceView(_ source: IMMyAIInlineSource) {
        var params: [AnyHashable: Any] = ["from_entrance": source.rawValue, "product_type": getSceneValueForTrack()]
        if let chat = self.delegate?.getChat() {
            params += IMTracker.Param.chat(chat)
        }
        Tracker.post(TeaEvent("public_inline_ai_entrance_view", params: params))
    }

    private func trackInlineAiEntranceClick(_ source: IMMyAIInlineSource, quickAction: QuickActionProtocol?) {
        var params: [AnyHashable: Any] = ["from_entrance": source.rawValue, "product_type": getSceneValueForTrack()]
        switch source {
        case .mention:
            params["click"] = "open_inline_ai"
        case .scroll_to_unread:
            params["click"] = "quick_action"
            params["action_type"] = "im.chat.inline.summarize_user"
            params["action_id"] = quickAction?.id ?? ""
        @unknown default:
            break
        }
        if let chat = self.delegate?.getChat() {
            params += IMTracker.Param.chat(chat)
        }
        Tracker.post(TeaEvent("public_inline_ai_entrance_click", params: params))
    }

    private func getSceneValueForTrack() -> String {
        switch self.scenarioType {
        case .groupChat:
            return "GroupChat"
        case .p2pChat:
            return "P2pChat"
        default:
            assertionFailure("unexcepted scenarioType")
            return "unknown"
        }
    }
}

private struct GroupInfo {
    let key: String?
    var title: String
    var isVisible: Bool
}

private class PromptWithExtraMap {
    let prompt: AIPrompt
    let extraMap: [String: String]
    init(prompt: AIPrompt,
         extraMap: [String: String]) {
        self.prompt = prompt
        self.extraMap = extraMap
    }
}

private enum QuitType: String {
    case click_other_command_button
    case click_button_on_result_page
}
