//
//  DocFeedPanelTracker.swift
//  SKCommon
//
//  Created by huayufan on 2021/6/17.
//  


import UIKit
import ThreadSafeDataStructure
import SKFoundation

struct DocFeedPanelTracker {
    
    enum Event {
        /// 耗时分析
        case timeRecord(store: [FeedTimeStage: TimeInterval])
    }
    
    var timeCost = SafeDictionary<String, TimeInterval>()
    
    enum DocsFeedOpenStage: String, CaseIterable {
        /// Lark Feed ---  BrowserViewDidLoad
        case createView = "cost_time_stage_createView"
        /// DocsFeed init --- DocsFeed ViewDidAppear 动画弹出耗时
        case showFeed = "cost_time_stage_showFeed"
        /// DocsFeed init --- Cache Loaded 缓存加载耗时
        case handleDataFromDB = "cost_time_stage_handleDataFromDB"
        /// Lark Feed  --- JS Data Loaded larkfeed到获取前端数据耗时
        case allFromFeed = "cost_time_all_from_feed"
        /// DocsFeed init  --- JS Data Loaded 打开铃铛到加载前端数据耗时
        case allFromJS = "cost_time_all_from_js"
        
        case renderView = "cost_time_render_view"
        
        /// Lark Feed  --- 创建BrowserViewController前节点耗时
        case beforeEditorOpen = "cost_time_before_editor_open"
        
        /// Lark Feed  --- 复用池取出editorView节点耗时
        case makeEditorEnd = "cost_time_make_editor_end"
        
        /// Lark Feed  --- 注册业务services节点耗时
        case registerServices = "cost_time_register_services"
        
        /// Lark Feed  --- BrowserViewController init 节点耗时
        case controllerInit = "cost_time_controller_init"
    }
    
    
}


extension DocFeedPanelTracker {
    
    func report(event: Event, openStatus: FeedOpenStatus, docsInfo: DocsInfo, fromInfo: FeedFromInfo?) {
        let token = docsInfo.wikiInfo?.objToken ?? docsInfo.objToken
        switch event {
        case let .timeRecord(store):
            var params: [String: Any] = ["result_key": openStatus.rawValue,
                                         "feed_id": fromInfo?.feedId ?? "",
                                         "file_id": DocsTracker.encrypt(id: token),
                                         "file_type": docsInfo.type.name,
                                         "feed_msg_type": fromInfo?.messageType.toTrackerType() ?? "",
                                         "network_status": DocsNetStateMonitor.shared.isReachable,
                                         "feed_unread_badge_count": fromInfo?.unreadCount ?? 0,
                                         "badge_count": "\(fromInfo?.unreadCount ?? 0)",
                                         "file_data_length": 0,
                                         "feed_data_source": "network",
                                         "feed_version": "v3",
                                         "feed_entrance": fromInfo?.entrance ?? 0
                                         ]
            let times = getAllStageTime(store)
            params.merge(times) { (_, new) in new }
            DocsTracker.log(enumEvent: .feedV2Open, parameters: params)
            DocsLogger.feedInfo("report:\(times)")
        }
    }
    
    private func getAllStageTime(_ store: [FeedTimeStage: TimeInterval]) -> [String: TimeInterval] {
        var dict: [String: TimeInterval] = [:]
        var stages: (FeedTimeStage, FeedTimeStage) = (.create, .create)
        for stage in DocsFeedOpenStage.allCases {
            switch stage {
            case .createView:
                stages = (.larkFeed, .willOpenFeed)
            case .showFeed:
                stages = (.create, .viewDidAppear)
            case .handleDataFromDB:
                stages = (.create, .cacheLoad)
            case .allFromFeed:
                stages = (.larkFeed, .deserialize)
            case .allFromJS:
                stages = (.create, .deserialize)
            case .renderView:
                stages = (.renderBegin, .renderEnd)
            case .beforeEditorOpen:
                stages = (.larkFeed, .beforeEditorOpen)
            case .makeEditorEnd:
                stages = (.larkFeed, .makeEditorEnd)
            case .controllerInit:
                stages = (.larkFeed, .controllerInit)
            case .registerServices:
                stages = (.larkFeed, .registerServices)
            }
            dict[stage.rawValue] = getStageTime(store: store, from: stages.0, to: stages.1)
        }
        return dict
    }
    
    func debugInfo(event: Event) {
        switch event {
        case let .timeRecord(store):
            debugPrint("doc new feed: all\(getAllStageTime(store))")
        }
    }
    
    private func getStageTime(store: [FeedTimeStage: TimeInterval], from: FeedTimeStage, to: FeedTimeStage) -> TimeInterval {
        guard let left = store[from],
              let right = store[to] else {
            return 0
        }
        return right - left
    }
}
