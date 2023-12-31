//
//  UserInfoService.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/12/2.
//

import Foundation
import LarkContainer
import SKFoundation

class UserInfoService: WASimpleContainerBridgeService {
    
    override var name: WABridgeName {
        .getUserInfo
    }
    
    override func handle(invocation: WABridgeInvocation) {
        guard let userInfo = try? self.container?.userResolver.resolve(assert: WAUserInfoProtocol.self) else {
            invocation.callback?.callbackFailure()
            return
        }
        invocation.callback?.callbackSuccess(param: ["info": userInfo.toDic()])
    }
}
