//
//  NativeAppOpenLinkHandler.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/1/10.
//

import Foundation
import LarkAppLinkSDK
import Swinject
import NativeAppPublicKit
import LarkNavigator
import EENavigator
import OPFoundation
import LKCommonsLogging
import UniverseDesignDialog
import LarkLocalizations
import LarkContainer

class NativeAppOpenLinkHandler {
    
    private static let logger = Logger.log(NativeAppOpenLinkHandler.self, category: "NativeAppOpenLinkHandler")
    
    func handle(applink: AppLink, resolver: UserResolver) {
        let queryParameters = applink.url.queryParameters
        guard let appId = queryParameters["appId"] else {
            Self.logger.error("NativeAppOpenLinkHandler: appId is nil")
            return
        }
        Self.logger.info("NativeAppOpenLinkHandler: native app open")
        guard let managerImpl = try? resolver.resolve(assert: NativeAppManagerInternalProtocol.self) else {
            Self.logger.error("NativeAppOpenLinkHandler: NativeAppManagerInternalProtocol impl is nil")
            return
        }
            
        guard let guideInfo = managerImpl.nativeAppGuideInfoDic[appId], guideInfo.code == .Pass else {
            Self.logger.info("NativeAppOpenLinkHandler: code is not pass")
            let language = BundleI18n.currentLanguage.identifier.lowercased()
            if let guideInfo = managerImpl.nativeAppGuideInfoDic[appId], let content = guideInfo.tip["content"], var localText = content[language] ?? content["en_us"] {
                let dialog = UDDialog()
                localText = localText.replacingOccurrences(of: "{APP_DISPLAY_NAME}", with: LanguageManager.bundleDisplayName)
                dialog.setContent(text: localText)
                dialog.addPrimaryButton(text: BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_IKnow)
                if let fromVC = Navigator.shared.mainSceneTopMost {
                    fromVC.present(dialog, animated: true)
                    Self.logger.info("NativeAppOpenLinkHandler: dialog show")
                } else {
                    Self.logger.error("NativeAppOpenLinkHandler: presentAlertWith can not present vc because no fromViewController")
                }
            } else {
                Self.logger.error("NativeAppOpenLinkHandler: localText is empty")
            }
            Self.logger.error("NativeAppOpenLinkHandler: app has not access, appId:\(appId), guideInfo:\(String(describing: managerImpl.nativeAppGuideInfoDic[appId]))")
            return
        }
        Self.logger.info("NativeAppOpenLinkHandler: code is pass")
        let implDic = NativeAppConnectManager.shared.getDIItems(protocolType: .OpenNativeAppProtocol)
        if let implDic = implDic as? [String: NativeAppExtensionProtocol], let impl = implDic[appId] as? OpenNativeAppProtocol {
            Self.logger.info("NativeAppOpenLinkHandler: impl as OpenNativeAppProtocol")
            let vc = impl.setupVC(url: applink.url.absoluteString)
            if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
                resolver.navigator.push(vc, from: fromVC)
            } else {
                Self.logger.error("NativeAppOpenLinkHandler: fromVC is nil")
            }
        } else {
            Self.logger.error("NativeAppOpenLinkHandler: implDic:\(String(describing: implDic))")
        }
    }
}
