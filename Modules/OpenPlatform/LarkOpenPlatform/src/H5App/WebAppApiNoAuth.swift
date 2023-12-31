//
//  WebAppApiNoAuth.swift
//  LarkOpenPlatform
//
//  Created by yi on 2021/3/31.
//
// 跳过config鉴权&auth的处理类

import Foundation
import WebBrowser
import LKCommonsLogging
import ECOProbe

public final class WebAppApiNoAuth: NSObject, WebAppApiNoAuthProtocol {
    private let jssdk: WebAppJsSDK
    private static let logger = Logger.oplog(WebAppApiNoAuth.self, category: "OPWeb.NoAuth")

    public init(apiHost: WebBrowser) {
        self.jssdk = WebAppJsSDK(api: apiHost)
        super.init()
    }

    // api免鉴权白名单
    public func isAPINoNeedAuth(apiName: String) -> Bool {
        return apiName == "share" // code from yiying
            || apiName == "requestAuthCode" // 免登优化
            || apiName == "requestAccess" // 增量授权
            || apiName == "config" // code from xiangyuanyuan
            || apiName == "setMainNavRightItems" // 私有化大 KA 诉求
            || apiName == "setStatusBarColor"   // IG需求
            || apiName == "setNavigationBar"   // KA 需求
            || apiName == "pageshow"   // KA 需求
            || apiName == "closeWindow"
            || apiName == "updateMeta"   // meta三期
            || apiName == "hostIsPrivate" // 错误页
            || apiName == "getErrorMetaInfo" // 错误页
            || apiName == "showWebCustomErrorPage"  // 定制错误页
            || apiName == "setAPIConfig" //api 分发 https://bytedance.feishu.cn/docx/doxcnWffBhDf095YqcHH4oDuAyc
            || apiName == "invokeCustomAPI"
            // Base Forms Start
            || apiName == "biz.bitable.formConfiguration"
            || apiName == "biz.bitable.chooseAttachment"
            || apiName == "biz.bitable.checkAttachmentValid"
            || apiName == "biz.bitable.previewAttachment"
            || apiName == "biz.bitable.deleteAttachment"
            || apiName == "biz.bitable.uploadAttachment"
            || apiName == "biz.bitable.getLocation"
            || apiName == "biz.bitable.reverseGeocodeLocation"
            || apiName == "biz.bitable.chooseLocation"
            || apiName == "biz.bitable.openLocation"
            || apiName == "biz.forms.createTraceId"
            || apiName == "biz.forms.reportWithTraceId"
            || apiName == "biz.forms.scanCode"
            // Base Forms End
            || apiName == "setNavigationBarColor" // web-meta 导航栏二期 code from dingxu.shawn
            || apiName == "getContainerContext"   // 获取运行环境上下文信息 code from luogantong
            || apiName == "openMyAI"
            || apiName == "closeWebDebugConnection"      //关闭调试链接
            || apiName == "getWebDebugConnection"      //获取调试链接
            || apiName == "device.js.read.content"
            || apiName == "getFilterFeatureGating"
    }

    @discardableResult
    public func invoke(method: String, args: [String: Any], shouldUseNewBridgeProtocol: Bool, trace: OPTrace, webTrace: OPTrace?) -> Bool {
        WebAppApiNoAuth.logger.info("invoke tt method=\(method) not need auth")

        return jssdk.invoke(method: method, args: args, needAuth: false, shouldUseNewBridgeProtocol: shouldUseNewBridgeProtocol, trace: trace, webTrace: webTrace)
    }
}
