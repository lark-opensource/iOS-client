//
//  Debug+V2.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2019/11/11.
//

import UIKit
import RoundedHUD

extension DebugFactory {

    public func loginNaviVC(rootVC: UIViewController) -> UINavigationController {
        return LoginNaviController(rootViewController: rootVC)
    }

    public func initPersonal() -> UIViewController {
//        let vc = InitializePersonalViewController(
//            service: loginService,
//            userID: "",
//            context: UniContext.placeholder,
//            onCancel: { },
//            fetchAccountHandler: { _ in }
//        )
        return UIViewController()
    }
}
