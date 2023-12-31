//
//  MissedCallReminderSettingViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2022/4/2.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import UniverseDesignColor
import UniverseDesignCheckBox
import ByteViewCommon
import ByteViewUI
import ByteViewTracker

final class MissedCallReminderSettingButtonView: UIView {
    lazy var imageView = UIImageView()
    lazy var label = UILabel()
    lazy var checkBoxView = UDCheckBox()

    override init(frame: CGRect) {
        super.init(frame: frame)

        checkBoxView.isSelected = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center

        addSubview(imageView)
        addSubview(label)
        addSubview(checkBoxView)

        imageView.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.width.equalTo(136)
            $0.height.equalTo(230)
        }

        label.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(imageView)
            $0.bottom.equalTo(checkBoxView.snp.top).offset(-6)
        }

        checkBoxView.snp.makeConstraints {
            $0.top.equalTo(label.snp.bottom).offset(6.0)
            $0.width.height.equalTo(20.0)
            $0.bottom.centerX.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MissedCallReminderSettingViewController: BaseViewController {

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.clipsToBounds = true
        view.layer.cornerRadius = 10
        return view
    }()

    lazy var leftZone: UIView = {
        let view = UIView()
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(clickLeftZone))
        view.addGestureRecognizer(tapGesture)
        return view
    }()

    lazy var rightZone: UIView = {
        let view = UIView()
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(clickRightZone))
        view.addGestureRecognizer(tapGesture)
        return view
    }()

    lazy var botButtonView: MissedCallReminderSettingButtonView = {
        let view = MissedCallReminderSettingButtonView()
        view.imageView.image = BundleResources.ByteViewSetting.Settings.bot_reminder
        view.label.attributedText = .init(string: I18n.View_MV_UnanswerMeetingBotNote, config: .bodyAssist, alignment: .center)
        return view
    }()

    lazy var potButtonView: MissedCallReminderSettingButtonView = {
        let view = MissedCallReminderSettingButtonView()
        view.imageView.image = BundleResources.ByteViewSetting.Settings.red_pot_reminder
        view.label.attributedText = .init(string: I18n.View_MV_Unanswer_MenuRedDot, config: .bodyAssist, alignment: .center)
        return view
    }()

    let viewModel: MissedCallReminderSettingViewModel
    init(service: UserSettingManager) {
        self.viewModel = MissedCallReminderSettingViewModel(service: service)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        VCTracker.post(name: .setting_meeting_missed_call_view)

        title = I18n.View_MV_UnanswerMeetingNotice
        view.backgroundColor = UIColor.ud.bgFloatBase

        view.addSubview(containerView)
        containerView.addSubview(leftZone)
        containerView.addSubview(rightZone)

        leftZone.addSubview(botButtonView)
        rightZone.addSubview(potButtonView)

        containerView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview().inset(16.0)
            $0.bottom.lessThanOrEqualToSuperview()
        }

        leftZone.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview()
            $0.width.equalTo(containerView).multipliedBy(0.5)
        }

        rightZone.snp.makeConstraints {
            $0.right.top.bottom.equalToSuperview()
            $0.width.equalTo(containerView).multipliedBy(0.5)
        }

        botButtonView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(30.0)
            $0.left.equalToSuperview().inset(24.0)
            $0.bottom.equalToSuperview().inset(30.0)
            $0.right.equalToSuperview().inset(11.0)
        }

        potButtonView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(30.0)
            $0.left.equalToSuperview().inset(11.0)
            $0.bottom.equalToSuperview().inset(30.0)
            $0.right.equalToSuperview().inset(24.0)
        }

        updateUI()
        viewModel.bindAction { [weak self] in
            self?.updateUI()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarBgColor(UIColor.ud.bgFloatBase)
    }

    func updateUI() {
        var bSelected = false
        var pSelected = false
        if viewModel.missedCallReminder.reminder == .bot {
            bSelected = true
        } else if viewModel.missedCallReminder.reminder == .redPoint {
            pSelected = true
        }
        Util.runInMainThread { [weak self] in
            self?.botButtonView.checkBoxView.isSelected = bSelected
            self?.potButtonView.checkBoxView.isSelected = pSelected
        }
    }

    @objc func clickLeftZone() {
        viewModel.updateSetting(.bot)
        updateUI()
    }

    @objc func clickRightZone() {
        viewModel.updateSetting(.redPoint)
        updateUI()
    }
}
