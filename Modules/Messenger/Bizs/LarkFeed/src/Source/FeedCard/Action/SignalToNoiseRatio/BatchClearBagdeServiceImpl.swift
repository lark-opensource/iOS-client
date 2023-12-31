//
//  BatchClearBadgeReciver.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/8/8.
//

import Foundation
import ThreadSafeDataStructure
import RxSwift
import UniverseDesignToast
import LarkOpenFeed

final class BatchClearBagdeServiceImpl: BatchClearBagdeService {
    let pushBatchClearFeedBadges: Observable<PushBatchClearFeedBadge>
    private let disposeBag = DisposeBag()
    private var taskIdSet: SafeAtomic<Set<String>>
    private let context: FeedContextService

    init(pushBatchClearFeedBadges: Observable<PushBatchClearFeedBadge>, context: FeedContextService) {
        self.pushBatchClearFeedBadges = pushBatchClearFeedBadges
        self.context = context
        taskIdSet = [] + .readWriteLock
        setup()
    }

    func addTaskID(taskID: String) {
        taskIdSet.safeWrite { (item) in
            item.insert(taskID)
        }
    }

    private func setup() {
        self.pushBatchClearFeedBadges
            .subscribe(onNext: { [weak self] (pushBatchClearFeedBadge) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.showToast(pushBatchClearFeedBadge: pushBatchClearFeedBadge)
                }
            }).disposed(by: disposeBag)
    }

    private func showToast(pushBatchClearFeedBadge: PushBatchClearFeedBadge) {
        taskIdSet.safeRead { (item) in
            if item.contains(pushBatchClearFeedBadge.taskID) {
                guard let window = self.context.page?.view.window else { return }
                UDToast.showSuccess(with: BundleI18n.LarkFeed.Lark_Core_UnreadDismissed_Toast, on: window)
                FeedContext.log.info("feedlog/clearBadge/successPush taskID: \(pushBatchClearFeedBadge.taskID)")
            } else {
                FeedContext.log.info("feedlog/clearBadge/worryPush taskID: \(pushBatchClearFeedBadge.taskID)")
            }
        }
        self.taskIdSet.safeWrite { (item) in
            item.remove(pushBatchClearFeedBadge.taskID)
        }
    }
}
