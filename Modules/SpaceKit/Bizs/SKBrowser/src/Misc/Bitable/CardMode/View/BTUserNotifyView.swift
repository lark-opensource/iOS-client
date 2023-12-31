//
//  BTUserNotifyView.swift
//  SKBrowser
//
//  Created by lizechuang on 2021/9/1.
//

import Foundation
import SKResource
import RxSwift
import RxRelay
import UniverseDesignColor

public class BTUserNotifyView: UIView {
    public private(set) var notifyModeData: BehaviorRelay<BTChatterPanelViewModel.NotifyMode>
    private lazy var selectedIcon: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(selectedIconTapped), for: .touchUpInside)
        return button
    }()

    lazy var titleLabel: UILabel = {
        return UILabel()
    }()

    public init(notifyMode: BTChatterPanelViewModel.NotifyMode) {
        self.notifyModeData = BehaviorRelay<BTChatterPanelViewModel.NotifyMode>(value: notifyMode)
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        if notifyModeData.value == .disabled {
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(6)
                make.left.equalToSuperview().offset(18)
                make.right.equalToSuperview()
            }
            titleLabel.text = BundleI18n.SKResource.Bitable_Reminder_NoNotifWillBeSentInForm
            titleLabel.font = UIFont.systemFont(ofSize: 14)
            titleLabel.textColor = UDColor.textPlaceholder
        } else {
            addSubview(selectedIcon)
            addSubview(titleLabel)
            selectedIcon.snp.makeConstraints { (make) in
                make.centerY.equalTo(titleLabel.snp.centerY)
                make.width.height.equalTo(20)
                make.left.equalToSuperview().offset(18)
            }
            titleLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.left.equalTo(selectedIcon.snp.right).offset(12)
                make.right.equalToSuperview()
            }
            updateDisplayWithNotifyMode(self.notifyModeData.value)
            titleLabel.text = BundleI18n.SKResource.Bitable_Reminder_NotifWillBeSent
            titleLabel.font = UIFont.systemFont(ofSize: 16)
            titleLabel.textColor = UDColor.textTitle
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectedIconTapped))
            self.addGestureRecognizer(tap)
        }
    }

    @objc
    private func selectedIconTapped() {
        let curNotifyMode: BTChatterPanelViewModel.NotifyMode = (self.notifyModeData.value == .enabled(notifies: true)) ? .enabled(notifies: false) : .enabled(notifies: true)
        self.notifyModeData.accept(curNotifyMode)
        updateDisplayWithNotifyMode(self.notifyModeData.value)
    }

    private func updateDisplayWithNotifyMode(_ notifyMode: BTChatterPanelViewModel.NotifyMode) {
        if notifyMode == .disabled || notifyMode == .hidden {
            return
        }
        if notifyMode == .enabled(notifies: true) {
            selectedIcon.setImage(BundleResources.SKResource.Common.Collaborator.Selected, for: .normal)
        } else {
            selectedIcon.setImage(BundleResources.SKResource.Common.Collaborator.Unselected, for: .normal)
        }
    }
}
