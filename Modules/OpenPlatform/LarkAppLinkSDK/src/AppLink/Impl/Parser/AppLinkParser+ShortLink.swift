//
//  AppLinkParser+ShortLink.swift
//  LarkAppLinkSDK
//
//  Created by yinyuan on 2021/3/30.
//

import Foundation
import ECOProbe
import LKCommonsTracker
import LKCommonsLogging

/// 短链解析 
extension AppLinkParser {
    
    func isShortApplink(url: URL) -> Bool {
        guard isAppLinkSync(url: url) else {
            Self.logger.info("AppLink \(url.applinkEncyptString()) is not applink")
            return false
        }
        let code = String(url.path.dropFirst())
        return isValidCode(code: code)
    }
    
    private func isValidCode(code: String) -> Bool {
        let codeRule = "^[0-9A-Za-z]+$"
        let regexCode = NSPredicate(format: "SELF MATCHES %@", codeRule)
        if regexCode.evaluate(with: code) == true {
            return true
        } else {
            return false
        }
    }
    
    func parseShortLink(appLink: AppLink, callback: @escaping AppLinkHandler) {
        Self.logger.info("AppLink parser short applink")
        OPMonitor(AppLinkMonitorCode.applinkRoute)
            .setAppLink(appLink)
            .addCategoryValue("route", "handleShortLink")
            .flush()
        let url = appLink.url
        var shortLinkParseEvent: [String: Any] = ["link": "\(url)"]
        shortLinkParseEvent["path"] = appLink.url.path
        var handled = false
        // 局部handled变量，可以保证在同一次AppLink处理中唯一，加锁保证线程安全
        let markHandled = {
            objc_sync_enter(handled)
            handled = true
            objc_sync_exit(handled)
        }
        let readHandled: (() -> Bool) = {
            objc_sync_enter(handled)
            let flag = handled
            objc_sync_exit(handled)
            return flag
        }
        let timeout = settingsProvider.getApplinkParseTimeout()
        //超时逻辑，超时那就直接打开短链
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            guard !readHandled() else {
                Self.logger.info("AppLink read handle is false")
                return
            }
            markHandled()
            Self.logger.info("AppLink parse short applink timeout open \(url.applinkEncyptString())")
            shortLinkParseEvent["success"] = "0"
            shortLinkParseEvent["result_type"] = "fail"
            shortLinkParseEvent["error_code"] = AppLinkMonitorCode.shortLinkRequestTimeout.code;
            shortLinkParseEvent["error_msg"] = AppLinkMonitorCode.shortLinkRequestTimeout.message;
            Tracker.post(TeaEvent("applink_short_to_long", params: shortLinkParseEvent))
            OPMonitor(AppLinkMonitorCode.shortLinkRequestTimeout).addMap(shortLinkParseEvent).setAppLink(appLink).flush();
            callback(appLink)
        }
        //解析短链逻辑，如果解析OK，那么直接打开解析之后长链，如果解析错误，直接打开短链
        let begin = Date()
        httpClient.parseShortLink(link: url.absoluteString, from: "shortApplink") { (link, rsp, _) in
            Self.logger.info("AppLink parsed link:\(link)")
            guard !readHandled() else {
                Self.logger.info("AppLink parse short link ,read handle is false")
                return
            }
            markHandled()
            var link = AppLink(url: URL(string: link) ?? url, from: appLink.from)
            /// 保留原始上下文，避免上下文丢失
            link.context = appLink.context
            link.traceId = appLink.traceId
            callback(link)
            let duration = Int(Date().timeIntervalSince(begin) * 1000)
            shortLinkParseEvent["duration"] = duration
            if rsp["networkErr"] as? Bool == true || link.url.path == url.path {
                shortLinkParseEvent["success"] = "0"
                shortLinkParseEvent["result_type"] = "fail"
                shortLinkParseEvent["error_code"] = (rsp["code"] as? Int) ?? AppLinkMonitorCode.shortLinkRequestFail.code;
                shortLinkParseEvent["error_msg"] = (rsp["msg"] as? String) ?? AppLinkMonitorCode.shortLinkRequestFail.message;
                OPMonitor(AppLinkMonitorCode.shortLinkRequestFail).addMap(shortLinkParseEvent).setAppLink(appLink).flush()
            } else {
                shortLinkParseEvent["success"] = "1"
                shortLinkParseEvent["result_type"] = "success"
                shortLinkParseEvent["long_path"] = link.url.path
            }
            Tracker.post(TeaEvent("applink_short_to_long", params: shortLinkParseEvent))
        }
        return
    }
}
