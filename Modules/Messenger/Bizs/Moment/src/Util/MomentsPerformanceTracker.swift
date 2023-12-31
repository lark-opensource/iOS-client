//
//  MomentsPerformanceTracker.swift
//  Moment
//
//  Created by liluobin on 2021/4/6.
//

import Foundation
import UIKit
import AppReciableSDK
import LarkSDKInterface
import LarkSearchCore

enum FirstPageLoadFailSence: String {
    case configAndSettigsFail = "config_and_settigs_fail"
    case localListFeedFail = "local_list_feed_fail"
    case remoteFeedFail = "remote_feed_fail"
}

enum FeedTrackSence {
    case refresh
    case loadMore
}

struct MomentsTrackerInfo {
    var timeCost: TimeInterval
}

class MomentsBusinessTrackerItem {
    let biz: Biz
    let scene: Scene
    let event: Event
    let page: String

    /// 是否只上报一次
    var onlyReportOnce = false
    fileprivate var key: DisposedKey?
    init(biz: Biz = .Moments,
         scene: Scene = .MoFeed,
         event: Event,
         page: String) {
        self.biz = biz
        self.scene = scene
        self.event = event
        self.page = page
    }

    func isNeedNet() -> Bool {
        return false
    }

    /// 数据是否read，默认true，重写之后，可以自己校验
    /// dataIsReady is false 不会上报
    func dataIsReady() -> Bool {
        return true
    }

    func latencyDetail() -> [String: Any]? {
        return nil
    }

    func metric() -> [String: Any]? {
        return nil
    }

    func category() -> [String: Any]? {
        return nil
    }

    func startUploadItem() {
    #if DEBUG
        /// 用来观察数据
        print("startUploadItem data")
        print("\(NSStringFromClass(type(of: self))) latencyDetail() \(self.latencyDetail())")
        print("\(NSStringFromClass(type(of: self))) item.metric() \(self.metric())")
        print("\(NSStringFromClass(type(of: self))) item.category() \(self.category())")
    #endif
    }
    func endUploadItem() {
    #if DEBUG
        /// 用来观察数据
        print("endUploadItem data")
    #endif
    }
}

final class MomentsDetialItem: MomentsBusinessTrackerItem {

    var sdkCost: TimeInterval = 0
    var localRenderCost: TimeInterval = 0
    var remoteRenderCost: TimeInterval = 0
    var startLocalRenderTime: TimeInterval = 0
    var startRemoteRenderTime: TimeInterval = 0
    var commentStartRender: TimeInterval = 0

    override func isNeedNet() -> Bool {
        return true
    }

    override func latencyDetail() -> [String: Any]? {
        if startLocalRenderTime == 0 {
            return ["sdk_cost": Int(sdkCost * 1000),
                    "remote_data_render": Int(remoteRenderCost * 1000)]
        } else {
            return ["sdk_cost": Int(sdkCost * 1000),
                    "local_data_render": Int(localRenderCost * 1000),
                    "remote_data_render": Int(remoteRenderCost * 1000)]
        }
    }

    func updateDataWith(sdkCost: TimeInterval, remoteRenderCost: TimeInterval) {
        self.sdkCost += sdkCost
        self.remoteRenderCost += remoteRenderCost
    }

    func endRender() {
        if self.sdkCost == 0 {
            self.localRenderCost = CACurrentMediaTime() - startLocalRenderTime
        } else {
            self.remoteRenderCost = CACurrentMediaTime() - startRemoteRenderTime
        }
    }
}
// hashtag & 板块详情页 聚合页
final class MomentsPolymerizationItem: MomentsFeedUpdateItem {
    let isEligible: Bool
    init(biz: Biz = .Moments, scene: Scene = .MoFeed, detail: MomentsTracer.PageDetail?) {
        guard let event: Event = Self.eventFromPageDetail(detail) else {
            self.isEligible = false
            assertionFailure("数据异常")
            super.init(biz: biz, scene: scene, event: .momentsShowHashtagPage, page: "category")
            return
        }
        self.isEligible = true
        let page = event == .momentsShowHashtagPage ? "hashtag" : "category"
        super.init(biz: biz, scene: scene, event: event, page: page)
    }

    override func latencyDetail() -> [String: Any]? {
        var params: [String: Any] = ["sdk_remote_cost": Int(sdkCost * 1000),
                                     "remote_data_render": Int(renderCost * 1000)]
        params["sdk_extra_cost"] = Int(sdkExtraCost * 1000)
        params["remote_extra_render"] = Int(extraRenderCost * 1000)
        return params
    }

    override func dataIsReady() -> Bool {
        if !self.isEligible {
            return false
        }
        return sdkCost != 0 && sdkExtraCost != 0
    }
    override func metric() -> [String: Any]? {
        return ["feeds_count": postCount]
    }

    static func eventFromPageDetail(_ detail: MomentsTracer.PageDetail?) -> Event? {
        var event: Event?
        if let detail = detail {
            event = .momentsShowHashtagPage
            switch detail {
            case .category_comment, .category_post, .category_recommend:
                event = .momentsShowCategoryPage
            case .hashtag_hot, .hashtag_new, .hashtag_recommend:
                event = .momentsShowHashtagPage
            }
        }
        return event
    }
}

/// feed 上拉、下拉
class MomentsFeedUpdateItem: MomentsBusinessTrackerItem {
    var sdkCost: TimeInterval = 0

    var renderCost: TimeInterval = 0
    var startRenderTime: TimeInterval = 0

    var startSDKCostTime: TimeInterval = 0
    var sdkExtraCost: TimeInterval = 0

    var extraRenderCost: TimeInterval = 0
    var startExtraRenderTime: TimeInterval = 0

    var postCount: Int = 0
    var order: Int = 0

    override func isNeedNet() -> Bool {
        return true
    }

    override func latencyDetail() -> [String: Any]? {
        var params: [String: Any] = ["sdk_remote_cost": Int(sdkCost * 1000), "remote_data_render": Int(renderCost * 1000)]
        if self.event == .refreshFeed {
            params["sdk_extra_cost"] = Int(sdkExtraCost * 1000)
            params["remote_extra_render"] = Int(extraRenderCost * 1000)
        }
        return params
    }

    override func dataIsReady() -> Bool {
        /// page页没有sdkExtraCost
        if self.page == "home" {
            return true
        }
        if self.event == .loadMoreFeed {
            return sdkCost != 0
        }
        return sdkCost != 0 && sdkExtraCost != 0
    }

    override func metric() -> [String: Any]? {
        return ["feeds_count": postCount,
                "order": order]
    }

    func updateDataWithSDKCost(_ sdkCost: TimeInterval, postCount: Int) {
        self.sdkCost = sdkCost
        self.postCount = postCount
    }

    func startListRender() {
        self.startRenderTime = CACurrentMediaTime()
    }

    func endListRender() {
        self.renderCost = CACurrentMediaTime() - self.startRenderTime
    }

    func startHeaderRender() {
        self.startExtraRenderTime = CACurrentMediaTime()
    }

    func endHeaderRender() {
        self.extraRenderCost = CACurrentMediaTime() - self.startExtraRenderTime
    }

    func startheaderDataCost() {
        self.startSDKCostTime = CACurrentMediaTime()
    }

    func endheaderDataCost() {
        self.sdkExtraCost = CACurrentMediaTime() - self.startSDKCostTime
    }

   static func convertFeedTraceSenceToEvent(_ sence: FeedTrackSence) -> Event {
        switch sence {
        case .loadMore:
            return .loadMoreFeed
        case .refresh:
            return .refreshFeed
        }
    }
}
final class MomentsNotificationItem: MomentsBusinessTrackerItem {
    var sdkCost: TimeInterval = 0
    var renderCost: TimeInterval = 0
    var type: String = ""
    var startRenderTime: TimeInterval = 0

    init(biz: Biz, scene: Scene, event: Event, page: String, type: NoticeList.SourceType) {
        switch type {
        case .message:
            self.type = "message"
        case .reaction:
            self.type = "reaction"
        }
        super.init(biz: biz, scene: scene, event: event, page: page)
    }

    override func isNeedNet() -> Bool {
        return true
    }

    override func latencyDetail() -> [String: Any]? {
        return ["sdk_cost": Int(sdkCost * 1000),
                "render": Int(renderCost * 1000)]
    }

    override func category() -> [String: Any]? {
        return ["notification_type": type]
    }

    func startRender() {
        self.startRenderTime = CACurrentMediaTime()
    }

    func endRender() {
        self.renderCost = CACurrentMediaTime() - self.startRenderTime
    }
}

class MomentsFeedLoadItem: MomentsBusinessTrackerItem {
    var postCount: Int = 0
    var uiRenderStartForLocalData: TimeInterval = 0
    var uiRenderStartForRemoteData: TimeInterval = 0
    var sdkLocalDataRenderCost: TimeInterval = 0
    var sdkRemoteDataRenderCost: TimeInterval = 0
    var sdklocalCost: TimeInterval = 0
    var sdkRemoteCost: TimeInterval = 0

    func startLocalDataRender() {
        let time = CACurrentMediaTime()
        DispatchQueue.main.async {
            self.uiRenderStartForLocalData = time
        }
    }
    func startRemoteDataRender() {
        let time = CACurrentMediaTime()
        DispatchQueue.main.async {
            self.uiRenderStartForRemoteData = time
        }
    }

    func endLocalDataRender() {
        let current = CACurrentMediaTime()
        self.sdkLocalDataRenderCost = current - self.uiRenderStartForLocalData
    }

    func endRemoteDataRender() {
        let current = CACurrentMediaTime()
        self.sdkRemoteDataRenderCost = current - self.uiRenderStartForRemoteData
    }

    func sdkLocalCost(_ cost: TimeInterval) {
        DispatchQueue.main.async {
            self.sdklocalCost = cost
        }
    }

    func sdkRemotelCost(_ cost: TimeInterval, postCount: Int) {
        DispatchQueue.main.async {
            self.sdkRemoteCost = cost
            self.postCount = postCount
        }
    }

    override func latencyDetail() -> [String: Any]? {
        var params: [String: Any] = ["sdk_remote_cost": Int(sdkRemoteCost * 1000),
                                     "remote_data_render": Int(sdkRemoteDataRenderCost * 1000),
                                     "sdk_local_cost": Int(sdklocalCost * 1000),
                                     "local_data_render": Int(sdkLocalDataRenderCost * 1000)]
        params["sdk_extra_cost"] = 0
        params["remote_extra_render"] = 0
        return params
    }

    override func metric() -> [String: Any]? {
        return ["feeds_count": postCount]
    }
}
/// 冷启动上报  只上报一次
final class MomentsFeedFristScreenItem: MomentsFeedLoadItem {

    static let shared = MomentsFeedFristScreenItem(biz: .Moments,
                                                   scene: .MoFeed,
                                                   event: .momentsShowHomePage,
                                                   page: "home")

    var initViewStart: TimeInterval = 0
    var initViewCost: TimeInterval = 0
    var sdkConfigAndSettingsCost: TimeInterval = 0
    var startSdkConfigAndSettings: TimeInterval = 0
    var tabRenderCost: TimeInterval = 0
    var startTabRender: TimeInterval = 0
    var hadUpload = false

    override init(biz: Biz,
         scene: Scene,
         event: Event,
         page: String) {
        super.init(biz: biz, scene: scene, event: event, page: page)
        onlyReportOnce = true
    }

    func startSdkConfigAndSettingsCost() {
        self.startSdkConfigAndSettings = CACurrentMediaTime()
    }

    func endSdkConfigAndSettingsCost() {
        self.sdkConfigAndSettingsCost = CACurrentMediaTime() - self.startSdkConfigAndSettings
    }

    func startTabRenderCost() {
        self.startTabRender = CACurrentMediaTime()
    }

    func endTabRenderCost() {
        self.tabRenderCost = CACurrentMediaTime() - self.startTabRender
    }

    func initViewStartRender(isRecommend: Bool) {
        guard isRecommend, !hadUpload else {
            return
        }
        self.initViewStart = CACurrentMediaTime()
    }

    func endInitView(isRecommend: Bool) {
        guard isRecommend, !hadUpload else {
            return
        }
        let current = CACurrentMediaTime()
        self.initViewCost = current - self.initViewStart
    }

    override func isNeedNet() -> Bool {
        return true
    }

    override func latencyDetail() -> [String: Any]? {
        return ["sdk_local_cost": Int(sdklocalCost * 1000),
                "sdk_remote_cost": Int(sdkRemoteCost * 1000),
                "sdk_config_and_settings_cost": Int(sdkConfigAndSettingsCost * 1000),
                "tab_render": Int(tabRenderCost * 1000),
                "init_view_cost": Int(initViewCost * 1000),
                "local_data_render": Int(sdkLocalDataRenderCost * 1000),
                "remote_data_render": Int(sdkRemoteDataRenderCost * 1000)]

    }

    override func endUploadItem() {
        hadUpload = true
    }
}
// 发帖
final class MomentsSendPostItem: MomentsBusinessTrackerItem {

    var isAnonymous: Bool = false

    override func isNeedNet() -> Bool {
        return true
    }

    override func metric() -> [String: Any]? {
        return ["is_anonymous": isAnonymous]
    }
}

// 发评论
final class MomentsSendCommentItem: MomentsBusinessTrackerItem {

    var isAnonymous: Bool = false

    override func isNeedNet() -> Bool {
        return true
    }

    override func metric() -> [String: Any]? {
        return ["is_anonymous": isAnonymous]
    }
}

// 发布页统计
final class MomentsSendPostPageItem: MomentsBusinessTrackerItem {
    var sdkDraftStart: TimeInterval = 0
    var sdkDraftCost: TimeInterval = 0

    var sdkPolicyStart: TimeInterval = 0
    var sdkPolicyCost: TimeInterval = 0

    var sdkQuotaStart: TimeInterval = 0
    var sdkQuotaCost: TimeInterval = 0

    var sdkCategoryStart: TimeInterval = 0
    var sdkCategoryCost: TimeInterval = 0

    var startRenderDraftTime: TimeInterval = 0
    var renderCost: TimeInterval = 0

    override func isNeedNet() -> Bool {
        return true
    }

    override func latencyDetail() -> [String: Any]? {
        return ["sdk_draft_cost": Int(sdkDraftCost * 1000),
                "sdk_policy_cost": Int(sdkPolicyCost * 1000),
                "sdk_quota_cost": Int(sdkQuotaCost * 1000),
                "sdk_category_cost": Int(sdkCategoryCost * 1000),
                "render": Int(renderCost * 1000)]
    }

    func startRenderDraft() {
        self.startRenderDraftTime = CACurrentMediaTime()
    }
    func endRenderDraft() {
        self.renderCost = CACurrentMediaTime() - self.startRenderDraftTime
    }

    func startGetDraft() {
        self.sdkDraftStart = CACurrentMediaTime()
    }
    func endGetDraft() {
        self.sdkDraftCost = CACurrentMediaTime() - self.sdkDraftStart
    }

    func startGetPolicy() {
        self.sdkPolicyStart = CACurrentMediaTime()
    }

    func endGetPolicy() {
        self.sdkPolicyCost = CACurrentMediaTime() - self.sdkPolicyStart
    }

    func startGetQuota() {
        self.sdkQuotaStart = CACurrentMediaTime()
    }
    func endGetQuota() {
        self.sdkQuotaCost = CACurrentMediaTime() - self.sdkQuotaStart
    }

    func startGetCategory() {
        self.sdkCategoryStart = CACurrentMediaTime()
    }

    func endGetCategory() {
        self.sdkCategoryCost = CACurrentMediaTime() - self.sdkCategoryStart
    }
}

// 发视频
final class MomentsUploadVideoItem: MomentsBusinessTrackerItem {

    var startUploadCover: TimeInterval = 0
    var uploadCoverCost: TimeInterval = 0

    var startUploadVideo: TimeInterval = 0
    var uploadVideoCost: TimeInterval = 0

    var startTranscodeCost: TimeInterval = 0
    var transcodeCost: TimeInterval = 0

    var startParse: TimeInterval = 0
    var parseCost: TimeInterval = 0
    /// 单位 bit
    var videoSize: Float64 = 0

    override func isNeedNet() -> Bool {
        return true
    }

    override func latencyDetail() -> [String: Any]? {
        return ["upload_video": Int(uploadVideoCost * 1000),
                "upload_cover": Int(uploadCoverCost * 1000),
                "transcode_cost": Int(transcodeCost * 1000),
                "parse_cost": Int(parseCost * 1000)]
    }

    func endUploadVideo() {
        self.uploadVideoCost = CACurrentMediaTime() - self.startUploadVideo
    }

    func endUploadCover() {
        self.uploadCoverCost = CACurrentMediaTime() - self.startUploadCover
    }

    func endParse() {
        self.transcodeCost = CACurrentMediaTime() - self.startTranscodeCost
    }

    func endTranscode() {
        self.parseCost = CACurrentMediaTime() - self.startParse
    }

    override func metric() -> [String: Any]? {
        /// 单位Byte
        return ["video_size": videoSize / 8]
    }
}

// profile公司圈tab
final class MomentsProfileItem: MomentsBusinessTrackerItem {

    var startSdkProfileCost: TimeInterval = 0
    var startSdkProfileListCost: TimeInterval = 0
    var startRemoteProfileInfoRender: TimeInterval = 0
    var startRemoteProfileListRender: TimeInterval = 0

    var sdkProfileInfoCost: TimeInterval = 0
    var sdkProfileListCost: TimeInterval = 0
    var remoteProfileInfoRenderCost: TimeInterval = 0
    var remoteProfileListRenderCost: TimeInterval = 0

    var localProfileInfoRenderCost: TimeInterval = 0
    var sdkProfileInfoLocalCost: TimeInterval = 0
    var startLocalProfileInfoRenderCost: TimeInterval = 0

    override func isNeedNet() -> Bool {
        return true
    }

    func updateRemoteDataRenderTimeAndSdkProfileInfoCost(_ cost: TimeInterval) {
        self.startRemoteProfileInfoRender = CACurrentMediaTime()
        self.sdkProfileInfoCost = cost
    }

    func endRemoteProfileInfoRenderCost() {
        self.remoteProfileInfoRenderCost = CACurrentMediaTime() - self.startRemoteProfileInfoRender
    }

    func endRemoteProfileListRenderCost() {
        self.remoteProfileListRenderCost = CACurrentMediaTime() - self.startRemoteProfileListRender
    }

    func startLocalProfileListRenderCost() {
        self.startLocalProfileInfoRenderCost = CACurrentMediaTime()
    }

    func endLocalProfileListRenderCost() {
        self.localProfileInfoRenderCost = CACurrentMediaTime() - self.startLocalProfileInfoRenderCost
    }

    override func latencyDetail() -> [String: Any]? {
        return ["sdk_profile_info_cost": Int(sdkProfileInfoCost * 1000),
                "sdk_profile_list_cost": Int(sdkProfileListCost * 1000),
                "remote_profile_info_render": Int(remoteProfileInfoRenderCost * 1000),
                "remote_profile_list_render": Int(remoteProfileListRenderCost * 1000),
                "local_profile_info_render": Int(localProfileInfoRenderCost * 1000),
                "sdk_profile_info_local_cost": Int(sdkProfileInfoLocalCost * 1000)]
    }
}

final class MomentsCommonTracker {
    /// 上报一次后 不再上报
    static var filterOnceItems: [MomentsBusinessTrackerItem.Type] = []

    var trackerItems: [MomentsBusinessTrackerItem] = []

    func startTrackWithItem(_ item: MomentsBusinessTrackerItem) {
        self.trackerItems.removeAll { $0.event == item.event }
        if Self.filterOnceItems.contains(where: { $0 === type(of: item) }) {
            return
        }
        let key = AppReciableSDK.shared.start(biz: item.biz,
                                              scene: item.scene,
                                              event: item.event,
                                              page: item.page)
        item.key = key
        trackerItems.append(item)
    }

    func getItemWithEvent(_ event: Event) -> MomentsBusinessTrackerItem? {
        var currentItem: MomentsBusinessTrackerItem?
        self.trackerItems.forEach { (item) in
            if item.event == event {
                currentItem = item
            }
        }
        return currentItem
    }

    func endTrackWithEvent(_ event: Event) {
        let item = self.getItemWithEvent(event)
        self.endTrackWithItem(item)
    }

    func endTrackWithItem(_ item: MomentsBusinessTrackerItem?) {
        guard let item = item,
              item.dataIsReady(),
                let key = item.key,
                !Self.filterOnceItems.contains(where: { $0 === type(of: item) }) else {
            return
        }
        if item.onlyReportOnce {
            Self.filterOnceItems.append(type(of: item))
        }
        self.trackerItems.removeAll { $0.event == item.event }
        item.startUploadItem()
        AppReciableSDK.shared.end(key: key, extra: Extra(isNeedNet: item.isNeedNet(),
                                                         latencyDetail: item.latencyDetail(),
                                                         metric: item.metric(),
                                                         category: item.category()))
        item.endUploadItem()
    }

}

/// 业务上的逻辑代码收敛在这里
extension MomentsCommonTracker {
    func startTrackFeedItemWithIsRecommendTab(_ isRecommendTab: Bool) {
        if isRecommendTab, !MomentsFeedFristScreenItem.shared.hadUpload {
            self.startTrackWithItem(MomentsFeedFristScreenItem.shared)
        } else {
            self.startTrackWithItem(MomentsFeedLoadItem(event: .momentsShowCategoryPage, page: "home"))
        }
    }
    func getMomentsFeedLoadItem(isRecommendTab: Bool) -> MomentsFeedLoadItem? {
        if !MomentsFeedFristScreenItem.shared.hadUpload, isRecommendTab {
            return MomentsFeedFristScreenItem.shared
        } else {
            return self.trackerItems.first { ($0 as? MomentsFeedLoadItem) != nil } as? MomentsFeedLoadItem
        }
    }

    func endTrackWithDetail(_ detail: MomentsTracer.PageDetail?) {
        guard let detail = MomentsPolymerizationItem.eventFromPageDetail(detail) else {
            return
        }
        let item = self.getItemWithEvent(detail) as? MomentsPolymerizationItem
        item?.endListRender()
        self.endTrackWithItem(item)
    }

    func endTrackFeedUpdateItemForExtra(_ item: MomentsFeedUpdateItem?) {
        guard let item = item else {
            return
        }
        if let polymerizationItem = item as? MomentsPolymerizationItem {
            let currentItem = self.getItemWithEvent(polymerizationItem.event) as? MomentsPolymerizationItem
            currentItem?.extraRenderCost = polymerizationItem.extraRenderCost
            currentItem?.sdkExtraCost = polymerizationItem.sdkExtraCost
            self.endTrackWithItem(currentItem)
        } else {
            self.endTrackWithItem(item)
        }
    }

    func endTrackFeedUpateItem() {
        let block: (MomentsFeedUpdateItem) -> Void = { [weak self] item in
            item.endListRender()
            self?.endTrackWithItem(item)
        }

        if let item = self.getItemWithEvent(.refreshFeed) as? MomentsFeedUpdateItem {
            block(item)
            return
        }

        if let item = self.getItemWithEvent(.loadMoreFeed) as? MomentsFeedUpdateItem {
            block(item)
        }
    }

}
final class MomentsErrorTacker {

    static func trackFeedError(_ error: Error, event: Event, page: String = "home", failSence: FirstPageLoadFailSence? = nil) {
        if let failSence = failSence, !MomentsFeedFristScreenItem.shared.hadUpload {
            let extra = Extra(isNeedNet: true, category: ["scene_type": failSence.rawValue])
            Self.trackReciableEventError(error,
                                         sence: .MoFeed,
                                         event: event,
                                         page: page,
                                         extra: extra)
            MomentsFeedFristScreenItem.shared.hadUpload = true
        } else {
            self.trackReciableEventError(error, sence: .MoFeed, event: .momentsShowCategoryPage, page: page)
        }
    }

    static func trackFeedUpdateError(_ error: Error, event: Event? = nil, pageDetail: MomentsTracer.PageDetail?) {
        guard let pageDetail = pageDetail else {
            return
        }
        let autoEvent: Event
        var page = ""
        switch pageDetail {
        case .category_comment, .category_post, .category_recommend:
            page = "category"
            autoEvent = .momentsShowCategoryPage
        case .hashtag_hot, .hashtag_new, .hashtag_recommend:
            page = "hashtag"
            autoEvent = .momentsShowHashtagPage
        }
        self.trackFeedError(error, event: event ?? autoEvent, page: page)
    }

    static func trackReciableEventError(_ error: Error, sence: Scene, event: Event, page: String, extra: Extra? = nil) {
        var isNetworkError = false
        var errorCode: Int = 0
        if let apiError = error.underlyingError as? APIError {
            errorCode = Int(apiError.code)
            switch apiError.type {
            case .networkIsNotAvailable:
                isNetworkError = true
            default:
                break
            }
        }
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Moments,
                                                        scene: sence,
                                                        event: event,
                                                        errorType: isNetworkError ? .Network : .SDK,
                                                        errorLevel: .Exception,
                                                        errorCode: errorCode,
                                                        userAction: nil,
                                                        page: page,
                                                        errorMessage: error.localizedDescription,
                                                        extra: extra ?? Extra(isNeedNet: true)))
    }
}
