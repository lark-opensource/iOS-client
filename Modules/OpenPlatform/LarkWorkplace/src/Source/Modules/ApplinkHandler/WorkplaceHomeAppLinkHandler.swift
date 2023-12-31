//
//  WorkplaceHomeAppLinkHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/4/26.
//

import Foundation
import LKCommonsLogging
import LarkNavigator
import LarkContainer
import LarkTab
import EENavigator
import LarkAppLinkSDK
import LarkSceneManager
import LarkUIKit

/// 工作台首页: /client/workplace/open
///
/// - 跳转到具体的模版工作台，eg: https://applink.feishu.cn/client/workplace/open?id=xxx
/// - 跳转到具体的网页工作台，eg: https://applink.feishu.cn/client/workplace/open?id=xxx&path=xxx&path_ios=xxx&path_android=xxx&path_pc=xxx
struct WorkplaceHomeAppLinkHandler {
    static let logger = Logger.log(WorkplaceHomeAppLinkHandler.self)

    static let pattern = "/client/workplace/open"

    static func handle(applink: AppLink) {
        logger.info("start handle workplace home applink", additionalData: [
            "url": applink.url.absoluteString
        ])
        guard let from = applink.context?.from() else { return }

        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: WorkplaceScope.userScopeCompatibleMode)
        let navigator = userResolver.navigator

        let body = WPHomeRootBody(originUrl: applink.url)
        let completion: (Bool) -> Void = { success in
            logger.info("workplace home applink handler did switch tab, success: \(success)")
            navigator.showDetailOrPush(
                body: body, wrap: LkNavigationController.self, from: from.fromViewController ?? UIViewController()
            )
        }

        // iPhone/不支持 multi scene，切换 tab 后 show VC
        if !Display.pad || !SceneManager.shared.supportsMultipleScenes {
            navigator.switchTab(
                Tab.appCenter.url,
                from: from,
                animated: false,
                completion: completion
            )
            return
        }

        // 其他情况，先切换到 main scene
        SceneManager.shared.active(scene: .mainScene(), from: from.fromViewController) { (window, _) in
            logger.info("scene manager did active main scene, hasWindow: \(window != nil)")
            guard let windowFrom = window else { return }
            navigator.switchTab(
                Tab.appCenter.url,
                from: windowFrom,
                animated: false,
                completion: completion
            )
        }
    }
}
