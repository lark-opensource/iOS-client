//
//  DriveCommentManager+Follow.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/4/9.
//  

import Foundation
import RxSwift
import RxCocoa
import SKCommon
import SKFoundation
import SpaceInterface

extension DriveCommentManager: FollowableContent {

    typealias State = DriveCommentFollowState

    // 收到评论 follow 事件
    var commentFollowStateUpdated: Driver<State> {
        return commentFollowStateSubject
            .asDriver(onErrorJustReturn: .default)
    }

    var currentCommentState: State {
        return commentStateRelay.value
    }

    var moduleName: String {
        return State.module
    }

    var isVCFollowing: Bool {
        return followDelegate != nil
    }

    func onSetup(delegate: FollowableContentDelegate) {
        DocsLogger.driveInfo("drive.comment.follow --- setting up follow delegate")
        followDelegate = delegate
        monitorStateChanged()
    }

    private func monitorStateChanged() {
        // 切换评论时，通知 VC 更新
        commentVCSwitchToComment
            .filter { !$0.isEmpty }
            .map { State.expanded(focusedID: $0) }
            .bind { [weak self] state in
                DocsLogger.driveInfo("drive.comment.follow --- commentVCSwitchToComment \(state)")
                self?.commentStateRelay.accept(state)
            }
            .disposed(by: disposeBag)

        // 关闭评论时，通知 VC 更新
        commentVCDismissed
            .bind { [weak self] in
                DocsLogger.driveInfo("drive.comment.follow --- commentVCDismissed")
                self?.commentStateRelay.accept(.collapse)
            }
            .disposed(by: disposeBag)

        // 收到主持人的 FollowState，通知 VC 更新
        commentFollowStateSubject
            .bind(to: commentStateRelay)
            .disposed(by: disposeBag)

        commentStateRelay
            .subscribe(onNext: { [weak self] newState in
                guard let delegate = self?.followDelegate else { return }
                DocsLogger.driveInfo("drive.comment.follow --- follow content state changed: \(newState.followModuleState)")
                delegate.onContentEvent(.stateChanged(newState.followModuleState), at: nil)
            })
            .disposed(by: disposeBag)
    }

    func setState(_ state: FollowModuleState) {
        guard let commentState = State(followModuleState: state) else {
            DocsLogger.error("drive.comment.state --- failed to convert module state to comment state", extraInfo: ["moduleState": state])
            return
        }
        DocsLogger.debug("drive.comment.follow --- receive follow comment state")
        guard verify(state: commentState) else {
            return
        }
        DocsLogger.driveInfo("drive.comment.follow --- setState: \(commentState)")
        commentFollowStateSubject.onNext(commentState)
    }

    private func verify(state: State) -> Bool {
        switch state {
        case .collapse:
            return true
        case .expanded:
            guard commentCount.value > 0 else {
                DocsLogger.driveInfo("drive.comment.follow --- invalid follow comment state, expanding comments while count is 0")
                return false
            }
            return true
        }
    }

    func getState() -> FollowModuleState? {
        return currentCommentState.followModuleState
    }

    func updatePresenterState(_ state: FollowModuleState?) {
        // follow module does not support calculating relative location
    }
}
