//
//  SwitchAccountHandler.swift
//  LarkAccount
//
//  Created by sniperj on 2020/3/2.
//

import Foundation
import EENavigator
import Swinject
import LKCommonsLogging
import LarkAccountInterface
import BootManager

struct SwitchAccountBody: CodablePlainBody {

    static let pattern = "//client/tenant/switch"

    let userId: String
    let redirect: String?

    init(userId: String, redirect: String?) {
        self.userId = userId
        self.redirect = redirect
    }
}

class SwitchAccountHandler: TypedRouterHandler<SwitchAccountBody> { // user:checked (navigator)
    private let resolver: Resolver

    static let logger = Logger.plog(SwitchAccountHandler.self, category: "switchAccount")

    init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }

    override func handle(_ body: SwitchAccountBody, req: EENavigator.Request, res: Response) {
        guard let launcher = try? resolver.resolve(type: Launcher.self) else {
            Self.logger.error("resolve launcher fauled.")
            return
        }
        guard let originRedirect = body.redirect, let redirect = originRedirect.urlDecoded() else {
            Self.logger.error("redirect url is nil: \(body.redirect ?? "nil")")
            return
        }
        SwitchAccountHandler.logger.info("userid = \(body.userId) redirectUrl = \(redirect)")
        let passportService = try? self.resolver.resolve(type: PassportService.self)
        if let passportService = passportService,
            body.userId == passportService.foregroundUser?.userID {
            Self.redirectToUrl(redirect: redirect, res: res)
        } else {
            launcher.switchTo(userID: body.userId) { (isSwitchSuccess) in
                if isSwitchSuccess {
                    NewBootManager.shared.registerTask(taskAction: {
                        Self.redirectToUrl(redirect: redirect, res: res)
                    }, triggerMoment: .afterFirstRender)
                } else {
                    res.end(resource: EmptyResource())
                }
            }
            res.wait()
        }
    }

    static func redirectToUrl(redirect: String, res: Response) {
        if let redirectUrl = URL(string: redirect) {
            if let mainSceneWindow = PassportNavigator.keyWindow {
                URLInterceptorManager.shared.handle(redirectUrl, from: mainSceneWindow)
            } else {
                assertionFailure()
            }
            res.end(resource: EmptyResource())
        } else {
            res.end(resource: EmptyResource())
        }
    }
}

fileprivate extension String {
    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }
}