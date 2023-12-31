//
//  WebAppMonitorReporter.swift
//  EcosystemWeb
//
//  Created by dengbo on 2022/3/11.
//

import ECOProbe
import Foundation
import LarkWebViewContainer
import LKCommonsLogging
import LarkSetting

public final class WebAppMonitorReporter: WebAppMonitorProtocol {
    
    struct Const {
        static let perfEventName = "web_compass_performance"
        static let perfEventKeyScene = "scene"
        static let perfEventKeyURL = "url"
        static let perfEventKeyAppId = "app_id"
        static let perfEventKeyDuration = "duration"
        static let perfEventKeyStatus = "status"
        static let perfEventKeyErrorMsg = "error_msg"
        static let perfEventKeyTraceId = "trace_id"
        static let perfEventKeyisTerminateState = "is_terminate_state"
        static let perfEventKeyIsH5Loading = "is_h5_loading"
        static let perfEventKeyLoadDuration = "load_duration"
        static let perfEventKeyDomCount = "dom_count"
        static let perfEventKeyErrorStack = "error_stack"
    }
    
    static let logger = Logger.lkwlog(WebAppMonitorReporter.self, category: "WebAppMonitorReporter")
    
    private lazy var operationQueue = DispatchQueue(label: "com.bytedance.webapp.monitor.report")
    private lazy var cacheData: [String: [[String: Any]]] = [:]
    private lazy var navigationMap: [String: String] = [:]

    public static let shared: WebAppMonitorReporter = {
        let monitorReporter = WebAppMonitorReporter()
        return monitorReporter
    }()
    
    public func bind(appId: String?, webView: LarkWebView) {
        guard let navigationId = LarkWebViewMonitorServiceWrapper().fetchNavigationId(webView: webView) else {
            Self.logger.error("bind but navId cannot be nil")
            return
        }
        
        Self.logger.info("bind \(navigationId) to \(appId ?? "nil")")
        webView.lwk_navigationMap[navigationId] = appId
        
        guard let appId = appId else {
            Self.logger.error("bind but invalid appId")
            return
        }
        operationQueue.async {
            self.navigationMap[navigationId] = appId
            // 有了appId后立即清理一批缓存数据
            if let datas = self.cacheData[navigationId] {
                self.reportCachedEvent(appId: appId, datas: datas)
            }
            Self.logger.info("bind then flush cacheData navigationId: \(navigationId)")
            self.cacheData.removeValue(forKey: navigationId)
        }
    }
    
    public func checkBlank(appId: String?, webView: LarkWebView) {
        let appIdValue = appId ?? "" //如appId不存在, 用空字符串
        guard let url = webView.url?.absoluteString, let urlString = url.urlWithoutQuery() else {
            Self.logger.error("check blank but url is invalid")
            return
        }
        let traceId = webView.trace?.traceId ?? ""
        let isH5Loading = webView.isLoading
        let isTerminateState = webView.isTerminateState
        let duration = Int((webView.disappearTime - webView.createTime) * 1000)

        //增加DOM检测
        var domCount = -1 //默认值,区分0 div情形
        if !FeatureGatingManager.shared.featureGatingValue(with: "openplatform.webbrowser.checkdomcount.disable") {// user:global
            webView.checkContentDOM { res in
                switch res {
                case .success(let count):
                    domCount = count
                    Self.logger.info("check content dom count:\(domCount)")
                case .failure(_):
                    Self.logger.error("check content dom failed")
                }
            }
        }
        
        webView.checkBlank(backgroundColor: webView.scrollView.backgroundColor ?? .clear) { result in
            var isBlank = false
            var error: Error? = nil
            switch result {
            case .success(let blank):
                isBlank = blank
                Self.logger.info("check blank result:\(blank), dom:\(domCount), isLoading:\(isH5Loading)")
            case .failure(let err):
                error = err
                Self.logger.error("check blank error", error: err)
            }
            self.operationQueue.async {
                self.reportEvent(name: Const.perfEventName,
                                 data: [Const.perfEventKeyScene: "white_screen",
                                        Const.perfEventKeyStatus: isBlank ? "0" : "1",
                                        Const.perfEventKeyURL: urlString.safeURLString,
                                        Const.perfEventKeyAppId: appIdValue,
                                        Const.perfEventKeyTraceId: traceId,
                                        Const.perfEventKeyIsH5Loading: isH5Loading,
                                        Const.perfEventKeyisTerminateState: isTerminateState,
                                        Const.perfEventKeyLoadDuration: duration,
                                        Const.perfEventKeyDomCount: domCount],
                                 error: error)
            }
        }
    }
    
    public func flushEvent(webView: LarkWebView, clear: Bool) {
        Self.logger.info("flush event with clear: \(clear)")
        let map = webView.lwk_navigationMap
        operationQueue.async {
            for (navigationId, datas) in self.cacheData {
                if let appId = map[navigationId], let unwrappedAppId = appId {
                    self.reportCachedEvent(appId: unwrappedAppId, datas: datas)
                }
            }
            
            Array(map.keys).forEach {
                Self.logger.info("flush cacheData navigationId: \($0)")
                self.cacheData.removeValue(forKey: $0)
            }
            if clear {
                Array(map.keys).forEach {
                    Self.logger.info("flush navMap navigationId: \($0)")
                    self.navigationMap.removeValue(forKey: $0)
                }
            }
        }
    }
    
    private func reportCachedEvent(appId: String, datas: [[String: Any]]) {
        datas.forEach { data in
            var copyData = data
            copyData[Const.perfEventKeyAppId] = appId
            reportEvent(name: Const.perfEventName, data: copyData)
        }
    }
    
    private func reportEvent(name: String, data: [String: Any], error: Error? = nil) {
        Self.logger.info("report name: \(name), data: \(data)")
        let event = OPMonitor(name)
        for (key, value) in data {
            event.addCategoryValue(key, value)
        }
        if error != nil {
            event.setError(error)
        }
        event.setPlatform([.tea, .slardar])
            .flush()
    }
    
    private func cacheEvent(navigationId: String, data: [String: Any]) {
        Self.logger.info("cache \(navigationId) data \(data)")
        var dataArr = cacheData[navigationId] ?? []
        dataArr.append(data)
        cacheData[navigationId] = dataArr
    }
}

extension WebAppMonitorReporter: LarkWebViewMonitorReceiver {
    // 收到hybrid sdk传过来的数据
    public func recv(key: String?, data: [AnyHashable: Any]?) {
        guard let key = key , let data = data else {
            Self.logger.error("recv event cannot be nil")
            return
        }
        
        operationQueue.async {
            if key == "bd_hybrid_monitor_service_js_exception_web_" {
                self.handleJSExceptionData(data: data)
            } else if key == "bd_hybrid_monitor_service_perf_web_" {
                self.handleFMPPerfData(data: data)
            }
        }
    }
    
    // 处理js异常上报
    private func handleJSExceptionData(data: [AnyHashable: Any]) {
        Self.logger.info("handle js exception")
        guard let eventData = WebAppMonitorData.parseData(data: data),
                let serviceType = eventData.serviceType, serviceType == "js_exception",
                let navigationId = eventData.nativeBase?.navigationId,
                let url = eventData.urlWithoutQuery else {
                    Self.logger.error("data is invalid")
                    return
                }
        var params = [Const.perfEventKeyScene: "js_error",
                      Const.perfEventKeyURL: url,
                      Const.perfEventKeyErrorMsg: eventData.jsInfo?.exception?.message ?? "",
                      Const.perfEventKeyErrorStack: eventData.jsInfo?.exception?.stack ?? ""]
        if let appId = navigationMap[navigationId] {
            params[Const.perfEventKeyAppId] = appId
            reportEvent(name: Const.perfEventName, data: params)
        } else {
            cacheEvent(navigationId: navigationId, data: params)
        }
    }
    
    // 处理perf数据上报
    private func handleFMPPerfData(data: [AnyHashable: Any]) {
        Self.logger.info("handle fmp perf")
        guard let eventData = WebAppMonitorData.parseData(data: data),
                let serviceType = eventData.serviceType, serviceType == "perf",
                let navigationId = eventData.nativeBase?.navigationId,
                let url = eventData.urlWithoutQuery else {
                    Self.logger.error("data is invalid")
                    return
                }
        
        func action(params: inout [String: Any]) {
            if let appId = navigationMap[navigationId] {
                params[Const.perfEventKeyAppId] = appId
                reportEvent(name: Const.perfEventName, data: params)
            } else {
                cacheEvent(navigationId: navigationId, data: params)
            }
        }
        
        // fmp和tti分别上报一次
        var params: [String: Any] = [Const.perfEventKeyURL: url]
        if let fmp = eventData.jsInfo?.fmp {
            params[Const.perfEventKeyScene] = "fmp"
            params[Const.perfEventKeyDuration] = String(fmp)
            action(params: &params)
        }
        if let tti = eventData.jsInfo?.tti {
            params[Const.perfEventKeyScene] = "tti"
            params[Const.perfEventKeyDuration] = String(tti)
            action(params: &params)
        }
    }
}

extension LarkWebView {
    static var kMonitorReportFlag: Void?
    var lwk_navigationMap: [String: String?] {
        get {
            objc_getAssociatedObject(self, &LarkWebView.kMonitorReportFlag) as? [String: String?] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &LarkWebView.kMonitorReportFlag, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
