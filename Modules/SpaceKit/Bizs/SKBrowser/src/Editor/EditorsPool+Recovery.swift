//
//  EditorsPool+Recovery.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/7/12.
//

import SKFoundation
import SKCommon
import SKInfra
import SKUIKit
import LKCommonsTracker
import SpaceInterface
import LarkPerf

extension EditorsPool {
    
    func recoverEditorIfNeed(editor: ResuableItem, failCount: Int, inPool: Bool) {
        guard UserScopeNoChangeFG.LJY.enableResetWKProcessPool else {
            return
        }
        guard let docsWebViewConfig = SettingConfig.docsWebViewConfig,
              let maxResetCount = docsWebViewConfig.resetWKProcessPoolContinuousFailCount,
              maxResetCount > 0, failCount >= maxResetCount else {
            return
        }
        
        guard let resetWebViewMaxCount = docsWebViewConfig.resetWebViewPolicy.resetWebViewMaxCount,
              resetWebViewMaxCount > self.recoveryWebViewCount else {
            DocsLogger.warning("reset WebView, Reached max reset count,\(self.recoveryWebViewCount)", component: LogComponents.editorPool)
            return
        }
        
        var hasKillAllContent = false
        var hasKillNetwork = false
        var hasKillClearCache = false
        var hasResetPool = false
        var policy = 0
        //重启WebView相关进程 https://bytedance.sg.feishu.cn/docx/PTYhd9THoolK2xxVTmdlRPHYgch
        if docsWebViewConfig.resetWebViewPolicy.shouldKillAllWebContentProcess {
            if let webview = (editor as? WebBrowserView)?.editorView as? DocsWebViewV2 {
                if webview.killAllContentProcess() {
                    hasKillAllContent = true
                    policy |= RecoverWebViewPolicy.killAllContent.rawValue
                    DocsLogger.warning("reset WebView, kill All Content Process", component: LogComponents.editorPool)
                }
            }
        }
        
        if docsWebViewConfig.resetWebViewPolicy.shouldKillNetworkProcess {
            if let webview = (editor as? WebBrowserView)?.editorView as? DocsWebViewV2 {
                if webview.killNetworkProcess() {
                    hasKillNetwork = true
                    policy |= RecoverWebViewPolicy.killNetwork.rawValue
                    DocsLogger.warning("reset WebView, kill Network Process", component: LogComponents.editorPool)
                }
            }
        }
        
        //删除WKWebView缓存 https://bytedance.sg.feishu.cn/docx/F84UdLIq3oNAWixTX2TluOQ3gPf
        if docsWebViewConfig.resetWebViewPolicy.shouldClearWebCache {
            hasKillClearCache = true
            policy |= RecoverWebViewPolicy.clearWKCache.rawValue
            DocsWebViewV2.clearWKCache { count in
                DocsLogger.warning("reset WebView, clear WKWebView Cache:\(count)", component: LogComponents.editorPool)
            }
        }
        
        //失败次数超过阈值，重置WKProcess进程 https://bytedance.feishu.cn/wiki/DWWmwEtk3iMb0qkE6Kec6tBrnnd
        if docsWebViewConfig.resetWebViewPolicy.resetWKProcessPool {
            hasResetPool = true
            policy |= RecoverWebViewPolicy.resetPool.rawValue
            DocsLogger.warning("reset WebView, resetWKProcessPool", component: LogComponents.editorPool)
            NetConfig.shared.resetWKProcessPool()
        }
        
        reportResetWKProcessPool(inPool: inPool,
                                 hasKillAllContent: hasKillAllContent,
                                 hasKillNetwork: hasKillNetwork,
                                 hasKillClearCache: hasKillClearCache,
                                 hasResetPool: hasResetPool,
                                 policy: policy)
        resetWKProcessPoolPolicy = policy
        recoveryWebViewCount += 1
        DocsLogger.info("reset WebView, inpool:\(inPool), failCount:\(failCount), policy: \(policy), recoveryCount:\(recoveryWebViewCount)", component: LogComponents.editorPool)
    }
    
    func reportResetWKProcessPool(inPool: Bool,
                                  hasKillAllContent: Bool,
                                  hasKillNetwork: Bool,
                                  hasKillClearCache: Bool,
                                  hasResetPool: Bool,
                                  policy: Int) {
        let param: [String: Any] = ["from": CheckResponsiveFrom.wkProcessPool.rawValue,
                                    "responsive": 0,
                                    "continuousFailCount": continuousFailCount,
                                    "run_time":  LarkProcessInfo.sinceStart(),
                                    "in_pool": inPool,
                                    "hasKillAllContent": hasKillAllContent,
                                    "hasKillNetwork": hasKillNetwork,
                                    "hasKillClearCache": hasKillClearCache,
                                    "hasResetPool": hasResetPool,
                                    "policy": policy
        ]
        DocsTracker.newLog(enumEvent: .webviewResponsiveState, parameters: param)
    }
    
    func canAutoPreloadWebView() -> Bool {
        guard let stopCount = SettingConfig.docsWebViewConfig?.stopAutoPreloadWebViewContinuousFailCount else {
            return true
        }
        let can = stopCount > self.continuousFailCount
        if !can {
            DocsLogger.info("stop Auto Preload WebView by ContinuousFailCount:\(self.continuousFailCount)", component: LogComponents.editorPool)
        }
        return can
    }
}
 
/// 恢复WebView策略
struct RecoverWebViewPolicy: OptionSet {
    let rawValue: Int
    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let resetPool = RecoverWebViewPolicy(rawValue: 1 << 0)
    static let killAllContent = RecoverWebViewPolicy(rawValue: 1 << 1)
    static let killNetwork = RecoverWebViewPolicy(rawValue: 1 << 2)
    static let clearWKCache = RecoverWebViewPolicy(rawValue: 1 << 3)
}
