//
//  FeedMainViewController+Focus.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/10/10.
//

import Foundation
import RxSwift
import RxCocoa
import LarkNavigation
import AppContainer
import EENavigator
import LarkUIKit
import LarkContainer
import LarkFocus

extension FeedMainViewController {

    func bindFocus() {
        // 监听 Chatter，更新导航栏的个人状态组件
        chatterManager.currentChatterObservable
            .subscribe(onNext: { [weak self] chatter in
                guard let self = self else { return }
                guard self.userResolver.userID == chatter.id else { return }
                self.naviFocusView.configure(with: chatter.focusStatusList)
            }).disposed(by: self.disposeBag)
    }

    func refreshFocusView() {
        naviFocusView.refresh()
    }

    func _didTapNaviFocusStatus() {
        FeedTracker.Navigation.Click.PersonalStatus()

        let focusListVC = FocusListController(userResolver: userResolver)
        navigator.present(focusListVC, from: self)
    }
}
