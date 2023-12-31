//
//  MagicShareRuntimeImpl+FollowStates.swift
//  ByteView
//
//  Created by chentao on 2020/4/14.
//

import Foundation
import RxSwift
import ByteViewNetwork

extension MagicShareRuntimeImpl {

    func bindFollowStates() {
        grootCellPayloadsSubject.asObservable()
            .map { $0.states }
            .do(onNext: { [weak self] (states: [FollowState]) in
                if !states.isEmpty {
                    self?.cancelFollowerNoValidFollowStatesTimeout()
                }
            }, onError: { [weak self] (error: Error) in
                guard let self = self else {
                    Self.logger.info("grootCellPayloadsSubject onError and self is nil")
                    return
                }
                Self.logger.info("grootCellPayloadsSubject error: \(error)")
                if self.timeIntervalRuntimeInit == nil {
                    self.timeIntervalRuntimeInit = Date().timeIntervalSince1970
                    self.trackOnMagicShareInitFinished(dueTo: .docLoadFail)
                }
            })
            .bind(to: vcFollowStatesSubject.asObserver())
            .disposed(by: disposeBag)

        grootCellPayloadsSubject.asObservable()
            .map { $0.patches }
            .bind(to: vcFollowPatchesSubject.asObserver())
            .disposed(by: disposeBag)

        // 仅当App位于前台且全屏时应用同步数据；由其他状态回到前台且全屏的瞬间应用最新一次的记录数据
        Observable.combineLatest(followStatesObservable,
                                 isApplicationActiveSubject.asObservable(),
                                 isVideoConferenceFloatingSubject.asObservable())
            .filterByCombiningLatest(followDidRenderFinishObservable.filter({ $0 }).take(1))
            .filter { $0.1 && !$0.2 }
            .map { $0.0 }
            .subscribe(onNext: { [weak self] (vcFollowStates) in
                guard let self = self, !self.checkShouldSkipApply() else { return }
                self.applyStatesForStrategies(states: vcFollowStates)
            }, onError: { [weak self] (error: Error) in
                guard let self = self else {
                    Self.logger.info("grootCellPayloadsSubject onError and self is nil")
                    return
                }
                Self.logger.info("followStatesObservable error: \(error)")
                if self.timeIntervalRuntimeInit == nil {
                    self.timeIntervalRuntimeInit = Date().timeIntervalSince1970
                    self.trackOnMagicShareInitFinished(dueTo: .docLoadFail)
                }
            }).disposed(by: disposeBag)

        Observable.combineLatest(followPatchsObservable,
                                 isApplicationActiveSubject.asObservable(),
                                 isVideoConferenceFloatingSubject.asObservable())
            .filterByCombiningLatest(followDidRenderFinishObservable.filter({ $0 }).take(1))
            .filter { $0.1 && !$0.2 }
            .map { $0.0 }
            .subscribe(onNext: { [weak self] (vcFollowPatches) in
                guard let self = self, !self.checkShouldSkipApply() else { return }
                self.applyPatchesForStrategies(patches: vcFollowPatches)
            }).disposed(by: disposeBag)
    }

    /// 检查是否需要跳过数据同步
    private func checkShouldSkipApply() -> Bool {
        switch currentDocumentStatus {
        case .sstomsFree:
            return true
        case .sstomsFollowing:
            if isShareScreenToFollowActionApplied {
                return true
            } else {
                isShareScreenToFollowActionApplied = true
                return false
            }
        default:
            return false
        }
    }

    var followStatesObservable: Observable<[FollowState]> {
        return vcFollowStatesSubject
            .asObservable()
            .filter { !$0.isEmpty }
    }

    var followPatchsObservable: Observable<[FollowPatch]> {
        return vcFollowPatchesSubject
            .asObservable()
            .filter { !$0.isEmpty }
    }

    func applyStatesForStrategies(states: [FollowState]) {
        debugLog(message: "apply states count:\(states.count), when current document status:\(currentDocumentStatus)")
        guard !states.isEmpty, currentDocumentStatus != .sharing else {
            return
        }
        if shouldBlockApplyFollowStates(states) {
            Logger.vcFollow.info("apply follow states skipped due to different sender")
            return
        }
        if timeIntervalRuntimeInit == nil {
            timeIntervalRuntimeInit = Date().timeIntervalSince1970
            // 被共享人收到首个Action时：如果被共享人跟随，上报.success；如果被共享人是自由浏览, 上报.unfollow
            if currentDocumentStatus == .following {
                trackOnMagicShareInitFinished(dueTo: .success)
            } else {
                trackOnMagicShareInitFinished(dueTo: .unfollow)
            }
        }
        let now = Date(timeIntervalSinceNow: 0).timeIntervalSince1970 * 1000
        let uuid = "\(now)"
        magicShareAPI.setStates(states, uuid: uuid)
        magicShareDelegate?.magicShareRuntime(self, onApplyStates: states, uuid: uuid, timestamp: CGFloat(now))
    }

    func applyPatchesForStrategies(patches: [FollowPatch]) {
        debugLog(message: "apply patches count:\(patches.count), when current document status:\(currentDocumentStatus)")
        guard !patches.isEmpty, currentDocumentStatus != .sharing else {
            return
        }
        magicShareAPI.applyPatches(patches)
    }
}

extension MagicShareRuntimeImpl: RouterListener {

    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        isVideoConferenceFloatingSubject.onNext(isFloating)
    }

}

private extension MagicShareRuntimeImpl {

    /// 根据sender判断是否需要丢弃同步数据
    func shouldBlockApplyFollowStates(_ followStates: [FollowState]) -> Bool {
        // sender格式为"-[userId]-[deviceId]"则进入判断
        if var sender = followStates.first?.sender, sender.first == "-" {
            sender.removeFirst()
            let userId = sender.components(separatedBy: "-")[0]
            let deviceId = sender.components(separatedBy: "-")[1]
            if !userId.isEmpty,
               !deviceId.isEmpty,
               (userId != documentInfo.user.id || deviceId != documentInfo.user.deviceId) {
                self.addTotalGrootCellsCount(true, addInvalidCount: true)
                return true
            } else {
                self.addTotalGrootCellsCount(true, addInvalidCount: false)
                return false
            }
        }
        // sender格式不同直接放过
        return false
    }

}
