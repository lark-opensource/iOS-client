//
//  AuthAutoLoginViewController.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/5/31.
//

import UniverseDesignDialog
import LKCommonsLogging
import UIKit
import EENavigator
import LarkContainer

class AuthAutoLoginViewController: AuthorizationBaseViewController {
    private let authInfo: LoginAuthInfo
    private let dialog = UDDialog()

    init(vm: SSOBaseViewModel, authInfo: LoginAuthInfo, resolver: UserResolver?) {
        self.authInfo = authInfo
        super.init(vm: vm, resolver: resolver)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        
        guard let buttonList = authInfo.buttonList, !buttonList.isEmpty else {
            dismiss(animated: false)
            return
        }

        dialog.setTitle(text: authInfo.authAutoLoginInfo?.title ?? "")
        dialog.setContent(attributedText: authInfo.authAutoLoginInfo?.subtitle.html2Attributed(font: .systemFont(ofSize: 16), forgroundColor: UIColor.ud.textTitle) ?? NSAttributedString())
        for button in buttonList {
            switch button.actionType {
            case .authAutoLoginConfirm:
                dialog.addPrimaryButton(text: button.text, dismissCompletion: { [weak self] in
                    Self.logger.info("n_action_auth_auto_login_comfirm")

                    self?.confirmToken(scope: "", isMultiLogin: false, success: {
                        Self.logger.info("n_action_auth_auto_login_succ")
                    }, failure: {
                        Self.logger.error("n_action_auth_auto_login_fail")
                    })
                })
                trackClick(isConfirm: true)
            case .authAutoLoginCancel:
                dialog.addSecondaryButton(text: button.text, dismissCompletion:  { [weak self] in
                    Self.logger.error("n_action_auth_auto_login_canceled")
                    self?.closeBtnClick()
                })
                trackClick(isConfirm: false)
            default:
                dialog.addSecondaryButton(text: button.text, dismissCompletion:  { [weak self] in
                    Self.logger.error("n_action_auth_auto_login_default_action", body: "action type: \(button.actionType ?? .unknown)")
                    self?.dismiss(animated: false, completion: nil)
                })
            }
        }
        Navigator.shared.present(dialog, from: self) // user:checked (debug)

        trackViewLoad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        dialog.dismiss(animated: false, completion: nil)
    }

    private func trackViewLoad() {
        SuiteLoginTracker.track("passport_disposable_login_risk_remind_view")
    }

    private func trackClick(isConfirm: Bool) {
        let key = "passport_disposable_login_risk_remind_click"
        let click = isConfirm ? "go_on" : "cancel"
        let target = isConfirm ? "passport_disposable_login_risk_restrict_view" : "none"
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: "", click: click, target: target)
        SuiteLoginTracker.track(key, params: params)
    }
}
