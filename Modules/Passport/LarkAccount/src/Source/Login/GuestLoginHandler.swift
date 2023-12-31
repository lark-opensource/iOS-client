//
//  GuestLoginHandler.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2020/8/9.
//

import Foundation
import LarkContainer
import LarkAccountInterface
import EENavigator
import LKCommonsLogging

class GuestLoginHandler: TypedRouterHandler<GuestLoginBody> { // user:checked (navigator)

    @Provider private var launcher: Launcher

    static let logger = Logger.plog(GuestLoginHandler.self, category: "SuiteLogin.GuestLogin")

    override func handle(_ body: GuestLoginBody, req: EENavigator.Request, res: Response) {
        Self.logger.info("start hanlde guest login")
        //TODO: 空处理, 后续等依赖方代码去除后删除
        res.end(resource: EmptyResource())
    }
}
