//
//  ShareHandler.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/23.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkUIKit
import LKCommonsLogging
import LarkContainer
import EENavigator
import LarkMessengerInterface
import LarkSDKInterface
import WebBrowser
import LarkOPInterface

class ShareHandler: JsAPIHandler, UserResolverWrapper {
    
    static let logger = Logger.log(ShareHandler.self, category: "Module.JSSDK")
    
    @ScopedProvider private var shareH5Service: ShareH5Service?

    let userResolver: UserResolver // UserResolverWrapper
    
    init(resolver: UserResolver) {
        userResolver = resolver
    }
    
    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        let url = args["url"] as? String
        let title = args["title"] as? String
        let iconURL = args["image"] as? String
        let desc = args["content"] as? String
        OPMonitor(EPMClientOpenPlatformShareCode.share_entry_start)
            .addCategoryValue("op_tracking", "opshare_h5_sdk_api")
            .addCategoryValue("hasURL", "\(!(url?.isEmpty ?? true))")
            .addCategoryValue("hasTitle", "\(!(title?.isEmpty ?? true))")
            .addCategoryValue("hasImage", "\(!(iconURL?.isEmpty ?? true))")
            .addCategoryValue("hasContent", "\(!(desc?.isEmpty ?? true))")
            .flush()

        guard let urlParam = url, let titleParam = title else {
            var missParams: [String] = []
            if (url?.isEmpty ?? true) {
                missParams.append("url")
            }
            if (title?.isEmpty ?? true) {
                missParams.append("title")
            }
            OPMonitor(EPMClientOpenPlatformShareCode.share_api_verify_failed)
                .addCategoryValue("op_tracking", "opshare_h5_sdk_api")
                .addCategoryValue("param_name", missParams.joined(separator: ","))
                .flush()
            callback.callbackFailure(param: ["errorMessage": "url or title is empty"])
            return
        }
        shareHandler(
            url: urlParam,
            title: titleParam,
            iconURL: iconURL,
            desc: desc,
            api: api,
            sdk: sdk,
            callback: callback
        )
    }

    /// 新版本分享API，支持 image, content 可选参数，分享样式由文本变为卡片（ShareH5）
    private func shareHandler(
        url: String,
        title: String,
        iconURL: String?,
        desc: String?,
        api: WebBrowser,
        sdk: JsSDK,
        callback: WorkaroundAPICallBack
    ) {
        // 可选参数
        let icon = iconURL.map({ ShareH5Context.Icon.url($0) })
        let context = ShareH5Context(
            type: .h5API, url: url, title: title, desc: desc, icon: icon, targetVC: api
        )
        
        guard let shareH5Service = try? userResolver.resolve(assert: ShareH5Service.self) else {
            Self.logger.error("resolve ShareH5Service failed")
            callback.callbackFailure(param: NewJsSDKErrorAPI.resolveServiceError.description())
            return
        }
        
        shareH5Service.share(with: context, successHandler: {
            Self.logger.info("[JSSDK(biz.util.share)]: share success")
            callback.callbackSuccess(param: [:])
        }, errorHandler: { error in
            Self.logger.error("[JSSDK(biz.util.share)]: share failed", error: error)
            callback.callbackFailure(param: [:])
        })
    }
}
