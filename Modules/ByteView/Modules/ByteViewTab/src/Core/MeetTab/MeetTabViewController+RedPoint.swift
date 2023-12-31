//
//  MeetTabViewController+RedPoint.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import RxSwift

extension MeetTabViewController {
    /// VC-Tab展示列表页面时，App进入后台或杀死App后，清空VC-Tab未读消息计数
    func bindClearVideoConferenceTabUnreadCount() {
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .observeOn(MainScheduler.instance)
            .filter { [weak self] _ in
                return self?.isSelfAppear ?? false
            }
            .subscribe(onNext: { [weak self] _ in
                Self.logger.debug("didEnterBackgroundNotification.onNext, will clear vc tab count")
                self?.clearVideoConferenceTabUnreadCount()
            }, onError: { (error: Error) in
                Self.logger.warn("didEnterBackgroundNotification.onError: \(error)")
            })
            .disposed(by: rx.disposeBag)

        NotificationCenter.default.rx.notification(UIApplication.willTerminateNotification)
            .observeOn(MainScheduler.instance)
            .filter { [weak self] _ in
                self?.isSelfAppear ?? false
            }
            .subscribe(onNext: { [weak self] _ in
                Self.logger.debug("willTerminateNotification.onNext, will clear vc tab count")
                self?.clearVideoConferenceTabUnreadCount()
            }, onError: { (error: Error) in
                Self.logger.warn("willTerminateNotification.onError: \(error)")
            })
            .disposed(by: rx.disposeBag)
    }

    func clearVideoConferenceTabUnreadCount() {
        viewModel.tabViewModel.dependency.badgeService?.clearTabBadge()
    }
}
