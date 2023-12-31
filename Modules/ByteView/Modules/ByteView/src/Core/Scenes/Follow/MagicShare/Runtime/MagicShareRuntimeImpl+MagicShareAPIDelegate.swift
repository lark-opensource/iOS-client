//
//  MagicShareRuntimeImpl+MagicShareAPIDelegate.swift
//  ByteView
//
//  Created by chentao on 2020/4/20.
//

import Foundation
import RxSwift
import ByteViewNetwork

extension MagicShareRuntimeImpl: MagicShareAPIDelegate {

    func bindUserOperation() {
        userOperationSubject.asObservable()
            .throttle(.microseconds(500), latest: false, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (operation) in
                guard let `self` = self else {
                    return
                }
                self.magicShareDelegate?.magicShareRuntime(self, onOperation: operation)
                self.documentChangeDelegate?.magicShareRuntime(self, didDocumentChange: operation)
            })
            .disposed(by: disposeBag)
    }

    func magicShareAPIDidReady(_ magicShareAPI: MagicShareAPI) {
        // 保护renderFinish成功的回调多次的情况
        if followDidRenderFinishRelay.value == false {
            followDidRenderFinishRelay.accept(true)
            timeIntervalDocCreate = Date().timeIntervalSince1970
            magicShareDelegate?.magicShareRuntimeDidReady(self)
            let distance = Date().timeIntervalSince1970 - timeIntervalWhenOpened
            var isPresenter = false
            switch currentDocumentStatus {
            case .sharing:
                isPresenter = true
            default:
                break
            }
            // 加载成功
            trackOnWebViewLoadingSuccess()
            MagicShareTracks.trackDocumentDidReady(duration: Int64(distance * 1000),
                                                   subType: magicShareDocument.shareSubType.rawValue,
                                                   followType: magicShareDocument.shareType.rawValue,
                                                   isPresenter: isPresenter ? 1 : 0,
                                                   shareId: magicShareDocument.shareID,
                                                   token: magicShareDocument.token)
            debugLog(message: "did ready")
        }
    }

    func magicShareAPIDidFinish(_ magicShareAPI: MagicShareAPI) {
        timeIntervalJSSdkReady = Date().timeIntervalSince1970
        let distance = Date().timeIntervalSince1970 - timeIntervalWhenOpened
        var isPresenter = false
        switch currentDocumentStatus {
        case .sharing:
            isPresenter = true
        default:
            break
        }
        MagicShareTracks.trackDocumentDidRenderFinish(duration: Int64(distance * 1000),
                                                      subType: magicShareDocument.shareSubType.rawValue,
                                                      followType: magicShareDocument.shareType.rawValue,
                                                      isPresenter: isPresenter ? 1 : 0,
                                                      shareId: magicShareDocument.shareID,
                                                      token: magicShareDocument.token)
        debugLog(message: "did finish")

    }

    func magicShareAPI(_ magicShareAPI: MagicShareAPI, onStates states: [FollowState], grootAction: GrootCell.Action, createTime: TimeInterval) {
        // 共享人由于触发文档变化而发出第一个Action时，上报.success
        if timeIntervalRuntimeInit == nil {
            timeIntervalRuntimeInit = Date().timeIntervalSince1970
            trackOnMagicShareInitFinished(dueTo: .success)
        }
        debugLog(message: "send follow states")
        addTimeCostData(Date().timeIntervalSince1970 - createTime)
        sendGrootCell(FollowGrootCell(states: states), action: grootAction)
        if !states.isEmpty {
            cancelPresenterNoValidFollowStatesTimeout()
        }
    }

    func magicShareAPI(_ magicShareAPI: MagicShareAPI, onPatches patches: [FollowPatch], grootAction: GrootCell.Action) {
        sendGrootCell(FollowGrootCell(patches: patches), action: grootAction)
    }

    func magicShareAPI(_ magicShareAPI: MagicShareAPI, onJSInvoke invocation: [String: Any]) {
    }

    func magicShareAPI(_ magicShareAPI: MagicShareAPI, onOperation operation: MagicShareOperation) {
        userOperationSubject.onNext(operation)
    }

    func magicShareAPI(_ magicShareAPI: MagicShareAPI, onPresenterFollowerLocationChange location: MagicSharePresenterFollowerLocation) {
        // 文档加载ready且当前为自由浏览时，上抛数据
        guard followDidRenderFinishRelay.value && isFree else {
            return
        }
        magicShareDelegate?.magicShareRuntime(self, onPresenterFollowerLocationChange: location)
    }

    func magicShareAPI(_ magicShareAPI: MagicShareAPI, onRelativePositionChange position: MagicShareRelativePosition) {
        // 文档加载ready且当前为自由浏览时，上抛数据
        guard followDidRenderFinishRelay.value && isFree else {
            return
        }
        magicShareDelegate?.magicShareRuntime(self, onRelativePositionChange: position)
    }

    func magicShareAPI(_ magicShareAPI: MagicShareAPI, onTrack info: String) {
        DispatchQueue.global().async {
            MagicShareTracksV2.trackWithPassThroughWebTrackInfo(info)
        }
    }

    func magicShareAPIDidFirstPositionChangeAfterFollow(_ magicShareAPI: MagicShareAPI) {
        if shouldUploadOnFirstPositionChange { // 仅当Runtime新建 or ShareID有变化时，标签重置，回调并触发埋点上报
            shouldUploadOnFirstPositionChange = false
            magicShareDelegate?.magicShareRuntime(self, onFirstPositionChangeAfterFollow: self.timeIntervalDocCreate)
        }
    }

    func magicShareInfoDidChanged(_ magicShareAPI: MagicShareAPI, states: [String]) {
        guard self.account == self.magicShareDocument.user else { return }
        guard let data = states.last?.data(using: .utf8),
              let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            Logger.vcFollow.warn("on .magicShareInfo event, data is invalid, magicShareInfo skipped.")
            return
        }
        let eventType = jsonObj["eventType"] as? Int ?? 0
        let timestamp = jsonObj["timestamp"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
        let objToken = jsonObj["objToken"] as? String ?? ""
        let info = jsonObj["info"] as? [String: Any] ?? [:]
        let infoData = (try? JSONSerialization.data(withJSONObject: info)) ?? Data()
        let infoString = String(data: infoData, encoding: .utf8)

        httpClient.follow.postMagicShareInfo(eventType: eventType, meetingId: meetingId, objToken: objToken, timestamp: timestamp, shareId: magicShareDocument.shareID, info: infoString)
    }

}
