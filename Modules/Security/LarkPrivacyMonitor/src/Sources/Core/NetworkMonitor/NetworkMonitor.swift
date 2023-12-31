//
//  NetworkMonitor.swift
//  LarkPrivacyMonitor
//
//  Created by Hao Wang on 2023/3/1.
//

import Foundation
import TSPrivacyKit
import LarkSnCService

/// 网络管控上报采样率，默认 1/100
private let kNetworkUploadSampleRateKey = "network_upload_sample_rate"
private let kEnableWebviewMonitor = "enable_webview_monitor"

public final class NetworkMonitor {

    public static let shared = NetworkMonitor()

    public var env: Environment?

    /// 输出log
    public var logger: Logger?

    private var config: Config?

    public func start(config: Config? = nil) {
        self.config = config
        let settings = config?.getSettings()
        // 1. 为网络管控设置配置
        // config 的注入和 Monitor 一致，业务基于 setting 来进行配置获取
        TSPKNetworkMonitor.setConfig(settings)
        // 2. 启动网络管控
        TSPKNetworkMonitor.start()
        TSPKEventManager.registerSubsciber(NetworkEngineSubscriber(), on: .networkResponse)

        if settings?[kEnableWebviewMonitor] as? Bool ?? false {
            logger?.info("NetworkMonitor Hybrid Monitor preload.")
            WebViewFlowPipeline.preload()
        }
    }

    public func canReport(_ event: TSPKNetworkEvent) -> Bool {
        // Block list
        if TSPKNetworkConfigs.isAllow(event) {
            return false
        }
        // 采样率
        let currentTime = Int64(CFAbsoluteTimeGetCurrent() * 1_000_000) // μs
        let sampleRateInt = self.config?.getSettings()?[kNetworkUploadSampleRateKey] as? Int64 ?? 100
        if sampleRateInt <= 0 {
            return false
        }
        return currentTime % sampleRateInt == 0
    }
}

private extension Config {
    func getSettings() -> [String: Any]? {
        return settings()
    }
}

final class NetworkEngineSubscriber: NSObject, TSPKSubscriber {
    func uniqueId() -> String {
        return NSStringFromClass(Self.self)
    }

    func canHandelEvent(_ event: TSPKEvent) -> Bool {
        return true
    }

    func hanleEvent(_ event: TSPKEvent) -> TSPKHandleResult? {
        guard let networkEvent = event as? TSPKNetworkEvent else {
            return nil
        }

        TSPKThreadPool.shard()?.networkWorkQueue()?.async { [weak self] in
            guard let self = self,
                  NetworkMonitor.shared.canReport(networkEvent) else {
                return
            }
            TSPKNetworkReporter.report(
                withCommonInfo: self.convertNetworkModelToParams(networkEvent),
                networkEvent: networkEvent
            )
        }
        return nil
    }

    func convertNetworkModelToParams(_ networkEvent: TSPKNetworkEvent) -> [String: Any]? {
        let request = networkEvent.request
        // common
        var dict: [String: Any] = ["is_request": false]
        dict["method"] = request?.tspk_util_HTTPMethod ?? ""
        dict["event_type"] = request?.tspk_util_eventType ?? ""
        dict["event_source"] = request?.tspk_util_eventSource ?? ""
        dict["is_redirect"] = request?.tspk_util_isRedirect
        // NSURL
        /// request
        dict["domain"] = request?.tspk_util_url?.host ?? ""
        dict["path"] = TSPKNetworkUtil.realPath(from: request?.tspk_util_url) ?? ""
        dict["scheme"] = request?.tspk_util_url?.scheme ?? ""
        /// response
        dict["res_domain"] = networkEvent.response?.tspk_util_url?.host ?? ""
        dict["res_path"] = TSPKNetworkUtil.realPath(from: networkEvent.response?.tspk_util_url) ?? ""
        dict["res_scheme"] = networkEvent.response?.tspk_util_url?.scheme ?? ""
        // other infos
        dict["monitor_scenes"] = "network_anaylze"
        dict["is_login"] = NetworkMonitor.shared.env?.isLogin
        dict["user_brand"] = NetworkMonitor.shared.env?.userBrand
        dict["package_id"] = NetworkMonitor.shared.env?.packageId
        dict["href"] = try? networkEvent.response?.tspk_util_value(forHTTPHeaderField: "href")?.asURL().urlWithoutQuery
        dict["referer"] = try? networkEvent.response?.tspk_util_value(forHTTPHeaderField: "referrer")?.asURL().urlWithoutQuery
        // response header 中 X-Lgw-Dst-Svc，X-Tt-Logid 大小写不一定固定，这里统一转小写后再获取字段值
        dict["X-Lgw-Dst-Svc"] = networkEvent.response?.tspk_util_headers?.valueOfKeyIgnoringCase(keyWithCase: "X-Lgw-Dst-Svc")
        dict["X-Tt-Logid"] = networkEvent.response?.tspk_util_headers?.valueOfKeyIgnoringCase(keyWithCase: "X-Tt-Logid")
        NetworkMonitor.shared.logger?.debug("pns_network: \(dict)")
        return dict
    }
}

extension URL {
    var urlWithoutQuery: String {
        (self.scheme ?? "") + "://" + (self.host ?? "") + self.path
    }
}

extension Dictionary where Key == String, Value == String {
    func valueOfKeyIgnoringCase(keyWithCase: String) -> String? {
        for (key, value) in self where key.lowercased() == keyWithCase.lowercased() {
            return value
        }
        return nil
    }
}
