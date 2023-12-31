//
//  MyAIServiceImpl+ChatMode.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/13.
//

import Foundation
import LarkAIInfra
import LarkUIKit
import LarkSceneManager
import LarkMessengerInterface
import RxSwift
import EENavigator
import ServerPB
import RustPB
import LarkContainer

/// 把MyAIChatModeService相关逻辑放这里
public extension MyAIServiceImpl {
    /// 用于主导航，跳转到MyAI的分会场；内部会根据是否Onboarding先进入Onboarding流程
    func openMyAIChatMode(config: MyAIChatModeConfig, from: UIViewController, isFullScreenWhenPresent: Bool) {
        // aiChatModeId必须有值
        if config.aiChatModeId <= 0 { assertionFailure() }
        // 已经有正在执行的打开分会场请求了，则做防连点处理，直接return
        if requestingChatModeSet.contains(config.aiChatModeId) {
            MyAIServiceImpl.logger.info("my ai openMyAIChatMode request is allready exist, aiChatModeId: \(config.aiChatModeId)")
            return
        }
        MyAIServiceImpl.logger.info("my ai openMyAIChatMode request start, aiChatModeId: \(config.aiChatModeId)")
        requestingChatModeSet.insert(config.aiChatModeId)
        // 获取业务方传入的chatId
        if self.myAIChatId <= 0 { self.myAIChatId = config.chatId ?? 0 }

        self.checkOnboardingAndThen(from: from) { [weak self] in
            guard let `self` = self else { return }
            self.checkChatterIdAndThen { [weak self] in
                guard let `self` = self else { return }
                self.checkChatIdAndThen { [weak self] in
                    guard let `self` = self else { return }
                    // MyAIChatModeConfig重新赋值chatId，群内会使用到
                    config.chatId = self.myAIChatId
                    let presentChatModeBlock = { [weak self, weak from] in
                        guard let self = self,
                              let from = from else { return }
                        let body = self.getMyAIChatModeBody(config: config)
                        DispatchQueue.main.async {
                            self.userResolver.navigator.present(body: body,
                                                     wrap: LkNavigationController.self,
                                                     from: from,
                                                     prepare: {
                                $0.modalPresentationStyle = isFullScreenWhenPresent ? .fullScreen : .formSheet
                            },
                                                     completion: { [weak self] _, _ in
                                MyAIServiceImpl.logger.info("my ai openMyAIChatMode request complete by present, aiChatModeId: \(config.aiChatModeId)")
                                self?.requestingChatModeSet.remove(config.aiChatModeId)
                            })
                        }
                    }
                    if #available(iOS 13, *),
                       Display.pad {
                        var userInfo: [String: String] = [:]
                        userInfo["chatID"] = self.myAIChatId.description
                        let scene = LarkSceneManager.Scene(
                            key: "MyAIChatMode",
                            id: config.aiChatModeId.description,
                            title: self.info.value.name,
                            userInfo: userInfo,
                            sceneSourceID: from.currentSceneID(),
                            windowType: "channel",
                            createWay: "window_click"
                        )
                        SceneManager.shared.active(scene: scene, from: from, localContext: config) { [weak self] (_, error) in
                            if error != nil {
                                presentChatModeBlock() //分屏报错了的话，走present兜底
                            } else {
                                MyAIServiceImpl.logger.info("my ai openMyAIChatMode request complete by newScene, aiChatModeId: \(config.aiChatModeId)")
                                self?.requestingChatModeSet.remove(config.aiChatModeId)
                            }
                        }
                    } else {
                        presentChatModeBlock()
                    }
                }
            }
        }
    }

    func getMyAIChatModeBody(config: MyAIChatModeConfig) -> Body {
        let body = ChatControllerByBasicInfoBody(
            chatId: self.myAIChatId.description,
            positionStrategy: .toLatestPositon, // 分会场永远都是加载最新的消息
            fromWhere: .myAIChatMode, // im_chat_main_view埋点需要
            showNormalBack: true, // 分会场不显示导航栏左侧未读数
            isCrypto: false,
            isMyAI: true,
            myAIChatModeConfig: config,
            chatMode: .default
        )
        return body
    }

    /// 用于Feed Mock MyAI，大搜出Mock MyAI群，跳转到MyAI的主会场，内部会先进行Onboarding再进入主会场；此时一定没有进行过Onboarding
    func openMyAIChat(from: UIViewController) {
        self.checkOnboardingAndThen(from: from) { [weak self] in
            guard let `self` = self else { return }
            self.checkChatterIdAndThen { [weak self] in
                guard let `self` = self else { return }
                self.checkChatIdAndThen { [weak self] in
                    guard let `self` = self else { return }
                    let body = ChatControllerByBasicInfoBody(
                        chatId: self.myAIChatId.description,
                        showNormalBack: false,
                        isCrypto: false,
                        isMyAI: true,
                        chatMode: .default
                    )
                    DispatchQueue.main.async { self.userResolver.navigator.showDetailOrPush(body: body, from: from) }
                }
            }
        }
    }

    func getAIChatModeId(appScene: String?, link: String?, appData: String?) -> Observable<ServerPB.ServerPB_Office_ai_AIChatModeInitResponse> {
        guard let myAiAPI = self.myAiAPI else { return .just(ServerPB.ServerPB_Office_ai_AIChatModeInitResponse()) }

        return myAiAPI.getAIChatModeId(appScene: appScene, link: link, appData: appData)
    }

    func closeChatMode(aiChatModeID: String) -> Observable<ServerPB.ServerPB_Office_ai_AIChatModeThreadCloseResponse> {
        guard let myAiAPI = self.myAiAPI else { return .just(ServerPB.ServerPB_Office_ai_AIChatModeThreadCloseResponse()) }

        return myAiAPI.closeChatMode(aiChatModeID: aiChatModeID)
    }

    //TODO: 贾潇 因接口实现变更，chatID不需要传了，aiChatModeID最好也改成String类型
    func getChatModeState(aiChatModeID: Int64, chatID: Int64?) -> Observable<Basic_V1_ThreadState> {
        guard let myAiAPI = self.myAiAPI else { return .error(UserScopeError.disposed) }
        return myAiAPI.getAIChatModeThreadState(aiChatModeID: aiChatModeID.description)
            .compactMap({ state -> Basic_V1_ThreadState in
                switch state {
                case .open:
                    return .open
                case .closed:
                    return .closed
                case .unknownState:
                    return .unknownState
                @unknown default:
                    return .unknownState
                }
            })
    }
}
