//
//  ShareH5Helper.swift
//  Lark
//
//  Created by 王飞 on 2021/4/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import LarkFeatureGating
import LarkSetting
import LarkSnsShare
import LKCommonsLogging
import LarkUIKit
import WebBrowser
import RoundedHUD
import WebKit
import LarkOpenPlatform
import UniverseDesignToast
import TTMicroApp

struct ShareH5Helper {
    struct H5Info {
        let url: String
        let title: String?
        let desc: String?
        let iconURL: String?
    }
    static let logger = Logger.oplog(ShareH5Helper.self, category: "ShareH5Helper")
    static private var h5InfoScriptCache: String?
    static var webInfoScript: String? {
        if let scriptCache = h5InfoScriptCache {
            return scriptCache
        }
        var script: String?
        if FeatureGatingManager.shared.featureGatingValue(with: "openplatform.web.get_share_info_ogp") {
            logger.info("[Share]: start getting script file from settings")
            // 通过在 settings 上配置的 key，返回对应的 JS 脚本
            script = CommonComponentResourceManager().fetchJSWithSepcificKey(componentName: "js_for_web_getShareInfo") ?? ""

            guard !script.isEmpty else {
                // settings 获取失败
                logger.error("[Share]: get script file from settings failed")
                // 使用原始 JS 脚本兜底
                script = legacyGetH5InfoScript
                h5InfoScriptCache = script
                return script
            }
            logger.info("[Share]: get script file from settings successfully")
        } else {
            script = legacyGetH5InfoScript
        }
        h5InfoScriptCache = script
        return script
    }

    static func fetchWebInfo(withWebView webView: WKWebView,
                             successHandler: @escaping (H5Info) -> Void,
                             failedHandler: @escaping (Error?) -> Void) {
        guard let url = webView.url?.absoluteString else {
            logger.error("webview url null")
            failedHandler(nil)
            return
        }
        guard let script = webInfoScript else {
            logger.error("fetch webInfoScript failed")
            failedHandler(nil)
            return
        }
        webView.evaluateJavaScript(script) { (result, error) in
            guard error == nil else {
                logger.error("evaluate js failed", error: error)
                failedHandler(error)
                return
            }
            guard let res = result as? [String: String] else {
                logger.error("webInfo result exc")
                failedHandler(nil)
                return
            }
            logger.info("[Share]: fetch web info successfully",
                        additionalData: ["iconUrl": "\(res["iconUrl"] ?? "")", "description": "\(res["desc"] ?? "")", "title": "\(res["title"] ?? "")"])
            successHandler(H5Info(url: url, title: res["title"], desc: res["desc"], iconURL: res["iconUrl"]))
        }
    }

    static func share(service: LarkShareService,
                      traceId: String,
                      webBrowser: WebBrowser?,
                      successHandler: @escaping () -> Void,
                      failedHandler: @escaping (Error?) -> Void) {
        guard let browser = webBrowser else {
            logger.error("invaild api invoke")
            failedHandler(nil)
            return
        }

        fetchWebInfo(withWebView: browser.webview) { (info) in
            DispatchQueue.global().async {
                let thumbnailImage = try? URL(string: info.iconURL ?? "")
                    .map({ try Data(contentsOf: $0) })
                    .flatMap({ UIImage(data: $0) })
                DispatchQueue.main.async {
                    let prepare = WebUrlPrepare(title: info.title ?? "",
                                                webpageURL: info.url,
                                                thumbnailImage: thumbnailImage,
                                                description: info.desc ?? "")
                    service.present(by: traceId,
                                    contentContext: .webUrl(prepare),
                                    baseViewController: browser,
                                    downgradeTipPanelMaterial: nil, // 被禁下的 downgrade 方案，需要与 pm 评估下是否需要
                                    customShareContextMapping: nil,
                                    defaultItemTypes: [],
                                    popoverMaterial: nil,
                                    pasteConfig: .scPasteImmunity) { result, _ in
                        switch result {
                        case .success:
                            logger.info("share successed")
                            successHandler()
                        case .failure(let code, let msg):
                            logger.error("share failed, msg: \(msg)")
                            let errorInfo: String
                            switch code {
                            case .notInstalled:
                                errorInfo = LarkOpenPlatform.BundleI18n.OpenPlatformShare.OpenPlatform_Share_WeChat_Not_Installed
                            default:
                                errorInfo = "errorcode=\(code.rawValue)"
                            }
                            UDToast().showFailure(with: errorInfo, on: browser.view)
                            failedHandler(nil)
                        @unknown default:
                            assertionFailure()
                        }
                    }
                }
            }

        } failedHandler: { (error) in
            logger.error("share failed, msg: \(error?.localizedDescription ?? "")")
            let errorInfo = LarkOpenPlatform.BundleI18n.OpenPlatformShare.OpenPlatform_ShareH5_GetH5InfoFailedToast
            let config = UDToastConfig(toastType: .error, text: errorInfo, operation: nil)
            UDToast.showToast(with: config, on: browser.webview)
            failedHandler(error)
        }
    }
}

// 旧版获取网页信息脚本
private let legacyGetH5InfoScript = """
(function($){
var titleEle = [].slice.call($.document.head.getElementsByTagName('title'))[0];
var title = (titleEle && titleEle.innerText) || "";
var descEle = [].slice.call(document.head.getElementsByTagName('meta')).find(function(a){return a.getAttribute('name')==="description"});
var desc = (descEle && descEle.getAttribute('content')) || "";
if(!desc){
desc=document.body.innerText.replace(/\\n/g, " ");
}
var min_image_size=100;
var imgs=document.querySelectorAll('body img');
var iconUrl = '';
for (var i = 0; i<imgs.length;i++) {
    var img = imgs[i];
    if (img.naturalWidth>min_image_size&&img.naturalHeight>min_image_size) {
        iconUrl=img.src;
        break;
    }
}
return {title: title.replace(/[\\n\\t]/g, ""), desc: desc, iconUrl: iconUrl}
})(window);
"""
