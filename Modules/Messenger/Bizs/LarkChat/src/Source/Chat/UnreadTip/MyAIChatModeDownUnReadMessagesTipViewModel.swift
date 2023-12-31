//
//  MyAIChatModeDownUnReadMessagesTipViewModel.swift
//  LarkChat
//
//  Created by ByteDance on 2023/6/9.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkContainer
import LarkCore
import LarkMessageCore
import LarkSDKInterface
import RustPB

final class MyAIChatModeDownUnReadMessagesTipViewModel: BaseUnreadMessagesTipViewModel {
    private let threadAPI: ThreadAPI

    private var lastReadPosition: Int32
    private let threadObservable: Observable<PushThreads>
    private let threadId: String
    private let myAIChatModeId: Int64
    private var preloadMessagePosition: Int32?
    init(userResolver: UserResolver,
         threadId: String,
         myAIChatModeId: Int64,
         readPosition: Int32,
         lastMessagePosition: Int32,
         threadAPI: ThreadAPI,
         pushCenter: PushNotificationCenter) {
        self.threadAPI = threadAPI
        self.threadId = threadId
        self.myAIChatModeId = myAIChatModeId
        self.threadObservable = pushCenter.observable(for: PushThreads.self)
        self.preloadMessagePosition = lastMessagePosition
        self.lastReadPosition = readPosition
        super.init(userResolver: userResolver)
        observePush()
    }

    override func fetchDataWhenLoad() {
        if let preloadMessagePosition = self.preloadMessagePosition {
            self.preloadThreadMessages(position: preloadMessagePosition).subscribe().disposed(by: self.disposeBag)
        }
    }

    private func preloadThreadMessages(position: Int32) -> Observable<Void> {
        return self.threadAPI.fetchThreadMessages(
            threadId: threadId,
            scene: .specifiedPosition(position),
            redundancyCount: 0,
            count: 0
            ).map({ (_) -> Void in return }) ?? .error(UserScopeError.disposed)
    }

    private func observePush() {
        threadObservable
            .compactMap({ (push) -> RustPB.Basic_V1_Thread? in
                if let newThread = push.threads.first(where: { $0.aiChatModeID == self.myAIChatModeId }) {
                    return newThread
                }
                return nil
            })
            .delay(
                .milliseconds(Int(CommonTable.scrollToBottomAnimationDuration * 1000)), scheduler:
                self.dataScheduler)
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] thread in
                /// 服务端的逻辑对lastMessagePositionBadgeCount，readPositionBadgeCount的数量处理存在小概率bug
                /// 需要端上加lastMessagePosition - readPosition的最大badge数做兜底(同步PC & 安卓逻辑)
                let badge = min(thread.lastMessagePositionBadgeCount - thread.readPositionBadgeCount,
                                thread.lastMessagePosition - thread.readPosition)
                let readPosition = thread.readPosition
                /// 话题的头部是-1，判断readPost >= -1 是判断当前的值是否为有效值
                if readPosition >= self?.lastReadPosition ?? -1 {
                    self?.lastReadPosition = readPosition
                    if badge > 0 {
                        self?.state.accept(.showUnReadMessages(badge, readPosition))
                    } else {
                        self?.state.accept(.dismiss)
                    }
                }
            }).disposed(by: self.disposeBag)
    }
}
