//
//  OPBlockAssembly.swift
//  OPBlock
//
//  Created by xiangyuanyuan on 2022/9/7.
//

import Swinject
import LarkAssembler
import OPBlockInterface
import LarkContainer

public final class OPBlockAssembly: LarkAssemblyInterface {
    
    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(BlockScope.userScope)
        // let userGraph = container.inObjectScope(BlockScope.userGraph)

        user.register(OPBlockPreUpdateProtocol.self) { _ in
            return OPBlockPreLoadService()
        }

        user.register(OPBlockAPISetting.self) { r in
            return OPBlockAPISetting(userResolver: r)
        }
    }
}
