//
//  AccountDependencyImp.swift
//  LarkAccountDev
//
//  Created by Miaoqi Wang on 2021/3/30.
//

import Foundation
import LarkAccount
import LarkAccountInterface
import EENavigator

#if canImport(LarkBytedCert)
import LarkBytedCert
class AccountDependencyImpl: DefaultAccountDependencyImpl {
    override func doFaceLiveness(
        appId: String,
        ticket: String,
        scene: String,
        identityName: String,
        identityCode: String,
        callback: @escaping (_ data: [AnyHashable: Any]?, _ errmsg: String?) -> Void
    ) {
        LarkBytedCert().doFaceLiveness(
                    appId: appId,
                    ticket: ticket,
                    scene: scene,
                    identityName: identityName,
                    identityCode: identityCode,
                    callback: callback
                )
    }

    override func doFaceLiveness(appId: String, ticket: String, scene: String, mode: String, callback: @escaping ([AnyHashable: Any]?, String?) -> Void) {
        LarkBytedCert().doFaceLiveness(
            appId: appId,
            ticket: ticket,
            scene: scene,
            mode: mode,
            callback: callback
        )
    }
}
#endif
