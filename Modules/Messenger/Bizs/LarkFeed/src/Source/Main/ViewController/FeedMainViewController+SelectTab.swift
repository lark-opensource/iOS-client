//
//  FeedMainViewController+SelectTab.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/29.
//

import Foundation
import SnapKit
import RxDataSources
import RxSwift
import RxCocoa
import LarkNavigation
import AnimatedTabBar
import LKCommonsLogging
import RunloopTools
import LarkSDKInterface
import RustPB
import AppContainer
import LarkPerf
import LarkMessengerInterface
import EENavigator
import LarkKeyCommandKit
import LarkUIKit
import UniverseDesignTabs
import LarkFoundation
import Heimdallr
import AppReciableSDK
import LarkAccountInterface

// MARK: 创建及基本布局
extension FeedMainViewController {

    func observSelectFeedTab() {
        mainViewModel.dependency.selectFeedObservable
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] info in
                guard let self = self else { return }
                self.handleInfo(info: info)
            }).disposed(by: disposeBag)
    }

    func handleInfo(info: FeedSelection?) {
        guard let theInfo = info, theInfo.filterTabType == .team else { return }
        changeTabWithFilterSelectItem(.team)
    }
}
