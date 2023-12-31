//
//  ZoomIdentityAuthenticationViewController.swift
//  Calendar
//
//  Created by pluto on 2022/10/31.
//

import UIKit
import Foundation
import LarkContainer
import UniverseDesignToast
import LarkAlertController
import UniverseDesignColor
import UniverseDesignInput
import RxCocoa
import RxSwift
import FigmaKit
import LarkUIKit

final class ZoomIdentityAuthenticationViewController: BaseUIViewController {

    var onSaveAuthenticationCallBack: ((Server.ZoomMeetingSettings.Authentication) -> Void)?
    private lazy var identitySwitchCell: SettingView = {
        let view = SettingView(switchSelector: #selector(tapVerifySwitch),
                               target: self,
                               title: I18n.Calendar_Zoom_OnlyWithVerifyJoin, lockedMsgToastCallBack: { [weak self]  in
            guard let self = self else { return }
            UDToast.showTips(with: I18n.Calendar_Zoom_LockedByAdmin, on: self.view)
        })
        return view
    }()

    private lazy var settingHeaderView: ZoomCommonSettingHeaderView = {
        let view = ZoomCommonSettingHeaderView()
        view.backgroundColor = .clear
        view.configHeaderTitle(title: I18n.Calendar_Zoom_SelectAuthentication)
        view.isHidden = true
        return view
    }()

    private lazy var divideView = EventBasicDivideView()

    private let pickerView: ZoomCommonListPickerView
    private var authenticationInfo: Server.ZoomMeetingSettings.Authentication
    private var pickedList: [String] = []
    private var pickedKeyList: [String] = []

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }

    init (authenticationInfo: Server.ZoomMeetingSettings.Authentication) {
        pickedList = authenticationInfo.options.map { $0.value }
        pickedKeyList = authenticationInfo.options.map { $0.key }
        let pickedPos: Int = pickedKeyList.firstIndex(of: authenticationInfo.selectedOption) ?? 0
        pickerView = ZoomCommonListPickerView(picked: pickedPos, pickerList: pickedList)
        self.authenticationInfo = authenticationInfo

        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground
        initStatus(isOn: authenticationInfo.optionButton.selected)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = I18n.Calendar_Zoom_AuthenticationTitle
        addBackItem()

        layoutIdentitySwitchCell()
        layoutSelecterTable()
    }

    // 侧滑返回
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        authenticationInfo.optionButton.selected = !pickerView.isHidden
        onSaveAuthenticationCallBack?(authenticationInfo)
        self.navigationController?.popViewController(animated: true)
        return true
    }

    // 按钮返回
    override func backItemTapped() {
        authenticationInfo.optionButton.selected = !pickerView.isHidden
        onSaveAuthenticationCallBack?(authenticationInfo)
        self.navigationController?.popViewController(animated: true)
    }

    private func layoutIdentitySwitchCell() {
        view.addSubview(identitySwitchCell)
        view.addSubview(divideView)
        identitySwitchCell.isLocked = !authenticationInfo.optionButton.editable

        identitySwitchCell.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(48)
            make.top.equalToSuperview().inset(14)
        }
        divideView.snp.makeConstraints { make in
            make.top.equalTo(identitySwitchCell.snp.bottom)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }

    private func layoutSelecterTable() {
        view.addSubview(settingHeaderView)
        view.addSubview(pickerView)

        settingHeaderView.snp.makeConstraints { make in
            make.top.equalTo(divideView.snp.bottom)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }

        pickerView.snp.makeConstraints { make in
            make.top.equalTo(settingHeaderView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        pickerView.didSelectCallBack = { [weak self] picked in
            guard let self = self else { return }
            self.authenticationInfo.selectedOption = self.pickedKeyList[picked]
        }
    }

    private func initStatus(isOn: Bool) {
        identitySwitchCell.update(switchIsOn: isOn)
        settingHeaderView.isHidden = !isOn
        pickerView.isHidden = !isOn
        divideView.isHidden = !isOn
    }

    @objc
    private func tapVerifySwitch(sender: UISwitch) {
        identitySwitchCell.update(switchIsOn: sender.isOn)
        divideView.isHidden = !sender.isOn
        settingHeaderView.isHidden = !sender.isOn
        pickerView.isHidden = !sender.isOn
    }
}
