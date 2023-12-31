//
//  DocsFeedTracker.swift
//  SpaceKit
//
//  Created by maxiao on 2019/11/6.
//

import UIKit
import ThreadSafeDataStructure
import SKFoundation

extension String {
    var isZero: Bool {
        return self == "0"
    }
}

public final class DocsFeedTracker {

    enum DocFeedFrom: String {
        case larkFeed = "docs_feed"
        case message  = "message"   // chat_type包含single和group
        case vcFollow = "vcFollow"
        case other
    }

    enum DocFeedType: String {
        case unknown = "0"
        case mention = "1"
        case comment = "2"
        case reply   = "3"
        case solve   = "4"
        case share   = "5"
        case reopen  = "6"

        func toTrackerType() -> String {
            switch self {
            case .unknown:
                return "unknown"
            case .mention:
                return "mention"
            case .comment:
                return "comment"
            case .reply:
                return "reply"
            case .solve:
                return "sovle"
            case .share:
                return "share"
            case .reopen:
                return "reopen"
            }
        }
    }

    enum DocFeedV2Stage: String {
        case nativeCheckPermission = "stage_native_check_permission"
        case nativePullData        = "stage_native_pull_data"
        case nativeParseData       = "stage_native_parse_data"
        case nativeRenderData      = "stage_native_render_data"
        case nativeLoadFrontData   = "stage_native_load_front_data"
        case frontRenderData       = "stage_fe_pull_data"
        case frontProcessData      = "stage_fe_render_data"
        case frontPullData         = "stage_fe_process_data"
        case nativeLoadCache       = "stage_native_load_cache"
        
        //  === 4.0.0 记录Feed打开成功率 ===
        /// lark feed 入口
        case nativeLarkFeed        = "stage_lark_feed"
        /// browserVC viewdidLoad
        case nativeBrowserLoad     = "stage_browser_view_did_load"
        /// Feed init
        case nativeInit            = "stage_native_oncreate"
        /// Feed ViewDidAppear
        case nativeShow            = "stage_native_show"
        /// 加载缓存成功(模型映射后)
        case cacheLoaded           = "stage_cache_loaded"
        /// 获取web/后台数据(模型映射后)
        case receiveData           = "stage_receive_data"
        
    }

    enum DocFeedV2OpenResult: String {
        case success
        case fail
        case cancel
        case timeout
    }

    enum DocFeedV2DataSource: String {
        case cache   = "cache"
        case native  = "network"
        case webview = "webview"
    }

    struct DocsFeedInfo {
        var fileID: String      = ""
        var unreadCount: String = ""
        var feedID: String      = ""
        var badgeType: String   = ""
        var from: String        = ""
        var fileType: String    = ""
        var fileLength: Int = 0
        var startTime: TimeInterval = 0
    }

    static var currentInfo: DocsFeedInfo = DocsFeedInfo()
    static var timeCost = SafeDictionary<String, TimeInterval>()

    public static var needShowPanel: Bool = false

    class func startTrack(_ url: URL, params: [String: Any]) {

        guard let feedID = params["feed_id"] as? String,
              let unreadCount = params["unread_count"] as? String,
              let docMessageType = params["doc_message_type"] as? String,
              let from = url.queryParameters["from"] else {
                return
        }

        let feedTypeParam = DocFeedType(rawValue: docMessageType)?.toTrackerType() ?? "unknown"
        let docsInfo = DocsUrlUtil.getFileInfoFrom(url)
        let fileID = DocsTracker.encrypt(id: docsInfo.token ?? "")
        let fileType = docsInfo.type?.name ?? ""

        let params = [
        "feed_id": feedID,
        "unread_badge_count": unreadCount,
        "props_badge_count": unreadCount,
        "file_id": fileID,
        "file_type": fileType,
        "notification_type": feedTypeParam,
        "network_status": DocsNetStateMonitor.shared.isReachable,
        "feed_version": "2.0"
        ] as [String: Any]

        DocsFeedTracker.currentInfo = DocsFeedInfo(fileID: fileID,
                                                   unreadCount: unreadCount,
                                                   feedID: feedID,
                                                   badgeType: feedTypeParam,
                                                   from: from,
                                                   fileType: fileType,
                                                   startTime: Date().timeIntervalSince1970 * 1000.0)
        DocsFeedTracker.needShowPanel = !DocsFeedTracker.currentInfo.unreadCount.isZero &&
        DocsFeedTracker.currentInfo.badgeType != DocFeedType.share.toTrackerType() &&
        DocsFeedTracker.currentInfo.from == DocFeedFrom.larkFeed.rawValue

        DocsLogger.info("--------->打点了，点击LarkFeed打点上报\(params)---from:\(from)")
        DocsTracker.newLog(enumEvent: .feedPanelOps, parameters: params) // isHasNotification改为上报feed_panel_ops
    }
    
//    class func endTrack(_ params: [String: Any]) {
//        if DocsFeedTracker.currentInfo.feedID.isEmpty {
//            DocsLogger.info("--------->FeedID为空，不是点击红点进入")
//        }
//
//        var allParams: [String: Any] = params
//        allParams.merge(other: ["feed_id": DocsFeedTracker.currentInfo.feedID,
//                                "notification_type": DocsFeedTracker.currentInfo.badgeType,
//                                "badge_count": DocsFeedTracker.currentInfo.unreadCount])
//
//        DocsLogger.info("--------->打点了，打开面板打点上报\(allParams)---from:\(DocsFeedTracker.currentInfo.from)")
//        DocsTracker.log(enumEvent: .feedPanelOps, parameters: allParams)
//        DocsFeedTracker.clear()
//    }

//    class func clear() {
//        DocsFeedTracker.currentInfo = DocsFeedInfo()
//    }

//    class func trackV2Error(code: DocFeedV2ErrorCode) {
//        let params: [String: Any] = ["result_code": code.rawValue,
//                                     "feed_id": DocsFeedTracker.currentInfo.feedID,
//                                     "file_id": DocsFeedTracker.currentInfo.fileID,
//                                     "file_type": DocsFeedTracker.currentInfo.fileType,
//                                     "notification_type": DocsFeedTracker.currentInfo.badgeType,
//                                     "network_status": DocsNetStateMonitor.shared.isReachable,
//                                     "badge_count": DocsFeedTracker.currentInfo.unreadCount,
//                                     "feed_unread_badge_count": DocsFeedTracker.currentInfo.unreadCount]
//        DocsTracker.log(enumEvent: .feedV2Error, parameters: params)
//        DocsLogger.info("-----<V2打开错误\(params)")
//    }

//    public class func trackV2StageStart(stage: DocFeedV2Stage) {
//        DocsFeedTracker.timeCost[stage.rawValue] = Date().timeIntervalSince1970 * 1000
//    }
    
//    /// 在Feed VC 初始化前清空
//    public class func resetFeedStage() {
//        resetStageTime(stages: [.nativeInit, .nativeShow, .cacheLoaded, .receiveData])
//    }

//    public class func resetLarkFeedStage() {
//        resetStageTime(stages: [.nativeLarkFeed])
//    }
    
    private class func resetStageTime(stages: [DocFeedV2Stage]) {
        for stage in stages {
            DocsFeedTracker.timeCost[stage.rawValue] = nil
        }
    }
    
//    class func trackV2StageEnd(stage: DocFeedV2Stage, param: [String: Any]? = nil) {
//        guard let startTime = DocsFeedTracker.timeCost[stage.rawValue] else {
//            return
//        }
//        let timeCost = Date().timeIntervalSince1970 * 1000 - startTime
//        let stageParam: String = stage.rawValue
//        var params: [String: Any] = ["stage": stageParam,
//                                     "cost_time": timeCost,
//                                     "feed_id": DocsFeedTracker.currentInfo.feedID,
//                                     "file_id": DocsFeedTracker.currentInfo.fileID,
//                                     "file_type": DocsFeedTracker.currentInfo.badgeType,
//                                     "feed_msg_type": DocsFeedTracker.currentInfo.fileType,
//                                     "network_status": DocsNetStateMonitor.shared.isReachable,
//                                     "badge_count": DocsFeedTracker.currentInfo.unreadCount]
//        params.merge(other: param)
//        DocsTracker.log(enumEvent: .feedV2Stage, parameters: params)
//        DocsLogger.info("-----<V2打开耗时\(params)")
//    }

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
        
        func duration() -> TimeInterval? {
            var stages: (DocFeedV2Stage, DocFeedV2Stage) = (.nativeInit, .nativeInit)
            switch self {
            case .createView:
                stages = (.nativeLarkFeed, .nativeBrowserLoad)
            case .showFeed:
                stages = (.nativeInit, .nativeShow)
            case .handleDataFromDB:
                stages = (.nativeInit, .cacheLoaded)
            case .allFromFeed:
                stages = (.nativeLarkFeed, .receiveData)
            case .allFromJS:
                stages = (.nativeInit, .receiveData)
            }
            guard let begin = DocsFeedTracker.timeCost[stages.0.rawValue],
                  let end = DocsFeedTracker.timeCost[stages.1.rawValue] else {
                return 0
            }
            return end - begin
        }
    }
    
//    /// 4.0.0 记录Feed打开阶段的埋点，分别统计6个阶段的耗各个阶段可看DocsFeedOpenStage注释
//    /// 对应调用该方法的节点为： BrowserViewDidLoad、DocsFeed ViewDidAppear、Cache Loaded、JS Data Loaded
//    public class func trackV2Open(result: DocFeedV2OpenResult, dataSource: DocFeedV2DataSource?, param: [String: Any]?) {
//        var params: [String: Any] = ["result_key": result.rawValue,
//                                     "feed_id": DocsFeedTracker.currentInfo.feedID,
//                                     "file_id": DocsFeedTracker.currentInfo.fileID,
//                                     "file_type": DocsFeedTracker.currentInfo.fileType,
//                                     "feed_msg_type": DocsFeedTracker.currentInfo.badgeType,
//                                     "network_status": DocsNetStateMonitor.shared.isReachable,
//                                     "feed_unread_badge_count": Int(DocsFeedTracker.currentInfo.unreadCount) ?? 0,
//                                     "badge_count": DocsFeedTracker.currentInfo.unreadCount,
//                                     "file_data_length": DocsFeedTracker.currentInfo.fileLength
//                                     ]
//        params.merge(other: param)
//        if let ds = dataSource {
//            params["feed_data_source"] = ds.rawValue
//        }
//        for stage in DocsFeedOpenStage.allCases {
//            if let duration = stage.duration() {
//                params[stage.rawValue] = duration
//            }
//        }
//        DocsTracker.log(enumEvent: .feedV2Open, parameters: params)
//        DocsLogger.info("-----<V2打开成功率\(params)")
//    }
    
}
