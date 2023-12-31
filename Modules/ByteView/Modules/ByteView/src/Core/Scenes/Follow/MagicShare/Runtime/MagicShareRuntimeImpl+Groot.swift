//
//  MagicShareRuntimeImpl+Groot.swift
//  ByteView
//
//  Created by chentao on 2020/4/14.
//

import Foundation
import RxSwift
import ByteViewNetwork

extension MagicShareRuntimeImpl: FollowGrootCellObserver {

    func bindGrootChannel() {
        downVersionObservable
            .subscribe(onNext: { [weak self] (downVersion) in
                guard let `self` = self,
                    let shareID = self.magicShareDocument.shareID else {
                    return
                }
                self.debugLog(message: "rebind groot channel when down version update to:\(downVersion), shareID:\(shareID)")
                self.refreshDisposeBag = DisposeBag()
                self.openGrootChannelIfNeed(initDownVersion: downVersion)
            })
            .disposed(by: disposeBag)
    }

    func didReceiveFollowGrootCells(_ cells: [FollowGrootCell], for channel: GrootChannel) {
        cells.forEach {
            grootCellPayloadsSubject.onNext($0)
        }
    }

    func openGrootChannelIfNeed(initDownVersion: Int32? = nil) {
        guard let shareID = magicShareDocument.shareID else {
            return
        }
        let isPresenter = self.account == self.magicShareDocument.user
        let startOpeningGrootChannelTimeInterval = Date.timeIntervalSinceReferenceDate
        let session = grootSession
        session?.open(version: nil) { [weak self, weak session] result in
            guard let self = self, self.grootSession === session else { return }
            switch result {
            case .success:
                self.grootChannelOpened = true
                MagicShareTracks.trackGrootChannelOpenSuccess(isPresenter: isPresenter ? 1 : 0, shareId: self.magicShareDocument.shareID)
                let duration = Date.timeIntervalSinceReferenceDate - startOpeningGrootChannelTimeInterval
                MagicShareTracks.trackMagicShareGrootChannelOpenSuccess(isPresenter: isPresenter, shareId: shareID, duration: duration)
            case .failure:
                self.grootChannelOpened = false
                MagicShareTracks.trackGrootChannelOpenFailed(isPresenter: isPresenter ? 1 : 0, shareId: self.magicShareDocument.shareID)
            }
        }
    }

    func closeGrootChannelIfNeed() {
        grootChannelOpened = false
        self.grootSession = nil
    }
}
