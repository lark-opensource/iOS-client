//
//  SettingTodoTaskReminderModule.swift
//  Todo
//
//  Created by 白言韬 on 2021/3/10.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer

final class SettingTodoTaskReminderModule: SettingBaseModule {

    override var view: UIView { rootView }

    @ScopedInjectedLazy private var settingService: SettingService?

    private lazy var rootView = UIView()
    private lazy var switchBtnCell = SettingSwitchBtnCell()

    private let rxIsOn = BehaviorRelay<Bool>(value: false)
    private let disposeBag = DisposeBag()

    private var isFirstEnter = true

    override func setup() {
        setupView()

        switchBtnCell.switchBtn.rx.isOn
            .bind(to: rxIsOn)
            .disposed(by: disposeBag)
        rxIsOn.bind { [weak self] isOn in
            guard let self = self else { return }
            guard !self.isFirstEnter else {
                self.isFirstEnter = false
                return
            }
            self.tracker(isOn: isOn)
            self.settingService?.update(isOn, forKeyPath: \.enableDailyRemind) { [weak self] in
                guard let self = self else { return }
                self.settingService?.updateCache(!isOn, forKeyPath: \.enableDailyRemind)
                Utils.Toast.showError(with: I18N.Todo_Task_FailedToSet, on: self.containerContext.viewController?.view ?? UIView())
            }
        }.disposed(by: disposeBag)

        settingService?.observe(forKeyPath: \.enableDailyRemind)
            .observeOn(MainScheduler.asyncInstance)
            .bind { [weak self] isOn in
                self?.switchBtnCell.switchBtn.isOn = isOn
            }.disposed(by: disposeBag)
    }

    private func setupView() {
        guard let settingService = settingService else { return }
        switchBtnCell.setup(
            title: I18N.Todo_Settings_DailyNotification,
            description: I18N.Todo_Task_RecentTodoTaskDesc,
            isOn: settingService.value(forKeyPath: \.enableDailyRemind)
        )
        rootView.addSubview(switchBtnCell)
        switchBtnCell.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
        }
    }

}

// MARK: - Tracker

extension SettingTodoTaskReminderModule {
    private func tracker(isOn: Bool) {
        Setting.Track.clickDailyReminderSetting(isOn: isOn)
    }
}
