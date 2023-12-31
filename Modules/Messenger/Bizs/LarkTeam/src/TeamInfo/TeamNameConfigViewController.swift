//
//  TeamNameConfigViewController.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/18.
//

import UIKit
import Foundation
import RxSwift
import LarkUIKit
import LarkModel
import EENavigator
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignDialog

final class TeamNameConfigViewController: BaseUIViewController {

    private let disposeBag = DisposeBag()
    private let team: Team
    private let hasAccess: Bool
    private let teamAPI: TeamAPI
    private let textMaxLength = 60
    lazy var nameInputView = TeamInputView(textMaxLength: textMaxLength)
    private(set) var finishedButton: UIButton?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    let navigator: EENavigator.Navigatable

    init(team: Team,
         teamAPI: TeamAPI,
         hasAccess: Bool,
         navigator: EENavigator.Navigatable) {
        self.team = team
        self.teamAPI = teamAPI
        self.hasAccess = hasAccess
        self.navigator = navigator
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addNavigationBarRightItem()

        nameInputView.text = team.name
        nameInputView.textFieldDidChangeHandler = { [weak self] (textField) in
            guard let self = self else { return }
            self.updateRightItemEnabled(text: textField.text)
        }
        self.view.addSubview(nameInputView)
        self.title = BundleI18n.LarkTeam.Project_T_RequiredTeamNameField

        nameInputView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(15)
        }

        self.backCallback = { [weak self] in
            self?.endEditting()
        }

        self.setAccessHandler(self.hasAccess)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.nameInputView.textField.becomeFirstResponder()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditting()
    }

    fileprivate func addNavigationBarRightItem() {
        let rightItem = LKBarButtonItem(title: BundleI18n.LarkTeam.Project_MV_SaveButton)
        rightItem.setProperty(alignment: .right)
        rightItem.button.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        rightItem.button.setTitleColor(UIColor.ud.N400, for: .disabled)
        rightItem.button.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        self.finishedButton = rightItem.button
        self.navigationItem.rightBarButtonItem = rightItem
    }

    @objc
    fileprivate func navigationBarRightItemTapped() {
        let hud = UDToast.showLoading(on: view)
        teamAPI.patchTeamRequest(teamId: team.id,
                                 updateFiled: [.name],
                                 name: nameInputView.text?.removeCharSpace ?? "",
                                 ownerId: nil,
                                 isDissolved: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, let window = self.view.window else { return }
                hud.showSuccess(with: BundleI18n.LarkTeam.Lark_Legacy_SaveSuccess, on: window)
                self.navigationController?.popViewController(animated: true)
            }, onError: { [weak self, weak hud] (error) in
                if let self = self {
                    hud?.showFailure(
                        with: BundleI18n.LarkTeam.Lark_Legacy_ChatGroupInfoModifyGroupNameFailed,
                        on: self.view,
                        error: error
                    )
                }
                TeamMemberViewModel.logger.error("teamlog/modify group name failed", error: error)
            }).disposed(by: disposeBag)
    }

    private func showNameIsEmptyAlert() {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkTeam.Lark_Legacy_Hint)
        dialog.setContent(text: BundleI18n.LarkTeam.Lark_Legacy_ContentCantEmpty)
        dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Lark_Legacy_Sure)
        navigator.present(dialog, from: self)
    }

    fileprivate func endEditting() {
        if self.view.canResignFirstResponder {
            self.view.endEditing(true)
        }
    }

    fileprivate func setAccessHandler(_ hasAccess: Bool) {
        self.nameInputView.textField.isEnabled = hasAccess
        self.finishedButton?.isHidden = !hasAccess
    }

    private func updateRightItemEnabled(text: String?) {
        self.finishedButton?.isEnabled = text?.checked(maxChatLength: textMaxLength) ?? false
    }
}
