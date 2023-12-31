//
//  HelpdeskAssembly.swift
//  LarkHelpdesk
//
//  Created by Roy Choo on 13/1/20.
//

import Foundation
import Swinject
import EENavigator
import LarkAppLinkSDK
import LarkUIKit
import LarkNavigator
import LarkOpenChat
import LarkRustClient
import LarkMessengerInterface
import LarkFeatureGating
import LarkAssembler
import LarkContainer

public protocol HelpdeskDependency {
    func openOncall(helpdeskId: String, extra: String, from: NavigatorFrom)
}

public final class HelpdeskAssembly: LarkAssemblyInterface {
    
    public init() {}

    public func registContainer(container: Container) {

        container.register(HelpdeskDependency.self) { _ -> HelpdeskDependency in
            return HelpdeskDependencyImpl(resolver: container)
        }
    }
    public func registServerPushHandler(container: Container) {
        getServerRegistPush(container: container)
    }

    private func getServerRegistPush(container: Container) -> [ServerCommand: RustPushHandlerFactory] {
        [ServerCommand.openBannerNotifyPush: {
            return BannerNotificationPullDataHandler(pushCenter: container.pushCenter)
        }]
    }

    public func registLarkAppLink(container: Container) {
        LarkAppLinkSDK.registerHandler(path: "/client/helpdesk/open", handler: {(applink: AppLink) in
            let queryParameters = applink.url.queryParameters
            if let helpdeskId = queryParameters["id"], let from = applink.context?.from()?.fromViewController {
                DispatchQueue.main.async {
                    let extra = queryParameters["extra"] ?? ""
                    let faqId = queryParameters["faqId"]
                    let body = OncallChatBody(oncallId: helpdeskId, reportLocation: false, extra: extra, faqId: faqId)
                    Navigator.shared.showDetailOrPush(body: body,
                                                      wrap: LkNavigationController.self,
                                                      from: from)
                }
            }
        })
    }
}

final class HelpdeskDependencyImpl: HelpdeskDependency {

    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func openOncall(helpdeskId: String, extra: String, from: NavigatorFrom) {
        let body = OncallChatBody(oncallId: helpdeskId, reportLocation: false, extra: extra)
        Navigator.shared.push(body: body, from: from)
    }
}
