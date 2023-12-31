//
//  CCMAIServiceImpl.swift
//  CCMMod
//
//  Created by ByteDance on 2023/6/6.
//

import Foundation
import EENavigator
import RxSwift
import RxCocoa
import LarkUIKit
import LarkContainer
import SpaceInterface
import LarkAIInfra
import SKFoundation
import SKCommon
import SKInfra
#if MessengerMod
import LarkMessengerInterface
#endif

class CCMAIServiceImpl: CCMAIService {
    private let disposeBag = DisposeBag()
    
    let resolver: Resolver
    
    init(resolver: Resolver) {
        self.resolver = resolver
    }
    
    #if MessengerMod
    private var aiService: MyAIService? {
        return try? resolver.resolve(assert: MyAIService.self)
    }
    #endif
    
    var enable: BehaviorRelay<Bool> {
        #if MessengerMod
        return aiService?.enable ?? .init(value: false)
        #else
        return .init(value: false)
        #endif
    }
    
    var needOnboarding: BehaviorRelay<Bool> {
        #if MessengerMod
        return aiService?.needOnboarding ?? .init(value: false)
        #else
        return .init(value: false)
        #endif
    }

    func openMyAIChatMode(config: CCMAIChatModeConfig, from: UIViewController) {
        #if MessengerMod
        let larkConfig = config.toLarkAIModel()
        aiService?.openMyAIChatMode(config: larkConfig, from: from)
        #endif
    }
    
    func openOnboarding(from: NavigatorFrom,
                        onSuccess: ((_ chatID: Int64) -> Void)?,
                        onError: ((_ error: Error?) -> Void)?,
                        onCancel: (() -> Void)?) {
        #if MessengerMod
        aiService?.openOnboarding(from: from,
                                  onSuccess: onSuccess,
                                  onError: onError,
                                  onCancel: onCancel)
        #endif
    }
    
    func getAIChatModeInfo(scene: String, link: String?, appData: String?, complete: @escaping (_ basicChatInfo: CCMBasicAIChatModeInfo?) -> Void) {
        #if MessengerMod
        
        aiService?.getAIChatModeId(appScene: scene, link: link, appData: appData)
            .subscribe(onNext: { response in
                if let chatID = Int64(response.chatID), let aiChatModeId = Int64(response.aiChatModeID) {
                    let basicInfo = CCMBasicAIChatModeInfo(chatID: chatID,
                                                           chatModeID: aiChatModeId)

                   complete(basicInfo)
                } else {
                    complete(nil)
                }
            }, onError: { error in
                DocsLogger.error("get chat mode id failed with error: \(error)")
                complete(nil)
            }).disposed(by: self.disposeBag)
        #else
            complete(nil)
        #endif
    }
}

#if MessengerMod
extension CCMAIChatModeConfig {
    
    func toLarkAIModel() -> MyAIChatModeConfig {
        let toolIds: [String]
        if let ids = SettingConfig.myAIChatModeConfig?.toolIds {
            toolIds = ids
        } else {
            toolIds = []
        }
        self.toolIds = toolIds
        DocsLogger.info(" toolIds:\(toolIds)")
        
        let ccmCallback = self.callBack
        let model = MyAIChatModeConfig(chatId: self.chatId,
                                       aiChatModeId: self.aiChatModeId,
                                       objectId: self.objectId,
                                       objectType: MyAIChatModeConfig.Scenario(rawValue: self.objectType) ?? .DOC,
                                       actionButtons: self.actionButtons.map({ $0.toLarkAIModel() }),
                                       greetingMessageType: self.greetingMessageType.toLarkAIModel(),
                                       appContextDataProvider: self.appContextDataProvider,
                                       callBack: { service in
            let obj = CCMAIChatModePageServiceImpl(service: service)
            ccmCallback?(obj)
        },
                                       toolIds: self.toolIds)
        model.extra = self.extra
        model.appContextDataProvider = self.appContextDataProvider
        model.triggerParamsProvider = self.triggerParamsProvider
        model.quickActionsParamsProvider = self.quickActionsParamsProvider
        model.delegate = self.delegate
        
        return model
    }
}

private class CCMAIChatModePageServiceImpl: CCMAIChatModePageService {

    let internalService: MyAIChatModeConfig.PageService

    private let disposeBag = DisposeBag()
    
    init(service: MyAIChatModeConfig.PageService) {
        self.internalService = service
    }

    var isActive: Bool {
        if self.ignoreActive() {
            return false
        } else {
            return internalService.isActive.value
        }
    }

    func closeMyAIChatMode(needShowAlert: Bool) { internalService.closeMyAIChatMode(needShowAlert: needShowAlert) }
    
    func updateQuickActions() { internalService.refreshQuickActions() }
    
    // 不拦截isActive
    private func ignoreActive() -> Bool {
        if #available(iOS 13, *) {
            let sceneState = internalService.getCurrentSceneState()
            if sceneState == .foregroundInactive || sceneState == .background {
                return true
            }
        }
        return false
    }
}

extension CCMAIChatModeConfig.ActionButton {
    
    func toLarkAIModel() -> MyAIChatModeConfig.ActionButton {
        let ccmCallback = self.callback
        let model = MyAIChatModeConfig.ActionButton(key: self.key,
                                                    title: self.title,
                                                    callback: { larkData in
            let ccmData = larkData.toCCMAIModel()
            ccmCallback(ccmData)
        })
        return model
    }
}

extension MyAIChatModeConfig.ActionButtonData {
    
    func toCCMAIModel() -> CCMAIChatModeConfig.ActionButtonData {
        let model = CCMAIChatModeConfig.ActionButtonData(type: self.type.toCCMAIModel(),
                                                         content: self.content)
        return model
    }
}

extension MyAIChatModeConfig.ActionButtonDataType {
    
    func toCCMAIModel() -> CCMAIChatModeConfig.ActionButtonDataType {
        switch self {
        case .raw:
            return .raw
        case .markdown:
            return .markdown
        case .jsonString:
            return .jsonString
        @unknown default:
            return .raw
        }
    }
}

extension CCMAIChatModeConfig.GreetingMessageType {
    
    func toLarkAIModel() -> MyAIChatModeConfig.GreetingMessageType {
        switch self {
        case .`default`:
            return .`default`
        case .plainText(let value):
            return .plainText(value)
        case .iconText(let value1, let value2):
            return .iconText(value1, text: value2)
        case .url(let value):
            return .url(value)
        @unknown default:
            return .`default`
        }
    }
}
#endif
