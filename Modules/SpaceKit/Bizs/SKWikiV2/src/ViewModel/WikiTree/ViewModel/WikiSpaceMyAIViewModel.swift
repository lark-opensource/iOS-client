//
//  WikiSpaceMyAIViewModel.swift
//  SKWikiV2
//
//  Created by zenghao on 2023/9/26.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import SKUIKit
import EENavigator
import LarkUIKit
import UniverseDesignColor
import SKInfra
import LarkAIInfra
import LarkContainer
import SpaceInterface
import SKResource
import UniverseDesignToast

class WikiSpaceMyAIViewModel {
    /// MyAI分会话
    
    public let bag = DisposeBag()
    
    /// 分会话界面实例引用
    private var pageService: CCMAIChatModePageService?
    
    /// AI 分会话需要使用的数据
    private var chatModeConfig: CCMAIChatModeConfig?
    
    private let spaceID: String
    private weak var hostVC: UIViewController?
    
    init(spaceID: String, hostVC: UIViewController) {
        self.spaceID = spaceID
        self.hostVC = hostVC
    }
    
    func enterMyAIChat() {
        DocsLogger.info("WikiSpaceMyAIViewModel -- start to show MyAI, objectID: \(self)")
        
        self.checkOnboardingBeforeEnterAIPage { [weak self] in
            guard let self = self else { return }

            if let config = self.chatModeConfig {
                DispatchQueue.main.async {
                    DocsLogger.info("WikiSpaceMyAIViewModel -- already has chat config")
                    self.openMyAIVC(chatModeConfig: config)
                }
            } else {
                self.fetchChatModeConfig()
            }
        }
    }
    
    deinit {
        DocsLogger.info("WikiSpaceMyAIViewModel -- deinit, \(self)")
        self.quiteAIChatIfNeeded()
    }
    
    private func fetchChatModeConfig() {
        // 这里传"WikiSpace"
        self.getAIChatModeConfig(appScene: MyAIChatModeConfig.Scenario.WIKISpace.getScenarioID()) { [weak self] chatConfig in
            guard let self = self else { return }
            
            guard let config = chatConfig else {
                DocsLogger.error("get chatConfig Failed")
                
                if let hostVC = self.hostVC {
                    DispatchQueue.main.async {
                        UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_Error_Comment_NetworkError,
                                         on: hostVC.view.window ?? hostVC.view)

                    }

                }
                
                return
            }
            DispatchQueue.main.async {
                self.openMyAIVC(chatModeConfig: config)
            }

        }

    }
    
    // 判断AI服务是否开启
    private var aiServiceEnable: Bool {
        if let service = try? Container.shared.resolve(assert: CCMAIService.self) {
            return service.enable.value
        }
        return false
    }
    
    // 判断是否已经展示过AI Onboarding
    private func checkOnboardingBeforeEnterAIPage(block: @escaping () -> ()) {
        guard let aiService = try? Container.shared.resolve(assert: CCMAIService.self),
             aiService.enable.value else {
            spaceAssertionFailure("MyAIService is nil")
            DocsLogger.error("MyAIService is nil")
            block()
           return
        }
        guard let hostVC = hostVC else { return }
        
        guard aiService.needOnboarding.value else {
           block()
           return
        }
        
        aiService.openOnboarding(from: hostVC, onSuccess: { [weak self] _ in
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
    
    private func getNeedOnboarding() -> Bool? {
        guard let aiService = try? Container.shared.resolve(assert: CCMAIService.self) else {
            spaceAssertionFailure("MyAIService is nil")
            DocsLogger.error("MyAIService is nil")
            return nil
        }
        return aiService.needOnboarding.value
    }
    
    // 打开MYAI分会话
    private func openMyAIVC(chatModeConfig: CCMAIChatModeConfig) {
        DocsLogger.info("WikiSpaceMyAIViewModel -- will show MyAI")
        
        guard let aiService = try? Container.shared.resolve(assert: CCMAIService.self) else { return }
        guard aiService.enable.value else { return }
        
        guard let hostVC = hostVC else { return }

        if pageService?.isActive == true { // 分会话在展示中
           DocsLogger.info("CCM chat_mode_page already shown")
           return
        }
        self.chatModeConfig = chatModeConfig

        aiService.openMyAIChatMode(config: chatModeConfig, from: hostVC)
        DocsLogger.info("open chat mode, config:\(chatModeConfig)")
    }
    
    private func getAIChatModeConfig(appScene: String, complete: @escaping ((CCMAIChatModeConfig?) -> Void)) {
        guard let aiService = try? Container.shared.resolve(assert: CCMAIService.self) else {
            spaceAssertionFailure("MyAIService is nil")
            DocsLogger.error("MyAIService is nil")
            complete(nil)
            return
        }
        
        let wikiSpaceURL = DocsUrlUtil.wikiSpaceURL(spaceID: spaceID)?.absoluteString
        
        aiService.getAIChatModeInfo(scene: appScene, link: wikiSpaceURL, appData: nil) { [weak self] basicInfo in
            guard let basicInfo = basicInfo else {
                complete(nil)
                return
            }
            guard let self = self else { return }
            
            let config = self.convertBasicInfoToChatConfig(basicInfo: basicInfo)
                        
            complete(config)
        }
    }
    
    private func convertBasicInfoToChatConfig(basicInfo: CCMBasicAIChatModeInfo) -> CCMAIChatModeConfig {
        let config = CCMAIChatModeConfig(chatId: basicInfo.chatID,
                                         aiChatModeId: basicInfo.chatModeID,
                                         objectId: spaceID,
                                         objectType: MyAIChatModeConfig.Scenario.WIKISpace.rawValue) // 这里传'WIKI'
        
        config.callBack = { [weak self] service in
            guard let self = self else { return }
            self.pageService = service
        }
        
        return config
    }
    
    private func quiteAIChatIfNeeded(needShowAlert: Bool = false) {
        DocsLogger.info("WikiSpaceMyAIViewModel -- quiteAIChatIfNeeded, needShowAlert: \(needShowAlert)")
        pageService?.closeMyAIChatMode(needShowAlert: needShowAlert)
        pageService = nil
    }

}

