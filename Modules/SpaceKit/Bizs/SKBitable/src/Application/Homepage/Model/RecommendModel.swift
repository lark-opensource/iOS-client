//
//  SKBitableRecommendNativeController.swift
//  SKBitable
//
//  Created by justin on 2023/8/30.
//

import Foundation
import UIKit
import SKFoundation
import SwiftyJSON
import SKCommon

// MARK: - Request model
struct RecommendRequestParam {
    // 服务端入参
    let chunkSize: Int
    let changeExtra: String
    let isRefresh: Bool // 同时也是埋点的参数
    let scene: Int
    
    // 其他参数
    let needCache: Bool
    
    // 埋点入参数
    let baseHPFrom: String
    
    func transformToDict() -> [String: Any] {
        var dict: [String: Any] =  [:]
        dict["chunk_size"] = chunkSize
        dict["change_extra"] = changeExtra
        dict["is_refresh"] = isRefresh
        dict["scene"] = scene
        return dict
    }
}

struct BacthReportRequestParam {
    // 服务端入参
    let contentIds: [String]
    // 1曝光 2点击
    let activityType: Int
    
    func transformToDict() -> [String: Any] {
        var dataDict: [String: Any] =  [:]
        dataDict["content_source_ids"] = contentIds
        dataDict["activity_type"] = activityType
        
        var dict: [String: Any] =  [:]
        if let dataJsonString = dataDict.jsonString {
            dict["data"] = dataJsonString
        }
        dict["report_type"] = 6
        
        return dict
    }
}

// MARK: - Response model
struct TrackingParams {
    let requestId: String
    let baseHPFrom: String
    let isRefresh: Bool
}

class RecommendResponse {
    private(set) var changeExtra: String = ""
    private(set) var hasMore: Bool = false
    private(set) var recommends:[Recommend] = []
    private(set) var requestId: String = ""
    
    
    init(_ json: JSON, trackingParams: TrackingParams?, context: BaseHomeContext) {
        if let changeExtra = json["change_extra"].string { self.changeExtra = changeExtra }
        if let hasMore = json["hasMore"].bool { self.hasMore = hasMore }
        if let recommends = json["contents"].array {
            var index = 0
            self.recommends = recommends.map({ recommendJson in
                let recommend = Recommend(recommendJson, context: context)
                if let trackingParams = trackingParams {
                    recommend.requestId = trackingParams.requestId
                } else {
                    recommend.requestId = "NA"
                }
                // 解析埋点字段
                index += 1
                recommend.positionInex = index
                recommend.baseHPFrom = trackingParams?.baseHPFrom ?? ""
                recommend.fromRefresh = trackingParams?.isRefresh ?? false
                return recommend
            })
        }
        requestId = trackingParams?.requestId ?? ""
    }
}

class Recommend: RecommendCardViewLifeCycle, RecommendCardImageTracker {
    class Owner {
        var ownerId: String?
        var ownerName: String?
        var avatarUrl: String?
        init(_ json: JSON) {
            if let ownerId = json["owner_id"].string { self.ownerId = ownerId }
            if let ownerName = json["owner_name"].string { self.ownerName = ownerName }
            if let avatarUrl = json["avatar_url"].string { self.avatarUrl = avatarUrl }
        }
    }
    
    class CoverInfo {
        var width: Float
        var height: Float
        init(_ json: JSON) {
            if let width = json["width"].float { self.width = width } else { self.width = 150}
            if let height = json["height"].float { self.height = height } else {self.height = 200.0}
        }
    }
    
    enum CoverLoadingState: String {
        case loading = "loading"
        case success = "true"
        case failed = "false"
    }
    
    // 服务端返回数据
    var title: String?
    var ownerId: String?
    var heat: Int?
    var contentUrl: String?
    var contentId: String?
    var contentType: Int?
    var coverToken: String?
    var coverUrl: String?
    var objToken: String?
    var owner: Owner
    var coverInfo: CoverInfo
    
    // 布局数据(计算)
    private(set) var cellHeight:CGFloat = 0
    private(set) var cellWidth: CGFloat = 0
    private(set) var imageHeight:CGFloat = 0
    private(set) var titleHeight:CGFloat = 0
    // 图片宽高比是否符合限制 0.2 - 5之间为合理
    private(set) var validWHRate: Bool = true
    
    // 埋点数据
    // 曝光开始时间戳
    private(set) var exposeStartTS: TimeInterval?
    // 服务端响应序列,如页面进入后的第一个请求的数据,则为1,上拉加载更多后则为2
    var respChunkSeq: Int = 1
    // 在整个页面数据源的排序
    var allPositionInex: Int = 1
    // 在当前resp数据源的排序
    var positionInex: Int = 1
    // 是否来源于刷新
    var fromRefresh: Bool = false
    // request_id
    var requestId: String = ""
    // 页面来源
    var baseHPFrom: String = ""
    // 封面加载状态
    var coverLoadState: CoverLoadingState = .loading

    private let context: BaseHomeContext

    init(_ json: JSON, context: BaseHomeContext) {
        self.context = context

        if let title = json["title"].string { self.title = title }
        if let ownerId = json["owner_id"].string { self.ownerId = ownerId }
        if let heat = json["heat"].int { self.heat = heat }
        if let contentUrl = json["content_url"].string { self.contentUrl = contentUrl }
        if let contentId = json["content_id"].string { self.contentId = contentId }
        if let contentType = json["content_type"].int { self.contentType = contentType }
        if let coverToken = json["cover_token"].string { self.coverToken = coverToken }
        if let coverUrl = json["cover_url"].string { self.coverUrl = coverUrl }
        if let objToken = json["obj_token"].string { self.objToken = objToken }
        
        owner = Recommend.Owner(json["owner"])
        coverInfo = Recommend.CoverInfo(json["cover_info"])
    }
    
    func computeLayout(_ itemWidth:CGFloat) {
        guard coverInfo.height > 0,
              coverInfo.width > 0,
              itemWidth > 0 else {
            DocsLogger.error("Recommend Model layout exception: cover height \(coverInfo.height) cover width \(coverInfo.width) item width \(itemWidth)")
            return
        }
        cellWidth = itemWidth
        
        var cursor = 0.0
        
        let WHRatio = CGFloat(coverInfo.width / coverInfo.height)
        
        validWHRate = WHRatio >= 0.25 && WHRatio <= 4
        if validWHRate {
            imageHeight = CGFloat(coverInfo.height / coverInfo.width) * itemWidth
        } else {
            imageHeight = itemWidth * 4 / 3
        }
        cursor += imageHeight
        // 内容图与标题(title)间距 12
        cursor += RecommendCellLayoutConfig.innerMargin12
        
        titleHeight = title?.getFitHeight(itemWidth - 2 * RecommendCellLayoutConfig.innerMargin12, font: RecommendCellLayoutConfig.titleLabelFont, lineHeght: 20.0) ?? 0.0
        titleHeight = min(titleHeight, 40.0)
        cursor += titleHeight
        // 标题(title)与作者间距 8
        cursor += RecommendCellLayoutConfig.innerMargin8
        
        // 作者行高 16
        cursor += RecommendCellLayoutConfig.innerLength16
        
        // 作者行与卡片间距 12
        cursor += RecommendCellLayoutConfig.innerMargin12
        
        cellHeight = cursor
    }
    
    func cardStartAppear(indexPath: IndexPath) {
        exposeStartTS = Date().timeIntervalSince1970
    }
    
    func cardFullAppear(indexPath: IndexPath) {
        let params = buildCommonTrackerParams()
        
        DocsTracker.newLog(enumEvent: DocsTracker.EventType.baseHomepageFeedContentView, parameters: params)
        if let contentId = contentId, !contentId.isEmpty {
            RecommendUserBehaviorBatchReporter.shared.reportExpose(contentId)
        }
    }
    
    func cardDidDisappear(indexPath: IndexPath) {
        var params = buildCommonTrackerParams()
        var customParams :[AnyHashable: Any] = [:]
        if let startTS = exposeStartTS {
            customParams["show_duration"] = Int((Date().timeIntervalSince1970 - startTS) * 1000)
            exposeStartTS = nil
        }
        params.merge(other: customParams)
        
        DocsTracker.newLog(enumEvent: DocsTracker.EventType.baseHomepageFeedContentEffectView, parameters: params)
    }
    
    func cardDidClick(indexPath: IndexPath) {
        // 人工干预上报
        if let contentId = contentId {
            RecommendUserBehaviorBatchReporter.shared.reportClick(contentId)
        }
        
        var params = buildCommonTrackerParams()
        var customParams :[AnyHashable: Any] = [:]
        if let startTS = exposeStartTS {
            customParams["show_duration"] = Int((Date().timeIntervalSince1970 - startTS) * 1000)
        }
        params.merge(other: customParams)
        
        DocsTracker.newLog(enumEvent: DocsTracker.EventType.baseHomepageFeedContentClick, parameters: params)
    }
    
    func cardLoadImageResult(success: Bool, error: Error?) {
        var params = buildCommonTrackerParams()
        var customParams :[AnyHashable: Any] = [:]
        if let error = error {
            customParams["crash_reason"] = error.localizedDescription
        }
        params.merge(other: customParams)

        DocsTracker.newLog(enumEvent: DocsTracker.EventType.baseHomepageFeedCoverView, parameters: params)
    }
}

extension Recommend {
    func buildCommonTrackerParams() -> [AnyHashable: Any] {
        var params :[AnyHashable: Any] = [:]
        params["file_id"] = DocUrlParser.getEncryptedToken(from: contentUrl) ?? ""
        params["file_type"] = DocUrlParser.geFileType(from: contentUrl) ?? ""
        params["container_env"] = context.containerEnv.rawValue
        params["tab_name"] = "recommend"
        params["base_hp_from"] = context.baseHpFrom
        params["content_id"] = contentId ?? ""
        params["content_name"] = title ?? ""
        params["request_rank_first"] = respChunkSeq
        params["all_position_index"] = allPositionInex
        params["position_index"] = positionInex
        params["request_id"] = requestId
        params["is_cover_load_success"] = coverLoadState.rawValue
        params["is_refresh"] = fromRefresh ? "true" : "false"
        params["target"] = "ccm_docs_page_view"
        params["module"] = "base_home"
        params["sub_module"] = "homepage_feed"
        params["happen_date"] = Date.currentToyyyyMMdd()
        params["hp_version"] = context.version.rawValue

        return params
    }
}

public class DiversionResponse {
    public private(set) var tab: DiversionTab
    
    init(_ json: JSON) {
        self.tab = DiversionTab(json["tab"])
    }
}

public enum TabType: String {
    case my = "my"
    case recommend = "feed"
}

public class DiversionTab: Codable {
    
    public private(set) var defaultSelect: TabType = .my
    public private(set) var expireTimeStamp: Double = 0
    
    init(_ json: JSON) {
        if let defaultSelect = json["default"].string { self.defaultSelect = TabType(rawValue: defaultSelect) ?? .my }
        if let expireTimeStamp = json["expire_time"].double { self.expireTimeStamp = expireTimeStamp }
    }
    
    enum CodingKeys: String, CodingKey {
        case defaultSelect
        case expireTimeStamp
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let selectType = try container.decode(String.self, forKey: CodingKeys.defaultSelect) as? String {
            defaultSelect = TabType(rawValue: selectType) ?? .my
        } else {
            defaultSelect = .my
        }
        expireTimeStamp = try container.decode(Double.self, forKey: CodingKeys.expireTimeStamp)

    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(defaultSelect.rawValue, forKey: CodingKeys.defaultSelect)
        try container.encode(expireTimeStamp, forKey: CodingKeys.expireTimeStamp)
    }
}
