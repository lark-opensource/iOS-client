//
//  OpenPluginPageLifeCycle.swift
//  EcosystemWeb
//
//  Created by yinyuan on 2021/11/10.
//

import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkWebViewContainer
import LarkSetting
import LKCommonsLogging
import OPSDK
import WebBrowser
import OPPlugin
import OPFoundation
import LarkContainer

private let logger = Logger.ecosystemWebLog(OpenPluginPageLifeCycle.self, category: "OpenPluginPageLifeCycle")

/// 页面生命周期事件
final class OpenPluginPageLifeCycle: OpenBasePlugin {
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        /// 引入来源：https://bytedance.feishu.cn/docx/doxcnxrkIn5PZLINemFwcLcR9Df
        /// JSSDK 通过该方法通知客户端页面回到前台
        registerAsyncHandler(for: "pageshow", paramsType: PageshowParams.self) { (params, context, callback) in
            // 来自 API 框架 @lixiaorui 要求：获取 OPAPIContextProtocol 只能通过该方式
            guard let apiContext = context.additionalInfo["gadgetContext"] as? OPAPIContextProtocol else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("gadgetContext is nil")
                context.apiTrace.error("gadgetContext is nil")
                callback(.failure(error: error))
                return
            }
            guard let browser = apiContext.controller as? WebBrowser else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("apiContext.controller is not WebBrowser")
                context.apiTrace.error("apiContext.controller is not WebBrowser")
                callback(.failure(error: error))
                return
            }
            if let navigationBarConfig = params.navigationBarConfig {
                do {
                    // 如果有 navigationBarConfig，需要设置生效
                    try OpenPluginWebNavigationBar.setNavigationBar(params: navigationBarConfig, browser: browser, from: "pageshow")
                } catch {
                    context.apiTrace.warn("setNavigationBar failed")
                }
            }
            if !FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: "openplatform.web.leaveconfirm.disable")), let leaveConfirmConfig = params.leaveConfirmConfig {// user:global
                // 如果有 leaveConfirmConfig，需要设置生效
                if let extensionItem = browser.resolve(LeaveConfirmExtensionItem.self) {
                    logger.info("trySetWebLeaveConfirm from pageshow")
                    if let error = OpenPluginApplication.trySetWebLeaveConfirm(extensionItem: extensionItem, params: leaveConfirmConfig) {
                        context.apiTrace.error("trySetWebLeaveConfirm failed", error: error)
                    }
                } else {
                    context.apiTrace.warn("LeaveConfirmExtensionItem is nil")
                }
            }
            if let meta = params.meta {
                logger.info("pageshow updateMetas")
                browser.updateMetas(metas: meta)
            }
            callback(.success(data: nil))
        }
    }
}

public final class PageshowParams: OpenAPIBaseParams {
    @OpenAPIOptionalParam(jsonKey: "navigationBarConfig")
    public var navigationBarConfig: SetTitleBarParams?
    
    @OpenAPIOptionalParam(jsonKey: "leaveConfirmConfig")
    public var leaveConfirmConfig: OpenAPIEnableLeaveConfirmParams?
    
    @OpenAPIOptionalParam(jsonKey: "meta")
    public var meta: [Dictionary<String, Any>]?
    
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_navigationBarConfig, _leaveConfirmConfig, _meta]
    }
}
