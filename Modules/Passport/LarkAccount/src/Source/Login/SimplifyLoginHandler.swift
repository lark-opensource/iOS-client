//
//  SimplifyLoginHandler.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/8/9.
//

import Foundation
import LarkContainer
import LarkAccountInterface
import EENavigator
import LKCommonsLogging

class SimplifyLoginHandler: TypedRouterHandler<SimplifyLoginBody> { // user:checked (navigator)

    @Provider private var launcher: Launcher

    static let logger = Logger.plog(SimplifyLoginHandler.self, category: "SuiteLogin.LoginHandler")

    override func handle(_ body: SimplifyLoginBody, req: EENavigator.Request, res: Response) {
        Self.logger.info("start hanlde simplify login")
        //TODO: 空处理, 后续等依赖方代码去除后删除
        res.end(resource: EmptyResource())
    }
}
