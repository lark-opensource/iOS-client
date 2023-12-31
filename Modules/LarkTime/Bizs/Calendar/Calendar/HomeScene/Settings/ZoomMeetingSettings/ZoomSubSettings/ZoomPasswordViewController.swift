//
//  ZoomPasswordViewController.swift
//  Calendar
//
//  Created by pluto on 2022/10/28.
//

import UIKit
import Foundation
import LarkContainer
import UniverseDesignToast
import LarkAlertController
import UniverseDesignColor
import UniverseDesignInput
import EditTextView
import RxCocoa
import RxSwift
import FigmaKit
import LarkUIKit

final class ZoomPasswordViewController: BaseUIViewController, UITextViewDelegate {

    var onSavePassCode: ((_ passCodeInfo: Server.ZoomSetting.Password) -> Void)?
    let disposeBag = DisposeBag()
    let originalPassCode: String
    var hasBringInError: Bool = false

    private var passCodeInfo: Server.ZoomSetting.Password
    private lazy var passCodeSwitchCell: SettingView = {
        let view = SettingView(switchSelector: #selector(tapPasswordSwitch),
                               target: self,
                               title: I18n.Calendar_Zoom_CodeRequired, lockedMsgToastCallBack: { [weak self]  in
            guard let self = self else { return }
            UDToast.showTips(with: I18n.Calendar_Zoom_LockedByAdmin, on: self.view)
        })
        return view
    }()

    private lazy var inputBlock: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var inputHeaderView: ZoomCommonSettingHeaderView = {
        let view = ZoomCommonSettingHeaderView()
        view.backgroundColor = .clear
        view.configHeaderTitle(title: I18n.Calendar_Zoom_Passcode)
        return view
    }()

    private lazy var passInputCell: ZoomCommonUITextField = {
        let inputView = ZoomCommonUITextField()
        inputView.rightView = nil
        inputView.font = UIFont.systemFont(ofSize: 16)
        inputView.backgroundColor = UIColor.ud.bgFiller
        inputView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        inputView.attributedPlaceholder = NSAttributedString(string: I18n.Calendar_Ex_PleaseEnter, attributes: [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: UIColor.ud.textCaption])
        inputView.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        return inputView
    }()

    private lazy var errorTips: UILabel = {
        let label = UILabel()
        label.text = I18n.Calendar_Zoom_CodeNoEmpty
        label.textColor = UIColor.ud.functionDangerContentDefault
        label.font = UIFont.systemFont(ofSize: 14)
        label.isHidden = true
        return label
    }()

    private lazy var passCodeErrorListView: ZoomCommonErrorTipsView = {
        let view = ZoomCommonErrorTipsView()
        view.errorType = .list
        view.isHidden = true
        return view
    }()

    private var divideView = EventBasicDivideView()

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }

    init (passCodeInfo: Server.ZoomSetting.Password, errorTitles: [String]) {
        self.passCodeInfo = passCodeInfo
        self.originalPassCode = passCodeInfo.password
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground
        passCodeSwitchCell.update(switchIsOn: passCodeInfo.optionButton.selected)
        inputBlock.isHidden = !passCodeInfo.optionButton.selected
        divideView.isHidden = !passCodeInfo.optionButton.selected
        passInputCell.text = passCodeInfo.password
        configErrorTitles(errorTitles: errorTitles)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = I18n.Calendar_Zoom_MeetingPasscode
        addBackItem()

        layoutPassSwitchCell()
        layoutInputCell()

    }

    // 侧滑返回
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if inputBlock.isHidden {
            passCodeInfo.optionButton.selected = false
            self.onSavePassCode?(passCodeInfo)
            self.navigationController?.popViewController(animated: true)
            return true
        } else if let passCode = passInputCell.text, !passCode.isEmpty {
            passCodeInfo.password = passCode
            passCodeInfo.optionButton.selected = true
            self.onSavePassCode?(passCodeInfo)
            self.navigationController?.popViewController(animated: true)
            return true
        } else {
            errorTips.isHidden = false
            let alertController = LarkAlertController()
            alertController.setTitle(text: I18n.Calendar_Zoom_SetCodeFirst)
            alertController.addPrimaryButton(text: I18n.Calendar_Common_GotIt)
            self.present(alertController, animated: true)
            return false
        }
    }

    // 按钮返回
    override func backItemTapped() {
        if inputBlock.isHidden {
            passCodeInfo.optionButton.selected = false
            self.onSavePassCode?(passCodeInfo)
            self.navigationController?.popViewController(animated: true)
        } else if let passCode = passInputCell.text, !passCode.isEmpty {
            passCodeInfo.password = passCode
            passCodeInfo.optionButton.selected = true
            self.onSavePassCode?(passCodeInfo)
            self.navigationController?.popViewController(animated: true)
        } else {
            errorTips.isHidden = false
            let alertController = LarkAlertController()
            alertController.setTitle(text: I18n.Calendar_Zoom_SetCodeFirst)
            alertController.addPrimaryButton(text: I18n.Calendar_Common_GotIt)
            self.present(alertController, animated: true)
        }
    }

    private func layoutPassSwitchCell() {
        view.addSubview(passCodeSwitchCell)
        view.addSubview(divideView)
        passCodeSwitchCell.isLocked = !passCodeInfo.optionButton.editable

        passCodeSwitchCell.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(48)
        }
        divideView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.top.equalTo(passCodeSwitchCell.snp.bottom)
        }
    }

    func layoutInputCell() {
        view.addSubview(inputBlock)
        inputBlock.addSubview(inputHeaderView)
        inputBlock.addSubview(passInputCell)
        inputBlock.addSubview(errorTips)
        inputBlock.addSubview(passCodeErrorListView)

        inputBlock.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(divideView.snp.bottom)
        }

        inputHeaderView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }

        passInputCell.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.top.equalTo(inputHeaderView.snp.bottom)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().offset(-32)
        }

        errorTips.snp.makeConstraints { make in
            make.top.equalTo(passInputCell.snp.bottom).offset(4)
            make.left.equalTo(passInputCell)
        }

        passCodeErrorListView.snp.makeConstraints { make in
            make.top.equalTo(passInputCell.snp.bottom).offset(4)
            make.left.equalTo(passInputCell).offset(16)
        }
    }

    @objc
    private func tapPasswordSwitch(sender: UISwitch) {
        inputBlock.isHidden = !sender.isOn
        divideView.isHidden = !sender.isOn
    }

    private func configErrorTitles(errorTitles: [String]) {
        if errorTitles.isEmpty { return }
        passCodeErrorListView.configErrorsList(titles: errorTitles)
        passCodeErrorListView.isHidden = false
        hasBringInError = true
    }

    @objc
    public func textFieldEditingChanged(_ textField: UITextField) {
        /// 修改过 提示消失
        if originalPassCode != textField.text {
            passCodeErrorListView.isHidden = true
        }
        /// 修改回原来一样的 出现提示
        if originalPassCode == textField.text && hasBringInError {
            passCodeErrorListView.isHidden = false
        }

        errorTips.isHidden = !textField.text.isEmpty
    }
}
