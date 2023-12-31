//
//  BlockPreviewAppLinkHandler.swift
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
import RoundedHUD

/// Block 真机预览: /client/block/open
///  https://applink.feishu.cn/client/block/open?block_type_id=blk_xxx&app_id=cli_xxx&version=preview&token=xxx
struct BlockPreviewAppLinkHandler {
    static let logger = Logger.log(BlockPreviewAppLinkHandler.self)

    static let pattern = "/client/block/open"

    static func handle(applink: AppLink) {
        let from = applink.context?.from()
        logger.info("start handle block preview applink", additionalData: [
            "url": applink.url.absoluteString,
            "hasFrom": "\(from != nil)"
        ])
        guard let from = from else { return }

        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: WorkplaceScope.userScopeCompatibleMode)
        let navigator = userResolver.navigator

        let url = applink.url
        let body = BlockPreviewBody(url: url)

        logger.info("will show block preview vc", additionalData: [
            "previewType": "\(url.queryParameters["preview_type"] ?? "")",
        ])

        if let previewType = url.queryParameters["preview_type"],
           previewType == "device_preview" {    // 真机调试
#if IS_LYNX_DEVTOOL_OPEN
            navigator.push(body: body, from: from)
#else
            if let view = from.fromViewController?.view {
                let text = BundleI18n.LarkWorkplace.OpenPlatform_MobBlcDebug_WrongPkgPrompt()
                RoundedHUD.showFailure(with: text, on: view)
            }
#endif
        } else {    // 真机预览
            navigator.push(body: body, from: from)
        }
    }
}

