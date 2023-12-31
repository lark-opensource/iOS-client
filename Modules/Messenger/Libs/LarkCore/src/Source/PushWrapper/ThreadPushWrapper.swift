//
//  ThreadPushWrapper.swift
//  LarkCore
//
//  Created by liuwanlin on 2019/2/26.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkSDKInterface
import RustPB
import LarkContainer
import LKCommonsLogging

public protocol ThreadPushWrapper {
    var thread: BehaviorRelay<RustPB.Basic_V1_Thread> { get }
}

final class ThreadPushWrapperImpl: ThreadPushWrapper, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(ThreadPushWrapperImpl.self, category: "ThreadPushWrapper")
    let thread: BehaviorRelay<RustPB.Basic_V1_Thread>
    @ScopedInjectedLazy private var threadAPI: ThreadAPI?
    private let lock = NSLock()
    private let disposeBag = DisposeBag()
    /// 是否是从普通群聊消息上创建的话题
    private let forNormalChatMessage: Bool

    init(userResolver: UserResolver,
         thread: RustPB.Basic_V1_Thread,
         pushCenter: PushNotificationCenter,
         chat: Chat,
         forNormalChatMessage: Bool) {
        self.userResolver = userResolver
        let threadId = thread.id
        self.thread = BehaviorRelay<RustPB.Basic_V1_Thread>(value: thread)
        self.forNormalChatMessage = forNormalChatMessage
        pushCenter.observable(for: PushThreads.self).subscribe(onNext: { [weak self] (push) in
            if let newThread = push.threads.first(where: { $0.id == threadId }) {
                if self?.canUpdate(newThread) ?? false {
                    self?.thread.accept(newThread)
                }
            }
        })
        .disposed(by: disposeBag)
        if chat.isSuper {
            self.threadAPI?.fetchThreads([thread.id], strategy: .forceServer, forNormalChatMessage: forNormalChatMessage)
                .subscribe(onNext: { [weak self] (result) in
                    if let threadMessage = result.threadMessages.first {
                        let thread = threadMessage.thread
                        if self?.canUpdate(thread) ?? false {
                            pushCenter.post(PushThreads(threads: [thread]))
                            pushCenter.post(PushThreadMessages(messages: [threadMessage]))
                        }
                    } else {
                        Self.logger.error("chatTrace threadDetail superChat fetchChat nil \(thread.id)")
                    }
                }, onError: { error in
                    Self.logger.error("chatTrace threadDetail superChat fetchChat fail \(thread.id)", error: error)
                }).disposed(by: self.disposeBag)
        }
    }

    private func canUpdate(_ thread: RustPB.Basic_V1_Thread) -> Bool {
        lock.lock()
        let currentThread = self.thread.value
        let result = thread.lastMessagePosition >= currentThread.lastMessagePosition
        lock.unlock()
        return result
    }
}
