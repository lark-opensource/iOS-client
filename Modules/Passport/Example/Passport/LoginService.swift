//
//  LoginService.swift
//  LarkAccountDev
//
//  Created by Miaoqi Wang on 2020/9/24.
//

import Foundation
import LarkAccountInterface
import LarkUIKit
import RxSwift
import LarkAccount
import LKCommonsLogging
import EENavigator

class LoginService {
    static let shared = LoginService()
    static let logger = Logger.log(LoginService.self)

    var window: UIWindow?
    let disposeBag = DisposeBag()

    /// 登录开始
    func login(window: UIWindow?) {
        self.window = window
        AccountServiceAdapter.shared.fastLogin()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (userInfo) in
                self.logined()
            }, onError: { _ in
                AccountServiceAdapter.shared.login(conf: .default, window: self.window)
                    .subscribe(onNext:{ _ in
                        self.logined()
                    }).disposed(by: self.disposeBag)
            }).disposed(by: disposeBag)
    }

    func logined() {
        let rootVc = LkNavigationController(rootViewController: MainViewController())

        Navigator.shared.navigationProvider = { rootVc }

        self.window?.rootViewController = rootVc

        AccountServiceAdapter.shared.mainViewLoaded()
    }

    /// 登出开始
    func relogin() {
        AccountServiceAdapter.shared.relogin(conf: .default) { (msg) in
            Self.logger.error("error with msg \(msg)")
        } onSuccess: {
            AccountServiceAdapter.shared.login(conf: .default, window: self.window)
                .subscribe { (userInfo) in
                    self.logined()
                } onError: { (error) in
                    Self.logger.error("relogin failed", error: error)
                }.disposed(by: self.disposeBag)
        } onInterrupt: {
            Self.logger.warn("logout interrupted")
        }
    }

    func registerOneKeyLogin() {
        AccountServiceAdapter.shared.conf
            .oneKeyLoginConfig = [
                .init(service: .mobile, appId: "123", appKey: "xxx"),
                .init(service: .telecom, appId: "123", appKey: "xxx"),
                .init(service: .unicom, appId: "123", appKey: "xxx")
        ]
    }
}
