//
//  IMMyAIChatModeHandler.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2023/10/30.
//

import UIKit
import Foundation
import LarkFoundation
import EENavigator
import RxSwift
import LarkCore
import RustPB
import LarkMessengerInterface
import LarkContainer
import LarkAIInfra
import LarkModel
import LarkSDKInterface
import UniverseDesignToast
import LKCommonsLogging

// 打开分会话 上下文信息
public struct OpenMyAIChatModeConfig {
    public let chatModeContext: [String: String]
    public let isFullScreenWhenPresent: Bool
    public let callBack: ((MyAIChatModeConfig.PageService) -> Void)?
    public init(chatModeContext: [String: String],
                isFullScreenWhenPresent: Bool,
                callBack: ((MyAIChatModeConfig.PageService) -> Void)?) {
        self.chatModeContext = chatModeContext
        self.isFullScreenWhenPresent = isFullScreenWhenPresent
        self.callBack = callBack
    }
}
public protocol IMMyAIChatModeOpenServiceDelegate: AnyObject {
    /// 新人进群总结：appLink处理
    func handleAIAddNewMemberSytemMessage(actionID: String, chatID: String, fromVC: UIViewController)
}
//打开分会话服务
public protocol IMMyAIChatModeOpenService: AnyObject {
    // 分会话ID
    var myAIChatModeId: String? { get set }
    // 主会场ID
    var myAIChatId: String? { get set }
    // 管理分会话生命周期
    var myAIModeConfigPageService: MyAIChatModeConfig.PageService? { get set }
    // 判断是否已经点击过电梯的总结按钮
    var alreadySummarizedMessageByMyAI: Bool { get set }
    func handleAIAddNewMemberSytemMessage(actionID: String, chatID: String, fromVC: UIViewController)
    func handleMyAIChatModeAndQuickAction(quickAction: AIQuickAction?, sceneCardClose: Bool, fromVC: UIViewController, trackParams: [String: Any])
    func imChatHistoryMessageClientInfo(startPosition: Int32?, direction: MyAIInlineServiceParamMessageDirection?) -> String
    func getMyAIChatContext(imChatHistoryMessageClient: String?,
                                   sceneCardClose: Bool?) -> [String: String]
}

final public class IMMyAIChatModeOpenServiceImpl: IMMyAIChatModeOpenService {
    private let logger = Logger.log(IMMyAIChatModeOpenServiceImpl.self, category: "LarkMessageCore.IMMyAIChatModeOpenServiceImpl")
    // 管理分会话生命周期
    public var myAIModeConfigPageService: LarkAIInfra.MyAIChatModeConfig.PageService?
    // 分会话ID
    public var myAIChatModeId: String?
    // 主会场ID
    public var myAIChatId: String?
    let chat: Chat
    weak var resolver: UserResolver?
    let disposeBag = DisposeBag()
    public var alreadySummarizedMessageByMyAI: Bool = false
    private lazy var myAIService: MyAIService? = try? resolver?.resolve(type: MyAIService.self)
    private lazy var myAiAPI: MyAIAPI? = try? resolver?.resolve(type: MyAIAPI.self)
    weak var fromViewController: UIViewController?

    struct MyAIContextParamKey {
        static let imChatChatId = "im_chat_chat_id"
        static let imChatChatName = "im_chat_chat_name"
        static let imChatHistoryMessageClient = "im_chat_history_message_client"
        static let sceneCardClose = "scene_card_close"
    }

    public init(resolver: UserResolver, chat: Chat) {
        self.resolver = resolver
        self.chat = chat
    }

    // 拼接 imChatHistoryMessageClient 信息
    public func imChatHistoryMessageClientInfo(startPosition: Int32? = nil, direction: MyAIInlineServiceParamMessageDirection? = nil) -> String {
        var jsonInfo: [String: Any] = ["chat_id": chat.id]
        if let startPosition = startPosition {
            jsonInfo["start_position"] = startPosition
        }
        if let direction = direction {
            jsonInfo["direction"] = direction.rawValue
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonInfo, options: []),
           let value = String(data: jsonData, encoding: .utf8) {
            return value
        }
        return ""
    }
    // 拼装chatContext信息
    public func getMyAIChatContext(imChatHistoryMessageClient: String? = nil,
                                   sceneCardClose: Bool? = nil) -> [String: String] {

        var res: [String: String] = [:]
        res[MyAIContextParamKey.imChatChatId] = chat.id
        res[MyAIContextParamKey.imChatChatName] = chat.name
        if let imChatHistoryMessageClient = imChatHistoryMessageClient {
            res[MyAIContextParamKey.imChatHistoryMessageClient] = imChatHistoryMessageClient
        } else {
            res[MyAIContextParamKey.imChatHistoryMessageClient] = imChatHistoryMessageClientInfo()
        }
        if let sceneCardClose = sceneCardClose {
            /// 值为false，才发送引导卡片
            res[MyAIContextParamKey.sceneCardClose] = String(sceneCardClose)
        }
        return res
    }

    // params: chatID 会话id
    // 获取有效的ModeID
    func getValidAIModeId(chatID: String, needRenew: Bool = false, completion: @escaping ((_ aiModeID: String?, _ aiChatID: String?) -> Void)) {
        if let myAIChatModeID = self.myAIChatModeId, let myAIChatID = self.myAIChatId {
            // 在主线程中调用 completion
            DispatchQueue.main.async {
                completion(myAIChatModeID, myAIChatID)
            }
            return
        }
        myAiAPI?.getChatMyAIInitInfo(scenarioChatID: Int64(chatID) ?? 0, needRenew: needRenew)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                let respAIChatModeID = String(response.aiChatModeID)
                let respAIChatID = String(response.chatID)
                if needRenew {
                    // 如果是新生成的，不需要校验是否过期
                    self?.myAIChatModeId = respAIChatModeID
                    self?.myAIChatId = respAIChatID
                    completion(respAIChatModeID, respAIChatID)
                } else {
                    self?.checkAIChatModeThreadState(aiModeID: respAIChatModeID, aiChatID: respAIChatID, completion: completion)
                }
            }, onError: { [weak self] error in
                guard let window = self?.fromViewController?.view else {
                    return
                }
                self?.logger.error("[IMMyAIChatModeOpenServiceImpl] get chatMyAI init info failed")
                UDToast.showFailureIfNeeded(on: window, error: error)
            }).disposed(by: self.disposeBag)
    }
    func checkAIChatModeThreadState(aiModeID: String, aiChatID: String, completion: @escaping ((_ aiModeID: String?, _ aiChatID: String?) -> Void)) {
        myAiAPI?.getAIChatModeThreadState(aiChatModeID: aiModeID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                guard let self = self else { return }
                if status == .open {
                    self.myAIChatModeId = aiModeID
                    self.myAIChatId = aiChatID
                    completion(aiModeID, aiChatID)
                } else {
                    // chatID如果过期，需要重新获取chatModeId
                    self.getValidAIModeId(chatID: self.chat.id, needRenew: true, completion: completion)
                }
            }, onError: { [weak self] error in
                self?.logger.error("[IMMyAIChatModeOpenServiceImpl] check chatModeID status failed, error: \(error)")
            })
        .disposed(by: disposeBag)
    }
    public func handleMyAIChatModeAndQuickAction(quickAction: AIQuickAction?,
                                                 sceneCardClose: Bool,
                                                 fromVC: UIViewController,
                                                 trackParams: [String: Any]) {
        if myAIService?.needOnboarding.value == true {
            myAIService?.openOnboarding(from: fromVC) { [weak self, weak fromVC] _ in
                guard let self = self, let fromVC = fromVC else { return }
                self.openMyAIChatModeAndExecQuickAction(quickAction: quickAction, sceneCardClose: sceneCardClose, fromVC: fromVC, trackParams: trackParams)
            } onError: { [weak self] _ in
                self?.logger.error("myai onboarding failed!")
            } onCancel: { [weak self] in
                self?.logger.error("myai onboarding been cancled!")
            }
        } else {
            openMyAIChatModeAndExecQuickAction(quickAction: quickAction, sceneCardClose: sceneCardClose, fromVC: fromVC, trackParams: trackParams)
        }
    }
    func openMyAIChatModeAndExecQuickAction(quickAction: AIQuickAction?,
                                            sceneCardClose: Bool,
                                            fromVC: UIViewController,
                                            trackParams: [String: Any]) {
        guard chat.supportMyAIInlineMode,
              myAIService?.enable.value == true else {
            return
        }
        self.fromViewController = fromVC
        // 如果分会话VC已经存在， 执行快捷指令
        if let pageService = self.myAIModeConfigPageService, pageService.isActive.value {
            if let quickAction = quickAction {
                do {
                    try pageService.sendQuickAction(quickAction, trackParmas: trackParams)
                } catch {
                    self.logger.error("[IMMyAIChatModeOpenServiceImpl]send quickaction error")
                }
            }
            if isChatModeActive() { return }
            // 如果是分会话在后台，还需要继续向下执行打开的逻辑
        }

        // 分会话不存在，执行快捷指令
        let chatModeContext = getMyAIChatContext(sceneCardClose: sceneCardClose)
        let aiConfig = OpenMyAIChatModeConfig(chatModeContext: chatModeContext,
                                              isFullScreenWhenPresent: false,
                                              callBack: { [weak self] pageService in
            self?.myAIModeConfigPageService = pageService
            if let quickAction = quickAction {
                do {
                    try pageService.sendQuickAction(quickAction, trackParmas: trackParams)
                } catch {
                    self?.logger.error("[IMMyAIChatModeOpenServiceImpl]send quickaction error")
                }
            }
        })

        openMyAIChatModeInChat(config: aiConfig, fromVC: fromVC)
    }
    // 判断分会话VC已经存在，并且在前台活跃
    private func isChatModeActive() -> Bool {
        guard let pageService = self.myAIModeConfigPageService, pageService.isActive.value else { return false }
        if #available(iOS 13, *) {
            let sceneState = pageService.getCurrentSceneState()
            if sceneState == .foregroundInactive || sceneState == .background {
                return false
            }
        }
        return true
    }
    // 跳转到分会话
    func openMyAIChatModeInChat(config: OpenMyAIChatModeConfig, fromVC: UIViewController) {
        getValidAIModeId(chatID: chat.id, completion: { [weak self, weak fromVC] (aiModeID, aiChatID) in
            guard let self = self,
                  let fromVC = fromVC,
                  let aiModeID = aiModeID,
                  let aiChatID = aiChatID else {
                self?.logger.error("get aiModeID failed")
                return
            }
            let objectType: MyAIChatModeConfig.Scenario = self.chat.type == .p2P ? .P2PChat : .GroupChat
            let myAIChatModeConfig = MyAIChatModeConfig(chatId: Int64(aiChatID) ?? 0,
                                                        aiChatModeId: Int64(aiModeID) ?? 0,
                                                        objectId: self.chat.id,
                                                        objectType: objectType,
                                                        appContextDataProvider: { config.chatModeContext },
                                                        callBack: config.callBack)
            myAIChatModeConfig.extra["app_name"] = objectType.getScenarioID().lowercased()
            myAIChatModeConfig.extra["session_id"] = aiModeID
            myAIService?.openMyAIChatMode(config: myAIChatModeConfig,
                                          from: fromVC,
                                          isFullScreenWhenPresent: config.isFullScreenWhenPresent)
            self.logger.info("[IMMyAIChatModeOpenServiceImpl] open IM chatMode success!")
        })
    }

    // 处理总结消息的APPLink
    public func handleAIAddNewMemberSytemMessage(actionID: String, chatID: String, fromVC: UIViewController) {
        // 如果没有onboarding, 需要显示调用onboarding的逻辑
        if myAIService?.needOnboarding.value == true {
            myAIService?.openOnboarding(from: fromVC) { [weak self, weak fromVC] _ in
                guard let self = self, let fromVC = fromVC else { return }
                self.fetchActionAndOpenAIChat(actionID: actionID, chatID: chatID, fromVC: fromVC)
            } onError: { [weak self] _ in
                self?.logger.error("myai onboarding failed!")
            } onCancel: { [weak self] in
                self?.logger.error("myai onboarding been cancled!")
            }
        } else {
            fetchActionAndOpenAIChat(actionID: actionID, chatID: chatID, fromVC: fromVC)
        }
    }
    func fetchActionAndOpenAIChat(actionID: String, chatID: String, fromVC: UIViewController) {
        // 校验appLink是否可以在本会话内打开, 不支持的群聊模式不打开
        guard chatID == self.chat.id, self.chat.supportMyAIInlineMode else {
            self.logger.error("chat not support jump to aichatMode, id: \(chatID)")
            return
        }
        getValidAIModeId(chatID: chat.id, completion: { [weak self] (aiModeID, aiChatID) in
            guard let self = self, let aiModeID = aiModeID, let aiChatID = aiChatID else {
                self?.logger.error("get myAIModeID failed")
                return
            }
            let fetchActionContext = self.getMyAIChatContext(sceneCardClose: true)
            self.myAiAPI?.fetchQuickActionByID(actionID: actionID,
                                               myAIChatID: aiChatID,
                                               aiChatModeID: aiModeID,
                                               chatContextInfo: fetchActionContext)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak fromVC] actionWrapper in
                guard let self = self, let fromVC = fromVC else { return }
                var quickAction = actionWrapper.quickAction
                quickAction.extraMap = fetchActionContext
                self.handleMyAIChatModeAndQuickAction(quickAction: quickAction,
                                                      sceneCardClose: true,
                                                      fromVC: fromVC,
                                                      trackParams: ["location": "chat_summary"])
            }, onError: { [weak self, weak fromVC] error in
                self?.logger.error("fetch quickaction failed, error: \(error)")
                guard let fromVC = fromVC else { return }
                UDToast.showFailureIfNeeded(on: fromVC.view, error: error)
            }).disposed(by: self.disposeBag)
        })
    }
}
