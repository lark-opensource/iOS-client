//
//  CalendarHome+Tabbar.swift
//  Calendar
//
//  Created by zhuheng on 2021/3/2.
//

import Foundation
import LarkUIKit
import LarkNavigation
import AnimatedTabBar
import LarkTab
import RxCocoa
import RxSwift

extension CalendarViewController: TabbarItemTapProtocol {
    public func onTabbarItemDoubleTap() {
        onTabbarItemTapped()
    }

    public func onTabbarItemTap(_ isSameTab: Bool) {
        if isSameTab {
            onTabbarItemTapped()
        }
        tabItemDidTapped()
    }
}

extension CalendarViewController: TabRootViewController {
    public var tab: Tab { .calendar }

    /// 首屏数据Ready
    public var firstScreenDataReady: BehaviorRelay<Bool>? {
        dependency.firstScreenDataReady
    }
}

extension CalendarViewController {
    enum StateType { case none }
    func observeTabSwitch() {
        navigationService?.tabDriver.drive(onNext: { [weak self] tab in
            guard let old = tab.oldTab,
                  let new = tab.newTab,
                  let self = self else { return }
            print(old, new)
            switch (old, new) {
            case (.calendar, .calendar): break
            // 切换到calendar
            case (_, .calendar):
                self.feelGoodDisposable?.dispose()
                self.feelGoodDisposable = MainScheduler.instance.scheduleRelative(StateType.none, dueTime: .seconds(10)) { (_) -> Disposable in
                    CalendarTracer.shared.calFeelGood()
                    return Disposables.create()
                }
                self.switcher.rx.selectedEntry.bind { entry in
                    if case .calendar = entry {
                        CalendarTracer.shared.calMainView()
                    }
                }.dispose()
                CalendarTracer.shared.calendarMeetingRoomSwitcherShow()
            // 切出calendar
            case (.calendar, _):
                self.feelGoodDisposable?.dispose()
            default:
                break
            }
        }).disposed(by: disposeBag)
    }
}
