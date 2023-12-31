//
//  AIChatModeService.swift
//  SKBrowser
//
//  Created by ByteDance on 2023/6/5.
//

import Foundation
import WebKit
import RxSwift
import RxCocoa
import SwiftyJSON
import SKCommon
import SKFoundation
import LarkWebViewContainer
import SpaceInterface
import LarkContainer
import UniverseDesignIcon
import SKUIKit
import HandyJSON
import ServerPB

/// AI分会话服务
public final class AIChatModeService: BaseJSService {
    /// 事件回调给前端
    private var callback: APICallbackProtocol?
    /// 分会话界面实例引用
    private var pageService: CCMAIChatModePageService?
    /// 缓存的上次获取到的前端上下文
    private var cachedDocContext: DocContext?
    /// 防止重复调用
    private let throttle = SKThrottle(interval: 1)
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
    
    private var aiServiceEnable: Bool {
        if let service = try? Container.shared.resolve(assert: CCMAIService.self) {
            return service.enable.value
        }
        return false
    }
    
    deinit {
        DocsLogger.info("chatmode service \(ObjectIdentifier(self)) deinit")
        if SKDisplay.pad {
            pageService?.closeMyAIChatMode()
        }
    }
}

public extension AIChatModeService {
    
    /// 文档Oops弹框点击刷新，关闭分会话
    func handleOopsRefresh() {
        // disable-lint: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.pageService?.closeMyAIChatMode()
        }
        // enable-lint: magic number
    }
    
    /// 用户权限变化时，刷新快捷指令
    func handleUserPermissionUpdate() {
        if let pageService = self.pageService {
            DocsLogger.info("update quickActions on userPermissionUpdate")
            pageService.updateQuickActions()
        } else {
            DocsLogger.info("pageService is nil")
        }
    }
}

extension AIChatModeService: DocsJSServiceHandler {
    
    public var handleServices: [DocsJSService] {
        return [.myAIMessage,
                .myAIShow,
                //.myAISelection,
                .myAIDocContext,
                .navSetCustomMenu,
                .setBlockMenuPanelItems]
    }
    
    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        switch DocsJSService(rawValue: serviceName) {
        case .myAIMessage:
            DocsLogger.info("on message: \(serviceName), params:\(params)")
            self.callback = callback
        case .myAIShow:
            let obj = AIChatModeService.ChatModeParam(dict: params)
            self.cachedDocContext = obj?.data.docContext
            DocsLogger.info("open chat mode, origin params:\(String(describing: obj))")
            throttle.schedule({ [weak self] in
                self?.checkOnboardingBeforeEnterAIPage(param: params)
            }, jobId: "chat_mode_entry_fe_call")
        case .myAIDocContext:
            let context = DocContext.parseDict(params)
            self.cachedDocContext = context
            DocsLogger.info("get myAIDocContext:\(context)")
        case .navSetCustomMenu, .setBlockMenuPanelItems:
            if pageService != nil { // 未进入过分会话, 无需监听与更新
                updateDocContextForPad(serviceName)
            }
        default:
            break
        }
        self.handle(params: params, serviceName: serviceName)
    }
    
    public func handle(params: [String: Any], serviceName: String) {}
}

extension AIChatModeService: BrowserViewLifeCycleEvent {
    
    public func browserViewControllerDidLoad() {
        let isInVC = model?.browserInfo.isInVideoConference == true
        let isDocX = model?.browserInfo.docsInfo?.inherentType == .docX
        let isVersion = model?.browserInfo.docsInfo?.isVersion ?? false
        DocsLogger.info("ai chat_mode entry enable: \(aiServiceEnable), isInVC:\(isInVC)")
        let serviceType = NavigationMenuInterceptionService.self
        guard let interception = model?.jsEngine.fetchServiceInstance(serviceType) else { return }
        if aiServiceEnable, !isInVC, !isVersion, isDocX {
            interception.registerAIChatModeMenuInfo(callback: { [weak self] in
                self?.throttle.schedule({ [weak self] in
                    self?.onClickEnterAIPage()
                }, jobId: "chat_mode_entry_click")
            })
        } else {
            interception.removeAIChatModeMenuInfo()
        }
    }
    
    public func browserTerminate() {
        pageService?.closeMyAIChatMode() // 文档reload时, 关闭现有分会话
    }
}

extension AIChatModeService {
    
    /// 点击了分会话入口
    func onClickEnterAIPage() {
        DocsLogger.info("ai chat_mode entry clicked")

        var param: [String: Any] = [:]

        var key: [String: Any] = [:]
        key["key"] = "open"
        param["key"] = key

        callback?.callbackSuccess(param: param)
    }
    
    /// 点击了按钮："insert" / "copy"
    func onClickButton(_ btnKey: String, content: String) {
        var param: [String: Any] = [:]
        
        var key: [String: Any] = [:]
        key["key"] = btnKey
        param["key"] = key
        param["content"] = content
        
        callback?.callbackSuccess(param: param)
    }
    
    /// 向前端索取上下文
    private func fetchDocContextFromWeb(_ entry: String) {
        var param: [String: Any] = [:]
        var key: [String: Any] = [:]
        key["key"] = "content_selection"
        param["key"] = key
        callback?.callbackSuccess(param: param)
        DocsLogger.info("fetch doc context, entry: \(entry)")
    }
    
    private func updateDocContextForPad(_ entry: String) {
        guard SKDisplay.pad else { return }
        throttle.schedule({ [weak self] in
            self?.fetchDocContextFromWeb(entry)
        }, jobId: "update_doccontext_for_pad")
    }
}

private extension AIChatModeService {
    
    func checkOnboardingBeforeEnterAIPage(param: [String: Any]) {
        let block: () -> () = { [weak self] in
            self?.enterAIPage(param: param)
        }
        checkOnBoardingBefore(block: block)
    }
    
    /// 进入AI分会话
    func enterAIPage(param: [String: Any]) {

        guard let aiService = try? Container.shared.resolve(assert: CCMAIService.self) else { return }
        guard aiService.enable.value else { return }

        if pageService?.isActive == true { // 分会话在展示中
            DocsLogger.info("CCM chat_mode_page already shown")
            return
        }
        
        let buttonCallback: CCMAIChatModeConfig.ButtonCallback = { [weak self] (key, content) in
            self?.onClickButton(key, content: content)
        }
        guard let config = CCMAIChatModeConfig.parse(params: param, buttonCallback: buttonCallback) else { return }
        config.callBack = { [weak self] service in
            guard let self = self else { return }
            self.pageService = service
        }
        let contextProvider: () -> [String: String] = { [weak self] in
            let context = self?.cachedDocContext
            let dict = context?.descriptionDictWithoutFullText
            let result = dict ?? [:]
            DocsLogger.info("get contextParams:\(context?.description ?? "")")
            self?.updateDocContextForPad("appContextDataProvider") // phone上因为文档被盖住时选区数据获取不到, 只在ipad上更新缓存
            return result
        }
        let triggerProvider: () -> [String: String] = { [weak self] in
            let context = self?.cachedDocContext
            let dict = context?.descriptionDictWithoutFullText
            let result = dict ?? [:]
            DocsLogger.info("get triggerParams:\(context?.description ?? "")")
            return result
        }
        let quickActionsProvider: (ServerPB_Office_ai_QuickAction) -> [String: String] = { [weak self] _ in
            let context = self?.cachedDocContext
            let dict = context?.descriptionDict
            let result = dict ?? [:]
            DocsLogger.info("get quickActionsParams:\(context?.description ?? "")")
            self?.updateDocContextForPad("quickActionsParams") // phone上因为文档被盖住时选区数据获取不到, 只在ipad上更新缓存
            return result
        }
        config.appContextDataProvider = contextProvider
        config.triggerParamsProvider = triggerProvider
        config.quickActionsParamsProvider = quickActionsProvider
        guard let topvc = self.topMostOfBrowserVC() else { return }
        aiService.openMyAIChatMode(config: config, from: topvc)
        DocsLogger.info("open chat mode, config:\(config)")
    }
}

extension CCMAIChatModeConfig {
    
    typealias ButtonCallback = (_ key: String, _ content: String) -> Void
    
    static func parse(params: [String: Any],
                      buttonCallback: @escaping ButtonCallback) -> CCMAIChatModeConfig? {
        
        guard let chatModeParam = AIChatModeService.ChatModeParam(dict: params) else { return nil }
        
        var buttons = [CCMAIChatModeConfig.ActionButton]()
        for action in chatModeParam.base.actions {
            let key = action.key
            let title = action.title
            let button = CCMAIChatModeConfig.ActionButton(key: key, title: title, callback: {
                buttonCallback(key, $0.content)
            })
            buttons.append(button)
        }
        let config = CCMAIChatModeConfig(chatId: chatModeParam.base.chatId,
                                         aiChatModeId: chatModeParam.base.aiChatModeId,
                                         objectId: chatModeParam.data.objectId,
                                         objectType: chatModeParam.data.objectType,
                                         actionButtons: buttons,
                                         greetingMessageType: .default)
        let biz_name = chatModeParam.data.objectType.lowercased() // 业务埋点参数: app_name = doc/sheet/base
        config.extra.updateValue(biz_name, forKey: "app_name")
        return config
    }
}

extension AIChatModeService {
    
    // 操作按钮
    struct ButtonParam {
        var key = ""
        var title = ""
    }
    
    // 基础信息
    struct BaseParam {
        var bizType = "" // 业务标识
        var aiChatModeId = Int64(0) // 分会话id
        var chatId = Int64(0) // 主会话id
        var actions = [ButtonParam]() // 消息上的按钮
    }
    
    // 业务信息
    struct DataParam: CustomStringConvertible {
        var url = "" // 文档url
        var welcomeMessageInfo = "" // 欢迎语
        var objectId = "" // 文档token
        var objectType = "" // AI业务场景 DOC/SHEET/BASE
        var docContext: AIChatModeService.DocContext?
        /// 用于日志打印, 去掉UGC内容
        var description: String {
            return [
                "url: \(url.encryptToShort)",
                "welcomeMessageInfo: \(welcomeMessageInfo)",
                "objectId: \(objectId.encryptToken)",
                "objectType: \(objectType)",
                "docContext: \(String(describing: docContext))"
            ].joined(separator: ",\n")
        }
    }
    
    struct ChatModeParam {
        var base = BaseParam()
        var data = DataParam()
    }
}

extension AIChatModeService {
    struct SelectionText: HandyJSON { // 选区文本
        var text = ""
    }
    struct PreviousText: HandyJSON { // 光标前文本,已废弃
        var cursorPosition = "" // title | content
        var hasValueBeforeCursor = false
        var hasValueAfterCursor = false
    }
    struct Cursor: HandyJSON { // 光标文本
        var position = "" // title | content
        var previous_text = ""
        var after_text = ""
    }
    struct DocMeta: HandyJSON {
        var has_cover = false
        var has_content = false
        var has_comment = false // 包括局部评论、全文评论
        var has_mention_me = false // 是否有 @ 我
        var title = ""
    }
    struct DocPermission: HandyJSON {
        var read = false
        var edit = false
        var copy = false
        var share = false
    }
    struct DocContext: HandyJSON, CustomStringConvertible {
        var timestamp: Double = 0
        var selected_text: SelectionText?
        var previous_text: PreviousText?
        var cursor: Cursor?
        var doc_meta: DocMeta?
        var permission: DocPermission?
        var content: String? // 用于执行快捷指令的内容（选中的文本或全文）
        static func parseDict(_ dict: [String: Any]) -> DocContext {
            if let data = DocContext.deserialize(from: dict) {
                return data
            }
            DocsLogger.info("DocContext parse failed: \(dict)")
            return DocContext()
        }
        var descriptionDict: [String: String] {
            var dict = [String: String]()
            dict["timestamp"] = "\(timestamp)"
            dict["doc_meta"] = doc_meta?.toJSONString() ?? ""
            dict["permission"] = permission?.toJSONString() ?? ""
            if let text = selected_text?.toJSONString() {
                dict["selected_text"] = text
            }
            if let text = cursor?.toJSONString() {
                dict["cursor"] = text
            }
            if let text = previous_text?.toJSONString() {
                dict["previous_text"] = text
            }
            if let text = content {
                dict["content"] = text
            }
            return dict
        }
        /// 去除content字段
        var descriptionDictWithoutFullText: [String: String] {
            var newDict = descriptionDict
            newDict.removeValue(forKey: "content")
            return newDict
        }
        /// 用于日志打印, 去掉UGC内容
        var description: String {
            var newDict = descriptionDict
            if newDict["selected_text"] != nil {
                newDict["selected_text"] = "***"
            }
            if newDict["cursor"] != nil {
                newDict["cursor"] = "***"
            }
            if newDict["content"] != nil {
                newDict["content"] = "***"
            }
            return "\(newDict)"
        }
    }
}

extension AIChatModeService.ChatModeParam {
    
    init?(dict: [String: Any]) {
        let json = JSON(dict)
        guard let aiChatModeId = Int64(json["base"]["aiChatModeId"].stringValue) else {
            DocsLogger.info("aiChatModeId invalid")
            return nil
        }
        guard let chatId = Int64(json["base"]["chatId"].stringValue) else {
            DocsLogger.info("chatId invalid")
            return nil
        }
        var base = AIChatModeService.BaseParam()
        base.bizType = json["base"]["bizType"].stringValue
        base.aiChatModeId = aiChatModeId
        base.chatId = chatId
        for action in json["base"]["actions"].arrayValue {
            let key = action["key"].stringValue
            let title = action["title"].stringValue
            base.actions.append(.init(key: key, title: title))
        }
        self.base = base
        
        var data = AIChatModeService.DataParam()
        data.url = json["data"]["url"].stringValue
        data.welcomeMessageInfo = json["data"]["welcomeMessageInfo"].stringValue
        data.docContext = AIChatModeService.DocContext.parseDict(json["data"]["docContext"].dictionaryObject ?? [:])
        data.objectId = json["data"]["objectId"].stringValue
        data.objectType = json["data"]["objectType"].stringValue
        self.data = data
    }
}

// MARK: onboarding

private extension AIChatModeService {
    
    /// 检查是否需要Onboarding
    func checkOnBoardingBefore(block: @escaping () -> ()) {
        guard let aiService = try? Container.shared.resolve(assert: CCMAIService.self),
              aiService.enable.value else {
            DocsLogger.info("aiService unavailable")
            return
        }
        guard aiService.needOnboarding.value else {
            block()
            return
        }
        guard let fromVC = self.navigator?.navigatorFromVC else {
            DocsLogger.info("cannot get navigatorFromVC")
            return
        }
        aiService.openOnboarding(from: fromVC, onSuccess: { [weak self] _ in
            DocsLogger.info("open onboarding success")
            if let newValue = self?.getNeedOnboarding(), newValue == false {
                block()
            }
        }, onError: { error in
            DocsLogger.info("open onboarding error: \(error?.localizedDescription ?? "")")
        }, onCancel: {
            DocsLogger.info("open onboarding canceled")
        })
    }
    
    func getNeedOnboarding() -> Bool? {
        guard let aiService = try? Container.shared.resolve(assert: CCMAIService.self) else {
            return nil
        }
        return aiService.needOnboarding.value
    }
}

// MARK: bridge

private extension DocsJSService {
    
    static let myAIMessage = DocsJSService("biz.myAI.message") // 监听消息
    
    static let myAIShow = DocsJSService("biz.myAI.show") // 打开分会话
    
    //static let myAISelection = DocsJSService("biz.myAI.contentselection") // 获取选区信息
    
    static let myAIDocContext = DocsJSService("biz.myAI.doccontext") // 获取文档上下文信息
}
