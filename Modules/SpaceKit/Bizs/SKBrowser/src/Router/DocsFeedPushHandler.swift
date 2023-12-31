//
//  DocsFeedPushHandler.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/2/10.
//  


import SKFoundation
import LarkRustClient
import RustPB
import SKCommon
import LKCommonsTracker
import RunloopTools
import SKInfra

final class PushDocsFeedHandler: BaseRustPushHandler<Basic_V1_Entity> {
    private let defaultDelayTime = 30 //MS
    private let maxPreloadCount = 10 //MS
    
    override func doProcessing(message: Basic_V1_Entity) {
        guard !message.docFeeds.isEmpty else {
            DocsLogger.error("[PushPreLoad] receive push but docFeeds isEmpty")
            return
        }
        DocsLogger.info("[PushPreLoad] preloadPushDocFeeds.count:\(message.docFeeds.count)", component: LogComponents.preload)
        let delayMS = SettingConfig.docsFeedPushPreloadConfig?.preloadDelay ?? defaultDelayTime
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(delayMS)) {
            // 预加载统一框架
            if !EditorManager.shared.registerIdelTask(preloadName: "PreloadPushDocFeed", action: {
                self.preloadDocFeeds(Array(message.docFeeds.values))
            }) {
                RunloopDispatcher.shared.addTask(priority: .low) { [weak self] in
                    DocsLogger.info("cpu.task: idlePreloadPushDocFeed")
                    self?.preloadDocFeeds(Array(message.docFeeds.values))
                }.waitCPUFree().withIdentify("leisureAsyncStage-PreloadPushDocFeed")
            }
        }
    }
       
    func preloadDocFeeds(_ feeds: [Basic_V1_DocFeed]) {
        let preloadLimitCount = SettingConfig.docsFeedPushPreloadConfig?.preloadLimitCount ?? maxPreloadCount
        let preloadFeeds = feeds.prefix(preloadLimitCount)
        DocsLogger.info("[PushPreLoad] start preloadPushDocFeeds(\(preloadFeeds.count), limit:\(preloadLimitCount)", component: LogComponents.preload)
        preloadFeeds.forEach { docFeed in
            if !docFeed.docURL.isEmpty, var docUrl = URL(string: docFeed.docURL) {
                EditorManager.shared.preloadContent(docUrl.absoluteString, from: FromSource.docsFeedPush.rawValue)
            } else {
                DocsLogger.error("[PushPreLoad] docsUrl error:\(docFeed.docURL)", component: LogComponents.preload)
            }
        }
    }
}
