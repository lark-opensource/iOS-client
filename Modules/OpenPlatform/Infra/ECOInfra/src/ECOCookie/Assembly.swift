//
//  Assembly.swift
//  ECOInfra
//
//  Created by Meng on 2021/2/18.
//

import Foundation
import Swinject
import LarkAssembler
import LarkContainer

public final class ECOCookieAssembly: Assembly, LarkAssemblyInterface {
    public init() {}

    /// 旧版本 assembly 调用入口，等主端新版本统一灰度完成后再下掉
    public func assemble(container: Container) {
        registContainer(container: container)
    }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(OPUserScope.userScope)
        let userGraph = container.inObjectScope(OPUserScope.userGraph)
        
        user.register(ECOCookieConfig.self) { resolver in
            return ECOCookieConfig(resolver: resolver)
        }

        /// Swinject 只会校验 argument type，因此不能绑定 objectScope，每次重新生成
        userGraph.register(ECOCookieGadgetSync.self) { (resolver, gadgetId: GadgetCookieIdentifier) in
            return try ECOCookieGadgetSync(resolver: resolver, gadgetId: gadgetId)
        }

        user.register(ECOCookieService.self) { resolver in
            return try ECOCookieServiceImpl(resolver: resolver)
        }

        /// Assembly Plugin
        container.register(ECOCookieGlobalPlugin.self) { _ in
            return ECOCookieGlobalPlugin()
        }.inObjectScope(.container)

        /// Swinject 只会校验 argument type，因此不能绑定 objectScope，每次重新生成
        userGraph.register(ECOCookiePlugin.self) { (resolver, identifier: String) in
            return ECOCookiePlugin(resolver: resolver, identifier: identifier)
        }
    }
}
