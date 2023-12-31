//
//  PassportJsAPIHandlerProvider.swift
//  JsSDK
//
//  Created by Miaoqi Wang on 2021/1/18.
//

import Foundation
import ECOInfra
import LarkContainer

public struct PassportJsAPIHandlerProvider: JsAPIHandlerProvider {

    public let handlers: JsAPIHandlerDict

    public init(resolver: Resolver) {
        self.handlers = [
            "biz.passport.logout": { PasssportLogoutHandler(resolver: resolver) },
            "biz.account.appInfo": { PassportAppInfoHandler(resolver: resolver) },
            "biz.passport.stateMachine": {
                PassportStateMachineHandler(resolver: resolver)
            },
            "biz.user.userInfo.get": {
                // TODOZJX
                return UserInfoHandler(resolver: OPUserScope.userResolver())
            },
            "biz.account.unRegisterFinish":{ PassportUnRegisterHandler(resolver: resolver) },
            "biz.account.unRegisterRedPacket": {PassportUnRegisterPacketHandler(resolver: resolver) },
            "biz.passport.fido.register": {PassportRegisterFidoHandler(resolver: resolver) }
        ]
    }
}
