//
//  FollowContainerViewController+Gesture.swift
//  ByteView
//
//  Created by liurundong.henry on 2020/4/17.
//

import Foundation
import RxSwift
import RxCocoa

extension FollowContainerViewController {

    func bindHitDetectView() {
        hitDetectView.isHidden = true

        hitDetectView.hitSubject
            .subscribe(onNext: { [weak self] _ in
                self?.changeToFreeIfNeeded()
            }).disposed(by: rx.disposeBag)

        viewModel.status
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (status: InMeetFollowViewModelStatus) in
                switch status {
                case .following, .shareScreenToFollow:
                    self?.hitDetectView.isHidden = false
                default:
                    self?.hitDetectView.isHidden = true
                }
            })
            .disposed(by: rx.disposeBag)
    }

    func changeToFreeIfNeeded() {
        if viewModel.manager.status.isFollowing() {
            viewModel.toViewOnMyOwnAction.execute()
        } else if viewModel.manager.status == .shareScreenToFollow {
            viewModel.manager.currentRuntime?.stopSSToMS()
            hitDetectView.isHidden = true
        }
    }

}
