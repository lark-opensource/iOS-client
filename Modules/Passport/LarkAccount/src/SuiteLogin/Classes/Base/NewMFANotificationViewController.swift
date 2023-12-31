//
//  NewMFANotificationViewController.swift
//  LarkAccount
//
//  Created by YuankaiZhu on 2023/9/8.
//

import Foundation
import UIKit
import LarkContainer
import LKCommonsLogging
import LarkAccountInterface


class NewMFANotificationViewController: UIViewController {
    private let userResolver = PassportUserScope.getCurrentUserResolver() // user:current
    static let logger = Logger.plog(NewMFANotificationViewController.self, category: "SuiteLogin.NewMFANotificationViewController")

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.white
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            var mfaService = try userResolver.resolve(assert: InternalMFANewService.self)
            if mfaService.isNotifyVCAppeared {
                if mfaService.needSendMFAResultcWhenDissmiss {
                    guard let onSuccess = mfaService.onSuccess, let onError = mfaService.onError else {
                        Self.logger.error("n_action_verification_error_no_callback")
                        self.dismiss(animated: false)
                        return
                    }
                    if case .token(let token) = mfaService.loginNaviMFAResult, let token = token {
                        onSuccess(token)
                    } else if case .code(let code) = mfaService.loginNaviMFAResult, let code = code {
                        onSuccess(code)
                    } else {
                        onError(NewMFAServiceError.userClosePage)
                    }
                }
                mfaService.isDoingActionStub = false
                self.dismiss(animated: false)
            }
        } catch {
            Self.logger.error("n_action_verification_completed_step_userResolver_error")
        }
    }
}
