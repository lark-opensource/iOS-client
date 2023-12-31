//
//  BatchMuteFeedCardsServiceImpl.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/8/8.
//

import Foundation
import ThreadSafeDataStructure
import RxSwift
import UniverseDesignToast
import LarkOpenFeed
import LarkContainer

final class BatchMuteFeedCardsServiceImpl: BatchMuteFeedCardsService, UserResolverWrapper {
    var userResolver: UserResolver { context.userResolver }
    let pushMuteFeedCards: Observable<PushMuteFeedCards>
    private let disposeBag = DisposeBag()
    private var muteTaskIdSet: SafeAtomic<[String: Bool]>
    private var atAllTaskIdSet: SafeAtomic<[String: Bool]>

    private let context: FeedContextService
    @ScopedInjectedLazy private var feedMuteConfigService: FeedMuteConfigService?

    init(pushMuteFeedCards: Observable<PushMuteFeedCards>, context: FeedContextService) {
        self.pushMuteFeedCards = pushMuteFeedCards
        self.context = context
        muteTaskIdSet = [String: Bool]() + .readWriteLock
        atAllTaskIdSet = [String: Bool]() + .readWriteLock
        setup()
    }

    func addTaskID(taskID: String, mute: Bool) {
        muteTaskIdSet.safeWrite { (item) in
            item[taskID] = mute
        }
    }

    func addAtAllTaskID(taskID: String, muteAtAll: Bool) {
        atAllTaskIdSet.safeWrite { (item) in
            item[taskID] = muteAtAll
        }
    }

    private func setup() {
        self.pushMuteFeedCards
            .subscribe(onNext: { [weak self] (pushMuteFeedCards) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.showToast(pushMuteFeedCards: pushMuteFeedCards)
                }
            }).disposed(by: disposeBag)
    }

    private func showToast(pushMuteFeedCards: PushMuteFeedCards) {
        muteTaskIdSet.safeRead { (item) in
            guard let window = self.context.page?.view.window else { return }
            let taskId = pushMuteFeedCards.taskID
            if let mute = item[taskId] {
                let text: String
                if mute {
                    if self.feedMuteConfigService?.getShowMute() == true {
                        text = BundleI18n.LarkFeed.Lark_Core_ChatsMovedToMutedFilter_Toast
                    } else {
                        text = BundleI18n.LarkFeed.Lark_Core_ChatsMuted_Toast
                    }
                } else {
                    text = BundleI18n.LarkFeed.Lark_Core_ChatsUnmuted_Toast
                }
                UDToast.showSuccess(with: text, on: window)
            }
        }
        muteTaskIdSet.safeWrite { (item) in
            item.removeValue(forKey: pushMuteFeedCards.taskID)
        }
    }
}
