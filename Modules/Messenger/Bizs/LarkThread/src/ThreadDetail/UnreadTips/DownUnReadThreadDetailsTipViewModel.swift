//
//  DownUnReadThreadDetailsTipViewModel.swift
//  LarkThread
//
//  Created by zc09v on 2019/3/4.
//

import Foundation
import LarkCore
import LarkModel
import LarkContainer
import RxSwift
import RxCocoa
import LarkMessageCore
import LarkSDKInterface
import RustPB

final class DownUnReadThreadDetailsTipViewModel: BaseUnreadMessagesTipViewModel {
    private var lastReadPosition: Int32 = -1
    private let threadId: String
    private let threadObservable: Observable<RustPB.Basic_V1_Thread?>
    private let updateThreadPublish: PublishSubject<RustPB.Basic_V1_Thread?> = PublishSubject<RustPB.Basic_V1_Thread?>()
    private let threadAPI: ThreadAPI
    private let preloadMessagePosition: Int32
    private let requestCount: Int32
    private let redundancyCount: Int32

    init(
        userResolver: UserResolver,
        threadId: String,
        threadObserver: BehaviorRelay<RustPB.Basic_V1_Thread>,
        lastMessagePosition: Int32,
        requestCount: Int32,
        redundancyCount: Int32,
        threadAPI: ThreadAPI
    ) {
        self.threadId = threadId
        self.threadAPI = threadAPI
        self.requestCount = requestCount
        self.redundancyCount = redundancyCount
        let pushThreadOb: Observable<RustPB.Basic_V1_Thread?> = threadObserver
            .map({ (thread) -> RustPB.Basic_V1_Thread? in
                return thread
            })
        self.threadObservable = Observable.merge([pushThreadOb, updateThreadPublish.asObservable()])
        self.preloadMessagePosition = lastMessagePosition
        super.init(userResolver: userResolver)
        registerPush()
    }

    override func fetchDataWhenLoad() {
        self.preloadThreadMessages(position: preloadMessagePosition).subscribe().disposed(by: self.disposeBag)
    }

    private func registerPush() {
        threadObservable
            .delay(
                .milliseconds(Int(CommonTable.scrollToBottomAnimationDuration * 1000)), scheduler:
                self.dataScheduler)
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (thread) in
                guard let thread = thread else { return }
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
            }).disposed(by: disposeBag)
    }

    public func update(thread: RustPB.Basic_V1_Thread) {
        self.updateThreadPublish.onNext(thread)
    }

    // MARK: - fetch data
    private func preloadThreadMessages(position: Int32) -> Observable<Void> {
        return self.threadAPI.fetchThreadMessages(
            threadId: self.threadId,
            scene: .specifiedPosition(position),
            redundancyCount: self.redundancyCount,
            count: self.requestCount
            ).map({ (_) -> Void in return })
    }
}
