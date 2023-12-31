//
//  LocalRefreshService.swift
//  Calendar
//
//  Created by zhuheng on 2021/6/3.
//

import Foundation
import RxSwift

final class LocalRefreshService {
    /// 视图页刷新通知（红线 + 过去日程蒙白）。迁移之前通知的写法，后续重构可干掉
    let rxMainViewNeedRefresh: PublishSubject<Void> = .init()
    /// 日历变更内部通知，作为SDK逻辑的兜底。迁移之前耦合在rustPush的写法，后续重构可干掉
    let rxCalendarNeedRefresh: PublishSubject<Void> = .init()
    /// 日程变更内部通知，作为SDK逻辑的兜底。迁移之前耦合在rustPush的写法，后续重构可干掉
    let rxEventNeedRefresh: PublishSubject<Void> = .init()
    /// 日历详情页->日程详情页中，日历详情页需要监听日程详情页对这个日程发生的变化，以此来把日历详情页删掉（之后接入完整push后，这个操作可以删除）
    let rxCalendarDetailDismiss: PublishSubject<Void> = .init()
    
    /// 如果读系统本地日程被 block 过，重新读
    func reloadIfReadLocalBlocked() {
        if LocalCalendarManager.hasBlockedLoad {
            rxEventNeedRefresh.onNext(())
        }
    }
}
