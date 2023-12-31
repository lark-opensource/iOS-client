//
//  LarkWebViewMonitorServiceWrapper.swift
//  LarkWebViewContainer
//
//  Created by dengbo on 2021/12/30.
//

import Foundation
import LarkSetting
import LKCommonsLogging

public final class LarkWebViewMonitorServiceWrapper: LarkWebViewMonitorServiceProtocol {
    
    static let logger = Logger.lkwlog(LarkWebViewMonitorServiceWrapper.self, category: "MonitorServiceWrapper")
    
    public static let enableMonitor: Bool = {
        // code from dengbo
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.larkwebview.hybridmonitor.enable"))// user:global
    }()

    public static let enableReporter: Bool = {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.larkwebview.performance.report"))// user:global
    }()

    public init() {
        
    }
    
    public static func startMonitor() {
        guard Self.enableMonitor else { return }
        Self.logger.info("start monitor")
        LarkWebViewMonitorService.startMonitor()
    }
    
    public static func registerReportReceiver(receiver: LarkWebViewMonitorReceiver) {
        guard Self.enableReporter else {return }
        Self.logger.info("register report receiver")
        LarkWebViewMonitorService.registerReport(receiver)
    }
    
    public func configWebView(webView: LarkWebView) {
        guard Self.enableMonitor else { return }
        Self.logger.info("config webview type: \(webView.config.bizType.rawValue)")
        LarkWebViewMonitorService.configWebView(webView)
    }
    
    public func updateWKWebViewConfiguration(configuration: WKWebViewConfiguration, monitorConfig: LarkWebViewMonitorConfig) {
        guard Self.enableMonitor else { return }
        Self.logger.info("update WKWebViewConfiguration: \(monitorConfig.toString())")
        LarkWebViewMonitorService.update(configuration, monitorConfig: monitorConfig)
    }
    
    public func fetchNavigationId(webView: LarkWebView) -> String? {
        guard Self.enableReporter else {
            Self.logger.error("disable reporter")
            return nil
        }
        Self.logger.info("fetch navigation id")
        return LarkWebViewMonitorService.fetchNavigationId(webView)
    }
}
