//
//  CheckTokenViewController.swift
//  LarkQRCode
//
//  Created by Miaoqi Wang on 2020/3/18.
//

import Foundation
import UIKit
import LarkUIKit
import EENavigator

class CheckAuthTokenViewController: AuthorizationBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        // clear view use mainWindow show toast
        checkToken(loadingOnview: PassportNavigator.getUserScopeKeyWindow(userResolver: userResolver), success: { [weak self] (authInfo) in
            guard let self = self else { return }
            if let authInfo = authInfo, let vc = CheckAuthTokenViewController.loginAuthViewController(
                vm: self.vm,
                authInfo: authInfo,
                resolver: self.userResolver) {
                if authInfo.template == .authAutoLogin || authInfo.template == .authAutoLoginError {
                    vc.modalPresentationStyle = .overCurrentContext
                } else {
                    vc.modalPresentationStyle = .fullScreen
                }
                let presentingVC = self.presentingViewController
                self.dismiss(animated: false) {
                    guard let from = presentingVC else {
                        Self.logger.errorWithAssertion("no presentingVC for further present")
                        return
                    }
                    Self.logger.info("n_page_ssosdk_auth_start")
                    self.userResolver.navigator.present(vc, from: from)
                }
            } else {
                self.dismiss(animated: false, completion: nil)
            }
        }) { [weak self] error in
            guard let self = self else { return }
            self.errorHandle(error: error, closeAlertHandle: { [weak self] in
                self?.dismiss(animated: false, completion: nil)
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Self.logger.info("n_page_transloading_start")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Self.logger.info("n_page_transloading_end")
    }
}
