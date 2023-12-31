//
//  LarkSnsShareAssembly.swift
//  LarkSnsShare
//
//  Created by shizhengyu on 2020/11/19.
//

import Foundation
import AppContainer
import LKCommonsLogging
import Swinject
import LarkRustClient
import LarkAccountInterface
import LarkAssembler

// MARK: - Assembly
public final class LarkSnsShareAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        container.inObjectScope(.userV2).register(ShareDynamicAPI.self) { (r) -> ShareDynamicAPI in
            let rustClient = try r.resolve(assert: RustService.self)
            return RustShareDynamicAPI(client: rustClient, scheduler: scheduler)
        }

        container.inObjectScope(.userV2).register(LarkShareService.self) { (r) -> LarkShareService in
            return LarkSharePresenter(userResolver: r)
        }
    }
}
