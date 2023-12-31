//
//  Assembly.swift
//  LarkCreateTeam
//
//  Created by liuwanlin on 2019/9/27.
//

import Foundation
import Swinject
import EENavigator
import LarkAccountInterface
import LarkMessengerInterface
import LarkUIKit
import LKCommonsLogging
import LarkContainer
import WebBrowser
import RxSwift
import LarkAssembler
import LarkContact

public final class CreateTeamAssembly: Assembly, LarkAssemblyInterface {

    public init() {}
    static let logger = Logger.log(CreateTeamAssembly.self)

    @Provider var dependency: PassportWebViewDependency
    let disposeBag = DisposeBag()

    public func assemble(container: Container) {
        registContainer(container: container)
        registRouter(container: container)
        registUnloginWhitelist(container: container)
    }

    public func registContainer(container: Container) {
        container.register(SuiteLoginWebViewFactory.self) { _ -> SuiteLoginWebViewFactory in
            return SuiteLoginWebViewFactoryImpl(controllerCreator: { url, userAgent in
                let vc = JsBridgeWebHandler.createWebViewController(resolver: container, url: url, customUserAgent: userAgent)
                return vc
            })
        }
        
        container.register(ExternalCallAPIDependencyProtocol.self, name: "PassportCallAPI") { resolver in
            let dependency = PassportCallAPIImpl(resolver: resolver)
            return dependency
        }
    }
    public func registRouter(container: Container) {
        Navigator.shared.registerRoute_(type: JsBridgeWebBody.self) {
            return JsBridgeWebHandler(resolver: container)
        }
    }

    public func registUnloginWhitelist(container: Container) {
        JsBridgeWebBody.pattern
    }
}
