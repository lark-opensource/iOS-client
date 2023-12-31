//
//  BaseFeedsViewModel+Bind.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/24.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LarkSDKInterface
import RustPB
import UniverseDesignToast
import ThreadSafeDataStructure
import RunloopTools
import LKCommonsLogging
import LarkPerf
import LarkModel
import AppReciableSDK

extension BaseFeedsViewModel {
    func subscribeEventHandlers() {
        baseDependency.badgeStyleObservable
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                self?.handleBadgeStyle()
            }).disposed(by: disposeBag)

        baseDependency.pushThreadFeedAvatarChanges.subscribe(onNext: { [weak self] changes in
            self?.handleThreadAvatarChangePush(by: changes.avatars)
        }).disposed(by: disposeBag)

        baseDependency.is24HourTime.distinctUntilChanged().asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.handleIs24HourTime()
            }).disposed(by: disposeBag)
    }

    /// BadgeStyle变更
    func _handleBadgeStyle() {
        commit { [weak self] in
            guard let self = self else { return }
            // 更新数据源
            self.provider.updateFeedWhenBadgeStyleChange()
            // 触发一次reload
            let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .badgeStyle)
            self.fireRefresh(renderType: .reload, trace: trace)
        }
    }

    // 响应话题更换头像事件
    func handleThreadAvatarChangePush(by avatars: [String: Feed_V1_PushThreadFeedAvatarChanges.Avatar]) {
        // 只有此处用到头像更新, 故没有把逻辑抽出, 直接在这里向队列加操作
        commit { [weak self] in
            guard let self = self, !avatars.isEmpty else { return }
            // 更新数据源头像字段
            self.provider.updateThreadAvatars(avatars)
            // 触发一次reload
            let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .threadAvatar)
            self.fireRefresh(renderType: .reload, trace: trace)
        }
        FeedContext.log.info("feedlog/dataStream/handleThreadAvatarChangePush. avatars.count: \(avatars.count)")
    }

    // is24HourTime: 直接触发一次table的reload
    func handleIs24HourTime() {
        FeedContext.log.info("feedlog/dataStream/handleIs24HourTime")
        let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .handleIs24HourTime)
        self.updateFeeds([], renderType: .reload, trace: trace)
    }
}
