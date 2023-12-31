//
//  ShareContainer.swift
//
//  Created by Meng on 2020/12/7.
//

import Foundation
import LarkContainer
import LarkOPInterface
import LKCommonsLogging
import LKCommonsTracker
import LarkUIKit
import LarkFeatureGating
import LarkSetting
import Homeric
import RoundedHUD
import JsSDK
import WebBrowser
import LarkOpenPlatform
import EENavigator
import LarkMessengerInterface
import ECOInfra

// swiftlint:disable all
final class ShareH5Container {
    static let logger = Logger.oplog(ShareH5Container.self, category: "WebView.ShareH5Container")
    @Provider private var shareH5Service: ShareH5Service

    private let shareEvent: OPMonitor

    init() {
        shareEvent = OPMonitor("op_h5_share_result")
    }

    /// H5分享（H5网页/H5应用）
    /// 收敛统一了所有H5 WebView容器的分享逻辑
    /// 内部区分H5网页和应用类型，区分新旧版本分享
    ///
    func shareH5(target: ShareH5InfoTarget) {
        Self.logger.info("[ShareH5]: start share h5")

        // monitor 通用参数填写
        shareEvent
            .setMonitorCode(WAMonitorCodeRuntime.share_error)
            .setResultTypeFail()
            .addCategoryValue("app_id", target.appID ?? "")
            .addCategoryValue("H5Type", target.isWebApp ? "application": "normal")

        OPMonitor(OPShareMonitorCodeH5.share_entry_start)
            .addCategoryValue("app_id", target.appID)
            .addCategoryValue("op_tracking", target.isWebApp ? "opshare_web_app_pageshare" : "opshare_web_pageshare")
            .flush()

        // 业务埋点
        let teaEvent = TeaEvent(
            Homeric.APP_SHARE,
            category: "AppCenter",
            params: ["app_capability_type": target.isWebApp ? "WebPage" : "H5"]
        )
        Tracker.post(teaEvent)
        
        // 若发送链接至会话
        var shareURLWhiteList: [String] = []
        do {
            shareURLWhiteList = try SettingManager.shared.setting(with: Array<String>.self, key: UserSettingKey.make(userKeyLiteral: "h5_share_link_settings"))
            Self.logger.info("get shareLink setting: \(shareURLWhiteList)")
        } catch {
            Self.logger.error("get shareLink setting error: \(error)")
            shareURLWhiteList = []
        }
        
        if WebMetaMoreMenuConfigExtensionItem.isWebShareLinkEnabled(), let webBrowser = target.targetVC as? WebBrowser, let pureShareURL = target.shareWebView.url {
            Self.logger.info("share pureShareURL: \(pureShareURL)")
            let component = URLComponents(url: pureShareURL, resolvingAgainstBaseURL: false)
            let hostAndPath = "\(component?.host ?? "")\(component?.path ?? "")"
            Self.logger.info("shareLink hostAndPath: \(hostAndPath), need shareLink: \(shareURLWhiteList.contains(hostAndPath))")
            if shareURLWhiteList.contains(hostAndPath) || webBrowser.resolve(WebMetaMoreMenuConfigExtensionItem.self)?.isShareLink == true {
                let title = webBrowser.webview.title
                let urlStr = pureShareURL.absoluteString
                let body = ShareContentBody(title: title ?? "", content: urlStr)
                Navigator.shared.present(body: body, from: webBrowser, prepare: { $0.modalPresentationStyle = .formSheet })
                Self.logger.info("[ShareH5]: push share link body")
                return
            }
        }

        fetchH5Info(target: target) { [weak self](url, title, desc, icon) in
            Self.logger.info("[ShareH5]: fetch h5 success, start share")
            self?.share(with: target, url: url, title: title, desc: desc, icon: icon)
        } failedHandler: { error in
            Self.logger.error("[ShareH5]: share failed", error: error)
            RoundedHUD.showFailure(
                with: LarkOpenPlatform.BundleI18n.OpenPlatformShare.Lark_Legacy_ShareFailed,
                on: target.targetVC.view
            )
        }
    }

    /// 通过统一JS脚本抓取网页信息
    private func fetchH5Info(
        target: ShareH5InfoTarget,
        successHandler: @escaping (String, String, String?, ShareH5Context.Icon?) -> Void,
        failedHandler: @escaping (Error?) -> Void
    ) {
        Self.logger.info("[ShareH5]: start fetch h5 info", additionalData: [
            "hasURL": "\(!(target.shareWebView.url?.absoluteString.isEmpty ?? true))",
            "h5Type": target.isWebApp ? "application": "normal"
        ])

        guard let url = target.shareWebView.url?.absoluteString else {
            shareEvent.setErrorMessage("share faild cause webview url is nil").flush()
            failedHandler(nil)
            return
        }

        guard let script = getH5InfoScript() else {
            shareEvent.setErrorMessage("share faild cause get script failed").flush()
            failedHandler(nil)
            return
        }

        target.shareWebView.evaluateJavaScript(script) { [weak self](res, error) in
            guard error == nil else {
                self?.evaluateJSFailed(target: target, error: error!)
                Self.logger.error("[ShareH5]: evaluate JS failed", error: error)
                // 调用失败仍走兜底方案，即 title 有服务端使用原始链接兜底
                successHandler(url, "", nil, nil)
                return
            }
            guard let res = res as? [String: String] else {
                Self.logger.error("[ShareH5]: can not deserialize res", error: error)
                // 解析失败仍走兜底方案，即 title 有服务端使用原始链接兜底
                successHandler(url, "", nil, nil)
                return
            }

            Self.logger.info("[ShareH5]: did fetched h5Info",
                             additionalData: ["resKeys": "\(res.keys)", "iconUrl": "\(res["iconUrl"] ?? "")", "description": "\(res["desc"] ?? "")", "title": "\(res["title"] ?? "")"])

            let icon: ShareH5Context.Icon? = res["iconUrl"].map({ ShareH5Context.Icon.url($0) })
            let desc = self?.truncateH5Desc(desc: res["desc"])

            // H5App的会在服务端处理不同端的跳转拼装
            // mobile: lark://client/web?app_id={appId}&url={url}
            // pc: lark://appcenter.open?appId={appId}&url={url}
            //
            // desc 如果为空，服务端会兜底使用原始链接
            // icon 如果为空，服务端会使用默认图兜底
            successHandler(url, res["title"] ?? "", desc, icon)
        }
    }

    private func share(
        with target: ShareH5InfoTarget,
        url: String,
        title: String,
        desc: String?,
        icon: ShareH5Context.Icon?
    ) {
        var newUrl = url
        var context = ShareH5Context(
            type: target.isWebApp ? .h5App : .h5,
            appId: target.appID,
            url: newUrl,
            title: title,
            desc: desc,
            icon: icon,
            targetVC: target.targetVC
        )
        if target.isWebApp, let appId = target.appID, let applink = H5Applink.generateAppLink(targetUrl: url, appId: appId) {
            newUrl = applink.absoluteString
            context.appId = nil
            context.url = newUrl
        }
        shareH5Service.share(with: context, successHandler: { [weak self] in
            self?.shareEvent
                .setMonitorCode(WAMonitorCodeRuntime.share_success)
                .setResultTypeSuccess()
                .flush()
            Self.logger.info("[ShareH5]: share h5 info success")
        }, errorHandler: { [weak self](error) in
            self?.shareEvent.setErrorMessage("share faild, error: \(error?.localizedDescription ?? "")").flush()
            Self.logger.error("[ShareH5]: share h5 info failed", error: error)
            if OPUserScope.userResolver().fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.share.on_icon_upload_failed.show_no_toast.disable")) {
                RoundedHUD.showFailure(
                    with: LarkOpenPlatform.BundleI18n.OpenPlatformShare.Lark_Legacy_ShareFailed,
                    on: target.targetVC.view
                )
            }
        })
    }

    private func evaluateJSFailed(target: ShareH5InfoTarget, error: Error) {
        let message =
            "getH5Info failed with \(target.monitorURLInfo), error: \(error.localizedDescription)"
        let category =
            target.isWebApp ? "applicationGetH5Info" : "normalGetH5Info"
        shareEvent
            .setErrorMessage(message)
            .addCategoryValue("shareType", category)
            .flush()
    }

    private func getH5InfoScript() -> String? {
        return ShareH5Helper.webInfoScript
    }

    private func truncateH5Desc(desc: String?) -> String? {
        guard let desc = desc else {
            return nil
        }

        let disableH5TruncateDesc = LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.h5.share.truncate.disable")

        Self.logger.info("[ShareH5]: truncate h5 desc", additionalData: [
            "disable": "\(disableH5TruncateDesc)",
            "count": "\(desc.count)"
        ])

        if disableH5TruncateDesc {
            return desc
        }

        // 300为双端跟server商定的值，有问题通过disableH5TruncateDesc关掉即可，没必要通过FG动态下发
        return desc.substring(to: min(300, desc.count))
    }
}

// swiftlint:enable all

@objcMembers
public final class WAMonitorCodeRuntime: OPMonitorCode {

    /// web crash
    static public let webview_crash = WAMonitorCodeRuntime(code: 10_000, level: OPMonitorLevelError, message: "webview_crash")

    /// H5 App 分享成功
    static public let share_success = WAMonitorCodeRuntime(code: 10_008, level: OPMonitorLevelNormal, message: "share_success")

    /// H5 App 分享失败
    static public let share_error = WAMonitorCodeRuntime(code: 10_009, level: OPMonitorLevelError, message: "share_error")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: WAMonitorCodeRuntime.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.open_platform.web.runtime"
}
