//
//  MagicShareRuntimeImpl+Track.swift
//  ByteView
//
//  Created by liurundong.henry on 2020/11/4.
//

import Foundation
import ByteViewTracker

extension MagicShareRuntimeImpl {

    /// 文档加载结束时埋点。如果skippedDocumentShareID非空，强制上报一次，且ShareID使用skippedDocumentShareID
    /// 参考：https://bytedance.feishu.cn/docs/doccna36Aup1dOWWWY3zMh9Ob1f
    /// - Parameters:
    ///   - finishReason: 加载结束的原因
    ///   - skippedDocumentShareID: 上报时使用的ShareID
    func trackOnMagicShareInitFinished(dueTo finishReason: MagicShareInitFinishedReason, forceUpdateWith skippedDocumentShareID: String? = nil) {
        guard let currentShareID = magicShareDocument.shareID else {
            Self.logger.info("shareID is nil, tracking on MS document init finished failed, finishReason: \(finishReason.desString)")
            return
        }
        guard isReadyForInitTrack || skippedDocumentShareID != nil else {
            Self.logger.info("isReadyForInitTrack is false && skippedDocumentShareID is nil, tracking on MS document init finished failed, finishReason: \(finishReason.desString)")
            return
        }
        isReadyForInitTrack = false
        MagicShareTracks.trackMagicShareInitFinished(isPresenter: currentDocumentStatus == .sharing,
                                                     finishReason: finishReason,
                                                     createSource: createSource,
                                                     shareId: skippedDocumentShareID ?? currentShareID,
                                                     docCreateTime: timeIntervalDocCreate - timeIntervalWhenOpened,
                                                     jssdkReadyTime: timeIntervalJSSdkReady - timeIntervalWhenOpened,
                                                     injectStrategiesTime: timeIntervalInjectStrategies - timeIntervalWhenOpened,
                                                     runtimeInitTime: Date().timeIntervalSince1970 - timeIntervalWhenOpened)
    }

    func trackOnWebViewStartLoading() {
        guard let shareID = magicShareDocument.shareID else {
            return
        }
        var isPresenter = magicShareDocument.user.identifier == account.identifier
        timeIntervalWebViewStartLoading = Date().timeIntervalSince1970
        MagicShareTracks.trackMagicShareWebViewLoadingStart(isPresenter: isPresenter, shareId: shareID)
    }

    func trackOnWebViewLoadingSuccess() {
        guard let shareID = magicShareDocument.shareID else {
            return
        }
        var isPresenter = magicShareDocument.user.identifier == account.identifier
        MagicShareTracks.trackMagicShareWebViewLoadingSuccess(
            isPresenter: isPresenter,
            duration: Date().timeIntervalSince1970 - timeIntervalWebViewStartLoading,
            shareId: shareID,
            retryTimes: 0)
    }

    func trackMagicShareStatus() {
        guard let shareID = magicShareDocument.shareID else {
            return
        }
        var isPresenter = magicShareDocument.user.identifier == account.identifier
        MagicShareTracks.trackMagicShareStatus(
            strategy: magicShareDocument.strategies.first?.id ?? "default_ccm",
            isPresenter: isPresenter,
            timeCost: followStatesTimeCost,
            shareId: shareID)
    }

    func addTimeCostData(_ timeCost: Double) {
        followStatesTimeCost.append(timeCost)
    }

}

// MARK: - Warning Tracks

extension MagicShareRuntimeImpl {

    /// 当前文档的共享ID
    private var shareID: String {
        magicShareDocument.shareID ?? ""
    }

    /// “didReady未回调”事件
    private static let msMissDidReadyEvent = DevTrackEvent.warning(.ms_miss_did_ready).category(.magic_share)

    /// “共享人未收到有效FollowStates”事件
    private static let msPresenterNoValidFollowStatesEvent = DevTrackEvent.warning(.ms_presenter_no_valid_follow_states).category(.magic_share)

    /// “跟随者未收到有效FollowStates”事件
    private static let msFollowerNoValidFollowStatesEvent = DevTrackEvent.warning(.ms_follower_no_valid_follow_states).category(.magic_share)

    /// 开始“didReady未回调”报警监控，Runtime加载完成或析构时取消，如20秒未收到取消则上报报警埋点
    func startDidReadyTimeout() {
        DevTracker.timeout(event: Self.msMissDidReadyEvent, interval: .seconds(20), key: shareID)
    }

    /// 取消“didReady未回调”报警监控
    func cancelDidReadyTimeout() {
        DevTracker.cancelTimeout(Self.msMissDidReadyEvent.action, key: shareID)
    }

    /// 开始“共享人未收到有效FollowStates”报警监控，共享状态变化或者发出有效[FollowState]数据时取消，如10秒未收到取消则上报报警埋点
    func startPresenterNoValidFollowStatesTimeout() {
        DevTracker.timeout(event: Self.msPresenterNoValidFollowStatesEvent, interval: .seconds(10), key: shareID)
    }

    /// 取消“共享人未收到有效FollowStates”回调报警监控
    func cancelPresenterNoValidFollowStatesTimeout() {
        DevTracker.cancelTimeout(Self.msPresenterNoValidFollowStatesEvent.action, key: shareID)
    }

    /// 开始“跟随者未收到有效FollowStates”回调报警监控，跟随状态变化或者收到有效[FollowState]数据时取消，如20秒未收到取消则上报报警埋点
    func startFollowerNoValidFollowStatesTimeout() {
        DevTracker.timeout(event: Self.msFollowerNoValidFollowStatesEvent, interval: .seconds(20), key: shareID)
    }

    /// 取消“跟随者未收到有效FollowStates”回调报警监控
    func cancelFollowerNoValidFollowStatesTimeout() {
        DevTracker.cancelTimeout(Self.msFollowerNoValidFollowStatesEvent.action, key: shareID)
    }

    /// 取消全部已发起的妙享相关的报警监控
    func cancelAllMagicShareTimeouts() {
        cancelDidReadyTimeout()
        cancelPresenterNoValidFollowStatesTimeout()
        cancelFollowerNoValidFollowStatesTimeout()
    }

}
