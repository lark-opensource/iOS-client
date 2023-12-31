//
//  DKMyAIServiceModule.swift
//  SKDrive
//
//  Created by zenghao on 2023/8/31.
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


// MyAI对接文档：https://bytedance.feishu.cn/wiki/VEOSwUGgnigmpykcOK1cZC8Tn3T
class DKMyAIServiceModule: DKBaseSubModule {
    /// MyAI分会话
    
    /// 分会话界面实例引用
    private var pageService: CCMAIChatModePageService?
    
    /// 权限点位
    lazy var showAIChatDriver: Observable<Bool> = {
        guard let host = hostModule else { return .never() }
        let permissionCanView: Observable<Bool>
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            permissionCanView = host.permissionService.onPermissionUpdated.map { [weak host] _ in
                guard let host else { return false }
                return host.permissionService.validate(operation: .view).allow
            }
        } else {
            permissionCanView = host.permissionRelay.map(\.isReadable)
        }
        return permissionCanView
        
    }()
    
    /// AI 分会话需要使用的数据
    private var chatModeConfig: CCMAIChatModeConfig?
    
    deinit {
        DocsLogger.driveInfo("DKMyAIServiceModule -- deinit, \(self)")
        self.quiteAIChatIfNeeded()
    }
    
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        guard let host = hostModule else { return self }
        host.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            guard let self = self else {
                return
            }
            guard case .showMyAIVC = action else {
                DocsLogger.driveInfo("DKMyAIServiceModule -- only handle show MyAI action")
                return
            }
            
            self.setupPermissionObserver()
            
            DocsLogger.driveInfo("DKMyAIServiceModule -- start to show MyAI, objectID: \(self)")
            
            self.checkOnboardingBeforeEnterAIPage { [weak self] in
                guard let self = self else { return }

                if let config = self.chatModeConfig {
                    DispatchQueue.main.async {
                        DocsLogger.driveInfo("DKMyAIServiceModule -- already has chat config")
                        self.openMyAIVC(chatModeConfig: config)
                    }
                } else {
                    self.fetchChatModeConfig()
                }
            }
        }).disposed(by: bag)
        return self
    }
    
    private func fetchChatModeConfig() {
        self.getAIChatModeConfig(appScene: MyAIChatModeConfig.Scenario.PDF.getScenarioID()) { [weak self] chatConfig in
            guard let self = self else { return }
            
            guard let config = chatConfig else {
                DocsLogger.driveError("get chatConfig Failed")
                if let hostVC = self.hostModule?.hostController {
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
        guard aiService.needOnboarding.value else {
           block()
           return
        }
        
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure("hostVC not found")
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
        DocsLogger.driveInfo("DKMyAIServiceModule -- will show MyAI")
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure("hostVC not found")
            return
        }
        
        guard let aiService = try? Container.shared.resolve(assert: CCMAIService.self) else { return }
        guard aiService.enable.value else { return }

        if pageService?.isActive == true { // 分会话在展示中
           DocsLogger.info("CCM chat_mode_page already shown")
           return
        }
        self.chatModeConfig = chatModeConfig

        aiService.openMyAIChatMode(config: chatModeConfig, from: hostVC)
        DocsLogger.info("open chat mode, config:\(chatModeConfig)")
        
        DriveStatistic.reportClickEvent(DocsTracker.EventType.navigationBarClick,
                                        clickEventType: DriveStatistic.DriveTopBarClickEventType.showMyAIChat,
                                        fileId: fileInfo.fileToken,
                                        fileType: fileInfo.fileType)
    }
    
    private func getAIChatModeConfig(appScene: String, complete: @escaping ((CCMAIChatModeConfig?) -> Void)) {
        guard let aiService = try? Container.shared.resolve(assert: CCMAIService.self) else {
            spaceAssertionFailure("MyAIService is nil")
            DocsLogger.error("MyAIService is nil")
            complete(nil)
            return
        }
        
        // TODO: - howie, 处理wiki 链接
        let shareURL = hostModule?.docsInfoRelay.value.shareUrl ?? ""
        
        aiService.getAIChatModeInfo(scene: appScene, link: shareURL, appData: nil) { [weak self] basicInfo in
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
                                         objectId: fileInfo.fileToken,
                                         objectType: MyAIChatModeConfig.Scenario.PDF.rawValue)
        
        config.callBack = { [weak self] service in
            guard let self = self else { return }
            self.pageService = service
        }
        config.delegate = self
        
        return config
    }
    
    private func getPDFPageNumber(from url: URL) -> Int? {
        guard let pageNumber = url.queryParameters[DKContextKey.pdfPageNumber.rawValue]  else {
            return nil
        }
        return Int(pageNumber)
    }
}

extension DKMyAIServiceModule: MyAIChatModeConfigDelegate {
    // 如果命中页面通信，则在该方法中执行对应的逻辑（然后通常返回false，拦截掉url自身事件）；若没有命中页面通信 则返回true响应默认事件。
    // ref: https://bytedance.feishu.cn/docx/A1gPd9WrtoaX02x8nR2cVp2ln7f
    func shouldInteractWithURL(_ url: URL) -> Bool {
        DocsLogger.driveInfo("shouldInteractWithURL: \(url)")
        
        guard URLValidator.isDocsURL(url) else {
            DocsLogger.driveInfo("not docs url")
            return true
        }
        guard let pageNumber = getPDFPageNumber(from: url) else {
            DocsLogger.driveInfo("can not get page number")
            return true
        }
        
        hostModule?.pdfAIBridge?.accept(pageNumber)
        
        // phone上面需要关闭分会话, iPad上强制采用分屏打开分会话
        if SKDisplay.phone {
            quiteAIChatIfNeeded()
        }
        return false

    }
}

extension DKMyAIServiceModule {
    
    /// 和产品确认，一期先不增加“复制”按钮
    func copyButton() -> CCMAIChatModeConfig.ActionButton {
        return CCMAIChatModeConfig.ActionButton(key: "copy", title: BundleI18n.SKResource.LarkCCM_Docs_MyAi_Copy_Menu) { [weak self] data in
            DocsLogger.driveDebug("get copyed data: \(data)")
            guard let self = self else { return }
            
            let trimedContent = self.trimContent(aiContent: data.content)
            self.copyTextAndToast(content: trimedContent)
        }
    }
    
    // TODO: - howie, 需要确认最终方案
    private func trimContent(aiContent: String) -> String {
        return aiContent
    }
    
    private func copyTextAndToast(content: String) {
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure("hostVC not found")
            DocsLogger.driveError("hostVC not found")
            return
        }
        
        let encryptId = ClipboardManager.shared.getEncryptId(token: hostModule?.hostToken)
        let refrenceToken = encryptId ?? fileInfo.fileToken
        let isSuccess = SKPasteboard.setString(content,
                                               pointId: refrenceToken,
                                               psdaToken: PSDATokens.Drive.drive_preview_aiservice_copy_content)
        if isSuccess {
            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Doc_CopySuccess, on: hostVC.view)
        } else {
            DocsLogger.error("can not copy to SKPasteboard")
        }
    }
    
    private func setupPermissionObserver() {
        showAIChatDriver.observeOn(MainScheduler.instance).subscribe { [weak self] canView in
            if !canView {
                self?.quiteAIChatIfNeeded(needShowAlert: true)
            }
        }.disposed(by: bag)
        
    }
    
    private func quiteAIChatIfNeeded(needShowAlert: Bool = false) {
        DocsLogger.driveInfo("DKMyAIServiceModule -- quiteAIChatIfNeeded, needShowAlert: \(needShowAlert)")
        pageService?.closeMyAIChatMode(needShowAlert: needShowAlert)
        pageService = nil
    }

}
