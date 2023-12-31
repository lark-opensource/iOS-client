//
//  PanelBrowserService.swift
//  LarkOpenPlatform
//
//  Created by jiangzhongping on 2022/9/5.
//

import EEMicroAppSDK
import LarkContainer
import EcosystemWeb
import EENavigator
import LKCommonsLogging

final class PanelBrowserService: PanelBrowserServiceProtocol {
    
    private let logger = Logger.log(PanelBrowserService.self, category: "PanelBrowserService")
    
    private let resolver: Resolver
    
    init(resolver: Resolver) {
        self.resolver = resolver
    }
    
    func openAboutH5Page(appId: String) {
        let body = AppSettingBody(appId: appId, scene: .H5)
        if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController  {// user:global
            self.logger.info("about page is pushed")
            Navigator.shared.push(body: body, from: fromVC)// user:global
        } else {
            logger.error("about page can not push vc because no fromViewController")
        }
    }
}
