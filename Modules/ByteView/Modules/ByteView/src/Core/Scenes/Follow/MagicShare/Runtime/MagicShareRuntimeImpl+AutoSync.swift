//
//  MagicShareRuntimeImpl+AutoSync.swift
//  ByteView
//
//  Created by chentao on 2020/4/16.
//

import Foundation
import RxSwift
import ByteViewNetwork

extension MagicShareRuntimeImpl {

    func bindAutoSync() {
        let autoSyncTimeInterval = self.autoSyncTimeInterval
        logic.stateObservable
            .flatMapLatest { [weak self] (status) -> Observable<([FollowState], String?, TimeInterval)> in
                guard let `self` = self, status == .sharing else {
                    return .empty()
                }
                let timerWhenReady = Observable<Int>
                    .interval(.seconds(autoSyncTimeInterval), scheduler: MainScheduler.instance)
                return timerWhenReady
                    .flatMap { [weak self] (_) -> Observable<([FollowState], String?, TimeInterval)> in
                        guard let `self` = self else {
                            Logger.vcFollow.warn("autoSync generate follow states skipped, due to MagicShareRuntimeImpl is nil")
                            return .empty()
                        }
                        let subject = PublishSubject<([FollowState], String?, TimeInterval)>()
                        self.magicShareAPI.getState { (arr, metaJson) in
                            subject.onNext((arr, metaJson, Date().timeIntervalSince1970))
                        }
                        return subject.asObservable()
                }
        }.subscribe(onNext: { [weak self] (vcFollowStates, _, generateTime) in
            guard let `self` = self else {
                Logger.vcFollow.warn("autoSync sync follow states failed, due to MagicShareRuntimeImpl is nil")
                return
            }
            self.debugLog(message: "sync states count:\(vcFollowStates.count) on timer")
            // 共享人通过每2秒的同步机制发出第一个Action时，上报.success
            if self.timeIntervalRuntimeInit == nil {
                self.timeIntervalRuntimeInit = Date().timeIntervalSince1970
                self.trackOnMagicShareInitFinished(dueTo: .success)
            }
            self.addTimeCostData(Date().timeIntervalSince1970 - generateTime)
            self.sendGrootCell(FollowGrootCell(states: vcFollowStates), action: .trigger)
            if !vcFollowStates.isEmpty {
                self.cancelPresenterNoValidFollowStatesTimeout()
            }
        }).disposed(by: disposeBag)
    }
}
