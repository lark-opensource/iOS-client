//
//  RegistAppLinkTask.swift
//  CCMMod
//
//  Created by majie.7 on 2023/11/20.
//

import Foundation
import BootManager
import EENavigator
import LarkUIKit
import SKCommon
import SKFoundation
import LarkAppLinkSDK
import WebAppContainer
import LarkSetting
import LarkDebugExtensionPoint
import SpaceInterface


class RegistWebAppLinkTask: UserFlowBootTask, Identifiable {
    static var identify = "RegistWebAppLinkTask"

    override class var compatibleMode: Bool { CCMUserScope.compatibleMode }

    override var scope: Set<BizScope> {
        return [.docs]
    }

    override func execute(_ context: BootContext) {
        registLarkAppLink()
        registWADependencySevice()
        setupDebugPanleItem()
    }
    
    // 小程序全局url拦截
    private func registLarkAppLink() {
        guard let webappSDK = try? userResolver.resolve(assert: WebAppSDK.self) as? WebAppSDKImpl else {
            DocsLogger.error("webappSDK is nil")
            return
        }
        let router = webappSDK.router
        // 注册小程序的纯url链接，不包含applink 和 sslocal
        Navigator.shared.registerRoute.match { url in
            return router.checkStandardWebAppUrl(url: url)
        }
        .priority(.default)
        .handle { resolver, request, response  in
            guard let config = router.getConfigWithUrl(urlString: request.url.absoluteString) else {
                DocsLogger.error("WA register task: can not get web app setting config")
                return
            }
            DocsLogger.info("WA register task: hit use web container open, converted url is: \(request.url)")
            let vc = WAContainerFactory.createPage(for: request.url, config: config, userResolver: resolver)
            response.end(resource: vc)
        }
    }
    
    private func registWADependencySevice() {
        let resolver = userResolver
        HostAppBridge.shared.register(service: OpenUserProfileService.self) { (service) -> Any? in
            let profileService = ShowUserProfileService(userId: service.userId,
                                                        fileName: service.fileName,
                                                        fromVC: service.fromVC,
                                                        params: service.params)
            HostAppBridge.shared.call(profileService)
            return nil
        }

        _ = Navigator.shared.registerRoute_(type: WAOpenChatBody.self) {
            return DocsOpenChatHandler(resolver: resolver)
        }
    }
    
    private func setupDebugPanleItem() {
        DebugRegistry.registerDebugItem(WADebugItem(), to: .debugTool)
    }
}
