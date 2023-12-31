//
//  MockAuthorizationAssembly.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2020/12/1.
//

import Foundation
import EENavigator
import LarkAccountInterface
import Swinject
import LarkAssembler

let authorizationNotEnableMsg: String = "not enable 'Authorization' subspec in LarkAccount. "

struct MockAuthorizationAssembly: LarkAssemblyInterface {

    public func registRouter(container: Swinject.Container) {
        Navigator.shared.registerRoute_(type: SSOVerifyBody.self) { (_, _, resp) in
            let msg = authorizationNotEnableMsg + "can not router SSOVerifyBody.pattern"
            assertionFailure(msg)
            resp.end(error: RouterError(code: -1, message: msg))
        }
    }

    public func registURLInterceptor(container: Swinject.Container) {
        (SSOVerifyBody.pattern, { (url: URL, from: NavigatorFrom) in
            assertionFailure(authorizationNotEnableMsg + "can not router SSOVerifyBody.pattern")
        })
    }
}

