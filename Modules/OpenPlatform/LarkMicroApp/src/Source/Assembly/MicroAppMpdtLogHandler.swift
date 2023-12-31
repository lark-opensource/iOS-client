//
//  MicroAppMpdtLogHandler.swift
//  LarkMicroApp
//
//  Created by yinyuan on 2019/7/26.
//

import Foundation
import Swinject
import EENavigator
import LarkNavigator
import EEMicroAppSDK

class MicroAppMpdtLogHandler: UserRouterHandler {
    static func compatibleMode() -> Bool {
        OPUserScope.compatibleModeEnabled
    }
    
    func handle(req: Request, res: Response) throws {
        let url = req.url
        let queryParameters = url.queryParameters
        guard let wsUrl = queryParameters["wsUrl"] else {
            res.end(error: RouterError.resourceWithWrongFormat)
            return
        }
        EERoute.shared().handleDebuggerWSURL(wsUrl)
        res.end(resource: EmptyResource())
    }
}
