//
//  FeedPerfTrack.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/7/16.
//

import Foundation
import RxSwift
import RxCocoa
import LarkPerf
import LKCommonsTracker
import RustPB
import LarkModel
import AppReciableSDK
import LarkSDKInterface
import LarkOpenFeed

/// LarkPerf相关打点，在LarkPerf基础上包一层原因:
/// 1. 收敛所有LarkPerf打点
/// 2. 部分LarkPerf打点有判断逻辑，不希望这些逻辑污染VC/VM
final class FeedPerfTrack {
    // MARK: - 首屏Feeds加载性能

    enum LoadFeedsState {
        case start // 开始加载
        case success // 加载成功
        case fail // 加载失败
    }

    /// 首屏Feeds加载性能
    static func trackLoadFirstPageFeeds(biz: FeedBizType, status: LoadFeedsState) {
        // 只有Inbox才会上报
        guard biz == .inbox else { return }
        switch status {
        case .start:
            AppStartupMonitor.shared.start(key: .feed)
            EnterAppMonitor.shared.start(key: .feed)
            SwitchUserMonitor.shared.start(key: .feed)
            SwitchUserUnifyMonitor.shared.end(key: .clearDataCost)
            SwitchUserUnifyMonitor.shared.start(key: .sdkGetFeedCardsV2)
        case .success:
            AppStartupMonitor.shared.end(key: .feed)
            EnterAppMonitor.shared.end(key: .feed)
            EnterAppMonitor.shared.update(step: .feedLoadSuccess)
            SwitchUserMonitor.shared.end(key: .feed)
            SwitchUserMonitor.shared.update(step: .feedLoadSuccess)
            SwitchUserUnifyMonitor.shared.end(key: .sdkGetFeedCardsV2)
            SwitchUserUnifyMonitor.shared.update(step: .renderFeedCost)
        case .fail:
            EnterAppMonitor.shared.end(key: .feed)
            EnterAppMonitor.shared.update(step: .feedLoadFail)
            SwitchUserMonitor.shared.end(key: .feed)
            SwitchUserMonitor.shared.update(step: .feedLoadFail)
            SwitchUserUnifyMonitor.shared.end(key: .sdkGetFeedCardsV2)
            SwitchUserUnifyMonitor.shared.update(step: .renderFeedCost)
        }
    }

    enum RenderStatus {
        case start // 开始渲染
        case end // 结束渲染
    }
    // FeedVC Init到首次viewDidAppear；冷启动打这个点，切租户不应该打，flag应为static
    private static var firstRenderStart = false
    private static var firstRenderEnd = false
    static func trackFirstRender(status: RenderStatus) {
        switch status {
        case .start:
            if !firstRenderStart {
                AppStartupMonitor.shared.start(key: .firstRender)
                firstRenderStart = true
            }
        case .end:
            if !firstRenderEnd {
                firstRenderEnd = true
                AppStartupMonitor.shared.end(key: .firstRender)
                AppStartupMonitor.shared.end(key: .startup)
                EnterAppMonitor.shared.end(key: .toMainShow)
                EnterAppMonitor.shared.update(step: .feedShow)
            }
        }
    }

    static func trackUpdateFeedShow() {
        SwitchUserMonitor.shared.update(step: .feedShow)
    }

    /// 首屏渲染完成，Cell非空时才有，当没有Cell的时候，没有时机打这个点
    static func trackFirstScreenDataReady() {
        ColdStartup.shared?.do(.firstScreenDataReady)
    }

    /// 点击Feed Cell打点
    static func trackFeedCellClick(_ preview: FeedPreview) {
        ClientPerf.shared.singleEvent("feed_click",
                                      params: ["feedID": preview.id],
                                      cost: nil)
    }

    /// Feed 下拉加载：start为开始加载展示菊花，end为结束当次加载更多
    static func trackFeedLoadingMore(bizType: FeedBizType, isStart: Bool = false) {

        let dict = [
            FeedBizType.inbox: ("inbox", 0),
            FeedBizType.done: ("done", 1),
            FeedBizType.box: ("chatBox", 2)
        ]

        guard let info = dict[bizType] else {
            return
        }

        if isStart {
            ClientPerf.shared.startSlardarEvent(service: "feed_load_more_time",
                                            indentify: info.0)
        } else {
            ClientPerf.shared.endSlardarEvent(service: "feed_load_more_time",
                                              indentify: info.0,
                                          category: ["scene": info.1])
        }
    }

    /// short cut: 监听从服务器第一次开始加载 short cut 的时间
    static func trackFeedLoadShortcutTimeStart() {
        AppStartupMonitor.shared.start(key: .shortcut)
    }

    /// short cut: 监听从服务器第一次结束加载 的时间
    static func trackFeedLoadShortcutTimeEnd() {
        AppStartupMonitor.shared.end(key: .shortcut)
    }

    /// short cut: 从服务器第一次收到响应后传contextID
    static func trackShortcutSetContextID(contextID: String) {
        if !contextID.isEmpty {
            AppStartupMonitor.shared.set(key: .shortcutContextID, value: contextID)
        }
    }

    /// 在shortcut点击chat cell 进行跳转
    static func trackJmpToChatByShortCut(id: String) {
        ClientPerf.shared.singleEvent("feed router to chat by shortCut", params: ["chatId": id], cost: nil)
    }

    // MARK: LoadMore打点

    // 每次loadmore & 显示底部菊花时 进行打点
    static func trackFeedLoadMoreStart() -> DisposedKey {
        return AppReciableSDK.shared.start(biz: .Messenger,
                                           scene: .Feed,
                                           event: .feedLoadMore,
                                           page: "MainFeedsViewController",
                                           userAction: nil,
                                           extra: nil)
    }

    static func trackFeedLoadMoreEnd(key: DisposedKey,
                                     getFeedCards: TimeInterval) {
        let latencyDetail = ["sdk_get_feed_cards": getFeedCards]
        let extra = Extra(isNeedNet: true,
                          latencyDetail: latencyDetail,
                          metric: nil,
                          category: nil)
        AppReciableSDK.shared.end(key: key, extra: extra)
    }

    // 每次loadmore & 没有显示底部菊花时 进行打点
    static func trackFeedLoadMoreTimecost(getFeedCards: TimeInterval) {

        let latencyDetail = ["sdk_get_feed_cards": getFeedCards]
        let extra = Extra(isNeedNet: true,
                          latencyDetail: latencyDetail,
                          metric: nil,
                          category: nil)

        let params = TimeCostParams(biz: .Messenger,
                                    scene: .Feed,
                                    event: .feedLoadMore,
                                    cost: -1,
                                    page: "MainFeedsViewController",
                                    extra: extra)
        AppReciableSDK.shared.timeCost(params: params)
    }

    // 当loadMore失败时打点
    static func trackFeedLoadMoreError(_ error: APIError) {
        let extra = Extra(isNeedNet: true,
                          latencyDetail: nil,
                          metric: nil,
                          category: nil)
        var errorType: ErrorType = .Unknown
        switch error.type {
        case .remoteRequestTimeout, .networkIsNotAvailable:
            errorType = .Network
        case .internalRustClientError:
            errorType = .SDK
        default:
            errorType = .Unknown
        }
        let code = Int(error.code)
        let errorMessage = "displayMessage: \(error.displayMessage) + serverMessage: \(error.serverMessage)"
        let params = ErrorParams(biz: .Messenger,
                                 scene: .Feed,
                                 event: .feedLoadMore,
                                 errorType: errorType,
                                 errorLevel: .Exception,
                                 errorCode: code,
                                 userAction: nil,
                                 page: "MainFeedsViewController",
                                 errorMessage: errorMessage,
                                 extra: extra)
        AppReciableSDK.shared.error(params: params)
    }

    // MARK: - 指标建设 点击置顶/取消置顶

    /// shortcutData 的访问都是在主线程进行的
    private static var shortcutData: TrackShortcutActionData?
    /// 点击置顶按钮时开始计时
    static func trackHandleShortcutStart(action: TrackShortcutActionData.ShortcutAction, shortcutID: String) {
        let disposedKey = AppReciableSDK.shared.start(biz: .Messenger,
                                                      scene: .Feed,
                                                      event: .shortCutAction,
                                                      page: "Feeds",
                                                      userAction: nil,
                                                      extra: nil)
        let shortcutData = TrackShortcutActionData(id: shortcutID,
                                                   action: action,
                                                   disposedKey: disposedKey)
        Self.shortcutData = shortcutData
    }

    /// sdk接口返回时存储接口耗时
    static func updateShortcutSdkCost() {
        guard let shortcutData = Self.shortcutData else {
            return
        }
        shortcutData.end()
        tryTrackHandleShortcutEnd(shortcutData)
    }

    /// view拿到数据进行刷新时，判断操作shortcut是否成功，并存储操作是否成功的结果
    static func updateShortcutFinishState(array: [ShortcutCellViewModel]) {
        guard let shortcutData = Self.shortcutData else {
            return
        }
        var isChecked = false
        let isExist = array.first(where: { $0.feedID == shortcutData.id }) != nil
        switch shortcutData.action {
        case .add:
            if isExist { isChecked = true }
        case .delete:
            if !isExist { isChecked = true }
        }
        shortcutData.updated = isChecked
        if isChecked { tryTrackHandleShortcutEnd(shortcutData) }
    }

    /// 尝试上报
    private static func tryTrackHandleShortcutEnd(_ shortcutData: TrackShortcutActionData) {
        guard shortcutData.updated,
              let sdkCost = shortcutData.sdkCost else {
            return
        }

        let latencyDetail = ["sdk_cost": sdkCost]
        let category = ["action": shortcutData.action.rawValue]
        let extra = Extra(isNeedNet: true,
                          latencyDetail: latencyDetail,
                          metric: nil,
                          category: category)
        AppReciableSDK.shared.end(key: shortcutData.disposedKey, extra: extra)
        Self.shortcutData = nil
    }

    /// 当操作shortcut失败时打点
    static func trackHandleShortcutError(_ error: APIError, action: TrackShortcutActionData.ShortcutAction) {
        let category = ["action": action.rawValue]
        let extra = Extra(isNeedNet: true,
                          latencyDetail: nil,
                          metric: nil,
                          category: category)
        let error = error.getInfo()
        guard let errorType = error["errorType"] as? ErrorType,
              let errorCode = error["errorCode"] as? Int,
              let errorMessage = error["errorMessage"] as? String else { return }
        let params = ErrorParams(biz: .Messenger,
                                 scene: .Feed,
                                 event: .shortCutAction,
                                 errorType: errorType,
                                 errorLevel: .Exception,
                                 errorCode: errorCode,
                                 userAction: nil,
                                 page: "Feeds",
                                 errorMessage: errorMessage,
                                 extra: extra)
        AppReciableSDK.shared.error(params: params)
    }
}

extension APIError {

    func getInfo() -> [String: Any] {
        var errorType: ErrorType = .Unknown
        switch self.type {
        case .remoteRequestTimeout, .networkIsNotAvailable:
            errorType = .Network
        case .internalRustClientError:
            errorType = .SDK
        default:
            errorType = .Unknown
        }
        let code = Int(self.code)
        let errorMessage = "displayMessage: \(self.displayMessage) + serverMessage: \(self.serverMessage)"

        return ["errorType": errorType,
                "errorCode": code,
                "errorMessage": errorMessage]
    }
}
