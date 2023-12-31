//
//  FeedMainViewController+LarkNaviBarDataSource.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//
import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkNavigation
import AppContainer
import EENavigator
import LarkContainer
import LarkFocus
import LarkSDKInterface
import LarkOpenFeed
import LarkMessengerInterface

///
/// 支持LarkNaviBar的显示
///
extension FeedMainViewController: LarkNaviBarDataSource {
    var isDrawerEnabled: Bool {
        true
    }

    var isNaviBarEnabled: Bool {
        true
    }

    var titleText: BehaviorRelay<String> {
        navigationBarViewModel.titleText
    }

    var isNaviBarLoading: BehaviorRelay<Bool> {
        navigationBarViewModel.isLoading
    }

    var needShowTitleArrow: BehaviorRelay<Bool> {
        navigationBarViewModel.needShowTitleArrow
    }

    var subFilterTitleText: BehaviorRelay<String?> {
        navigationBarViewModel.subFilterTitleText
    }

    func larkNaviBar(imageOfButtonOf type: LarkNaviButtonType) -> UIImage? {
        switch type {
        case .first:
            return Resources.conversation_plus_light
        default:
            return nil
        }
    }

    func userFocusStatusView() -> UIView? {
        return naviFocusView
    }

    var showPad3BarNaviStyle: BehaviorRelay<Bool> {
        navigationBarViewModel.showPad3BarNaviStyle
    }

    var showTabbarFocusStatus: BehaviorRelay<Bool> {
        navigationBarViewModel.showTabbarFocusStatus
    }

    var isDefaultSearchButtonDisabled: Bool {
        return self.mainViewModel.dependency.isDefaultSearchButtonDisabled
    }
}

final class MainTabbarControllerDependencyImpl: MainTabbarControllerDependency, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    // 放在 iPad MainTabbar 展示的个人状态 UI 组件
    lazy var tabbarFocusView: FocusTabbarDisplayView = {
        let view = FocusTabbarDisplayView()
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapNaviFocusStatus)))
        return view
    }()

    let chatterManager: ChatterManagerProtocol
    let showTabbarFocusRelay: BehaviorRelay<Bool>
    let context: FeedContextService
    let disposeBag = DisposeBag()

    init(resolver: UserResolver,
         chatterManager: ChatterManagerProtocol,
         context: FeedContextService) {
        self.userResolver = resolver
        self.chatterManager = chatterManager
        self.context = context
        let showTabFocus = chatterManager.currentChatter.focusStatusList.topActive != nil
        self.showTabbarFocusRelay = BehaviorRelay(value: showTabFocus)
        self.bindFocus()
    }

    func userFocusStatusView() -> UIView? {
        return tabbarFocusView
    }

    @objc
    func didTapNaviFocusStatus() {
        FeedTracker.Navigation.Click.PersonalStatus()

        if let vc = context.page {
            let focusListVC = FocusListController(userResolver: userResolver)
            navigator.present(focusListVC, from: vc)
        }
    }

    func bindFocus() {
        // 监听 Chatter，更新导航栏的个人状态组件
        chatterManager.currentChatterObservable
            .subscribe(onNext: { [weak self] chatter in
                guard let self = self else { return }
                guard self.userResolver.userID == chatter.id else { return }
                self.tabbarFocusView.configure(with: chatter.focusStatusList)
                let showTabFocus = chatter.focusStatusList.topActive != nil
                self.showTabbarFocusRelay.accept(showTabFocus)
            }).disposed(by: self.disposeBag)
        //解决后台切前台个人状态更新问题(chatterManager未及时更新)
        tabbarFocusView.didBecomeActiveRefreshCallBack = { [weak self] (isShowTabFocus) in
            guard let self = self else { return }
            self.showTabbarFocusRelay.accept(isShowTabFocus)
        }
    }

    var showTabbarFocusStatus: Driver<Bool> {
        showTabbarFocusRelay.asDriver()
    }
}
