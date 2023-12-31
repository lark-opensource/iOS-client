//
//  SettingBadgeModule.swift
//  Todo
//
//  Created by wangwanxin on 2021/6/4.
//

import LarkContainer
import RxSwift
import RxCocoa
import EENavigator

final class SettingBadgeModule: SettingBaseModule {

    override var view: UIView { rootView }

    private lazy var rootView = UIView()
    private lazy var indicatorCell = SettingSubTitleCell()
    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy private var settingService: SettingService?

    override func setup() {
        setupSubview()

        if let config = settingService?.value(forKeyPath: \.listBadgeConfig) {
            updateDetailText(by: config)
        }
        settingService?.observe(forKeyPath: \.listBadgeConfig)
            .distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] badgeConfig in
                guard let self = self else { return }
                self.updateDetailText(by: badgeConfig)
            })
            .disposed(by: disposeBag)
    }

    private func setupSubview() {
        rootView.addSubview(indicatorCell)
        indicatorCell.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
        indicatorCell.setup(
            title: I18N.Todo_Settings_BadgeCountTitle,
            description: nil,
            subTitle: I18N.Todo_Settings_BadgeCountNone) { [weak self] in
            self?.pushBadgeSettingVC()
        }
    }

    private func pushBadgeSettingVC() {
        guard let from = containerContext.viewController else { return }
        Setting.Track.clickBadgeSetting()
        userResolver.navigator.push(BadgeSettingViewController(resolver: userResolver), from: from)
    }

    private func updateDetailText(by badgeConfig: Rust.ListBadgeConfig) {
        var text = I18N.Todo_Settings_BadgeCountNone
        if badgeConfig.enable {
            switch badgeConfig.type {
            case .overdueAndToday:
                text = I18N.Todo_Settings_BadgeCountOverdueAndToday
            case .ownedByMeUnfinished:
                text = I18N.Todo_Settings_BadgeCountOngoingOwned_Option
            @unknown default:
                text = I18N.Todo_Settings_BadgeCountOverdue
            }
        }
        indicatorCell.subTitleLabel.text = text
    }
}
