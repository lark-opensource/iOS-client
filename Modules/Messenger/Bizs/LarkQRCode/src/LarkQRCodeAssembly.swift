//
//  LarkQRCodeAssembly.swift
//  LarkQRCode
//
//  Created by CharlieSu on 12/12/19.
//

import Foundation
import Swinject
import EENavigator
import RxSwift
import LarkRustClient
import LarkUIKit
import AppContainer
import SuiteAppConfig
import BootManager
import LarkAppLinkSDK
import LarkAssembler
import QRCode
import LarkOpenFeed

public final class QRCodeAssembly: LarkAssemblyInterface {
    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(NewForceTouchTask.self)
    }

    public func registContainer(container: Container) {
        container.inObjectScope(.userGraph).register(QRCodeAnalysisService.self) { (r) in
            return QRCodeAnalysisManager(userResolver: r)
        }
    }

    public func registLarkAppLink(container: Container) {
        /// 注册 扫一扫 applink
        LarkAppLinkSDK.registerHandler(path: "/client/qrcode/main") { (applink) in
            guard let from = applink.context?.from() else {
                assertionFailure()
                return
            }
            LarkQRCodeNavigator.showQRCodeViewControllerIfNeeded(from: from)
        }
    }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(QRCodeControllerBody.self).factory(QRCodeControllerHandler.init)
        Navigator.shared.registerRoute.type(QRCodeDetectLinkBody.self).factory(QRCodeDetectLinkHandler.init)
    }

    public func registURLInterceptor(container: Container) {
        // 扫一扫
        (QRCodeControllerBody.pattern, { (url: URL, from: NavigatorFrom) in
            var params = NaviParams()
            params.switchTab = feedURL
            params.forcePush = true
            let context = [String: Any](naviParams: params)
            Navigator.shared.push(url, context: context, from: from) //Global
        })
    }

    public func registBootLoader(container: Container) {
        (ForceTouchApplicationDelegate.self, DelegateLevel.default)
    }

    @_silgen_name("Lark.Feed.FloatMenu.QRCode")
    static public func feedFloatMenuRegister() {
        FeedFloatMenuModule.register(QRCodeMenuSubModule.self)
    }
}
