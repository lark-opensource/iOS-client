//
//  LarkMicroAppAssembly.swift
//  Lark
//
//  Created by Meng on 2021/1/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkMicroApp
import LarkOPInterface
import LarkModel
import EENavigator
import Swinject
#if CCMMod
import CCMMod
import SpaceInterface
#endif
import LarkAssembler
import ECOInfra
import LarkContainer

final public class LarkMicroAppAssembly: LarkAssemblyInterface {

    public init() { }

    public func registContainer(container: Container) {
        let userContainer = container.inObjectScope(OPUserScope.userScope)
        userContainer.register(MicroAppDependency.self) { userResolver -> MicroAppDependency in
            return MicroAppDependencyImpl.init(resolver: userResolver)
        }
    }
}

final class MicroAppDependencyImpl: MicroAppDependency, UserResolverWrapper {
    
    var userResolver: UserResolver
    init(resolver: UserResolver) {
        self.userResolver = resolver
    }
    
    public func shareAppPageCard(
        appId: String,
        title: String,
        iconToken: String?,
        url: String,
        appLinkHref: String?,
        options: ShareOptions,
        fromViewController: UIViewController,
        callback: @escaping (([String: Any]?, Bool) -> Void)
    ) {
        let shareAppPage = ShareAppPage(
            appId: appId,
            title: title,
            iconKey: iconToken,
            url: url,
            applinkHref: appLinkHref,
            options: options
        )
        let eventHandler = ShareEventHandler(shareCompletion: { callback($0, $1) })
        let body = OPShareBody(
            shareType: .appPage(shareAppPage),
            fromType: .gadgetPageShare,
            eventHandler: eventHandler
        )
        self.navigator.open(body: body, from: fromViewController)
    }

    public func presendSendDocBody(maxSelect: Int,
                            title: String?,
                            confirmText: String?,
                            sendDocBlock: @escaping MicroAppSendDocBlock,
                            wrap: UINavigationController.Type?,
                            from: NavigatorFrom,
                            prepare: ((UIViewController) -> Void)?,
                            animated: Bool) {
        
        
#if CCMMod
        let body = SendDocBody(SendDocBody.Context(maxSelect: maxSelect,
                                        title: title,
                                        confirmText: confirmText)) { (config: SendDocConfirm, models: [SendDocModel]) in
            sendDocBlock(config, models as [MicroAppSendDocModel])
        }
        self.navigator.present(body: body,
                               context: [:],
                               wrap: wrap,
                               from: from,
                               prepare: prepare,
                               animated: animated,
                               completion: nil)
#endif
    }
    
    func openAppLinkWithWebApp(url: URL, from: NavigatorFrom?) -> URL? {
        guard let webAppSDK = try? userResolver.resolve(assert: WebAppSDK.self) else {
            return nil
        }
        guard let url = webAppSDK.convert(url: url.absoluteString) else {
            return nil
        }
        if let from {
            self.userResolver.navigator.push(url, from: from)
        }
        return url
    }
}

#if CCMMod
extension SendDocModel: MicroAppSendDocModel {}
#endif
