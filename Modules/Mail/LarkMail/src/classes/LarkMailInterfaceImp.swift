//
//  LarkMailInterfaceImp.swift
//  LarkMail
//
//  Created by tefeng liu on 2020/2/7.
//

import Foundation
import LarkMailInterface
import Swinject
import LarkAccountInterface
import LKCommonsLogging
import RunloopTools
import LarkExtensionCommon
import RxSwift
import MailSDK
import SpaceInterface
import EENavigator
import LarkFeatureGating
import LarkUIKit
import LarkContainer
import LarkSetting

struct ShareEmlError: Error {
    var message: String
}

class EMLFileProviderDecorator: EMLFileProvider {
    private let imp: LarkMailEMLProvider

    var localFileURL: URL? {
        return imp.localFileURL
    }

    init(imp: LarkMailEMLProvider) {
        self.imp = imp
    }

    func download() -> Observable<EMLFileDownloadState> {
        return imp.download().map({ state in
            switch state {
            case .downloading(progress: let progress):
                return EMLFileDownloadState.downloading(progress: progress)
            case .success(fileURL: let fileURL):
                return EMLFileDownloadState.success(fileURL: fileURL)
            case .interrupted(reason: let reason):
                return EMLFileDownloadState.interrupted(reason: reason)
            @unknown default:
                return EMLFileDownloadState.interrupted(reason: "unknown case \(state)")
            }
        })
    }

    func cancelDownload() {
        imp.cancelDownload()
    }
}

class LarkMailInterfaceImp: LarkMailInterface {
    let resolver: UserResolver
    let logger = Logger.log(LarkMailInterfaceImp.self, category: "Module.Mail")
    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func checkLarkMailTabEnable() -> Bool {
        // 非导航栏模式，不展示mail
        return false
    }
    
    func isConversationModeEnable() -> Bool {
        return MailSettingManagerInterface.getCachedCurrentAccount()?.mailSetting.enableConversationMode ?? true
    }
    

    func notifyMailNaviUpdated(isEnabled: Bool) {
        // 存储是否有 mail tab 给 share extension 使用.
        ShareExtensionConfig.share.isLarkMailEnabled = isEnabled

        if !isEnabled {
            return
        }
        
        if let mailUserContext = try? resolver.resolve(assert: MailUserContext.self) {
            mailUserContext.isLarkMailEnabled = isEnabled
        }

        if let mailService = try? resolver.resolve(assert: LarkMailService.self) {
            mailService.initMailForServerNavMode()
            mailService.mailTabLoaded(nil)
        } else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Failed to get mail service in notifyMailNaviUpdated.")
        }

        logger.debug("[mailTab] notifyMailNaviEnabled")
        (try? resolver.resolve(assert: LarkMailService.self))?.initMailForServerNavMode()
        (try? resolver.resolve(assert: LarkMailService.self))?.mailTabLoaded(nil)
    }

    func canOpenIMFile(fileName: String) -> Bool {
        guard let fg = try? resolver.resolve(assert: FeatureGatingService.self) else {
            return false
        }
        let isEmailFile = ["msg", "eml"].contains((fileName as NSString).pathExtension.lowercased())
        return isEmailFile && fg.staticFeatureGatingValue(with: "mail.readmail.ios.open_eml_from_im")
    }

    func openEMLFromIM(fileProvider: LarkMailEMLProvider, from: NavigatorFrom) {
        guard let mailService = try? self.resolver.resolve(assert: LarkMailService.self) else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Failed to get mail service.")
            return
        }
        DispatchQueue.main.async {
            mailService.mail.openEmlFromIM(provider: EMLFileProviderDecorator(imp: fileProvider), from: from)
        }
    }

    func onShareEml(action: ShareEmlAction) -> Observable<()> {
        return Observable.create { observer -> Disposable in
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = `self` else {
                    observer.onError(ShareEmlError(message: "share eml self is nil"))

                    return
                }

                // has mail tab, do some init
                guard let mailService = try? self.resolver.resolve(assert: LarkMailService.self) else {
                    MailSDKManager.assertAndReportFailure("[UserContainer] Failed to get mail service.")

                    observer.onError(ShareEmlError(message: "share eml mail init failed"))

                    return
                }

                switch action {
                case .open(let entry):
                    guard let content = ShareContent(entry.data) else {
                        observer.onError(ShareEmlError(message: "share eml decode data error"))

                        return
                    }

                    switch content.contentType {
                    case .fileUrl:
                        guard let item = ShareFileItem(content.contentData) else {
                            observer.onError(ShareEmlError(message: "share eml file decode error"))

                            return
                        }

                        DispatchQueue.main.async {
                            mailService.mail.openEml(emlPath: item.url, from: entry.from, switchToMail: true)
                        }
                    default: self.logger.debug("share eml unsupported contentType: \(content.contentType)")
                    }
                }
            }

            return Disposables.create()
        }
    }
    
    func getEMLPreviewController(_ emlPath: URL) -> UIViewController? {
        guard let mailService = try? resolver.resolve(assert: LarkMailService.self) else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Failed to get mail service.")
            return nil
        }
        return mailService.mail.makeEMLPreviewController(emlPath)
    }

    func getSearchController(query: String?, searchNavBar: SearchNaviBar?) -> UIViewController {
        guard let mailService = try? resolver.resolve(assert: LarkMailService.self) else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Failed to get mail service.")
            return UIViewController()
        }
        return mailService.mail.makeMailSearchViewController(query, searchNavBar)
    }

    func hasLarkSearchService() -> Bool {
        guard let mailService = try? resolver.resolve(assert: LarkMailService.self) else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Failed to get mail service.")
            return false
        }
        return MailSettingManagerInterface.hasLarkSearchService
    }

    func openEMLFromPath(_ path: URL, from: NavigatorFrom) {
        guard let mailService = try? resolver.resolve(assert: LarkMailService.self) else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Failed to get mail service.")
            return
        }
        mailService.mail.openEml(emlPath: path, from: from, switchToMail: false)
    }
}
