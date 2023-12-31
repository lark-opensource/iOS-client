//
//  DynamicURLAssembly.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/23.
//

import Foundation
import Swinject
import EENavigator
import LarkAssembler
import LarkAppLinkSDK
import LarkFoundation
import LarkCloudScheme

public final class DynamicURLAssembly: LarkAssemblyInterface {
    public init() { }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(URLPreviewActionBody.self)
            .factory(URLPreviewActionHandler.init(resolver:))
    }

    public func registLarkAppLink(container: Container) {
        // https://bytedance.feishu.cn/docx/TAKudjZgdoP9bOxgSVecHe7RnIc
        LarkAppLinkSDK.registerHandler(path: "/client/preview/open/schema") { appLink in
            guard let fromVC = appLink.context?.from()?.fromViewController,
                  let urlStr = appLink.url.queryParameters["url"],
                  let url = try? URL.forceCreateURL(string: urlStr) else {
                return
            }
            let userResolver = container.getCurrentUserResolver()
            // 是否应该交给云控管理逻辑处理
            if CloudSchemeManager.shared.canHandle(url: url) {
                userResolver.navigator.open(url, from: fromVC)
                return
            }
            UIApplication.shared.open(url, options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: true]) { [weak fromVC] result in
                if !result, let fromVC = fromVC {
                    userResolver.navigator.open(url, from: fromVC)
                }
            }
        }
    }
}
