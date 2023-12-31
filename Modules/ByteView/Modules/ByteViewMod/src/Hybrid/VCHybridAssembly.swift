//
//  VCHybridAssembly.swift
//  ByteViewMod
//
//  Created by kiri on 2023/2/20.
//

import Foundation
import ByteViewHybrid
import LarkAssembler
import LarkContainer

final class VCHybridAssembly: LarkAssemblyInterface {
    func registContainer(container: Container) {
        let user = container.inObjectScope(.vcUser)
        user.register(LynxDependency.self) {
            LynxDependencyImpl(userResolver: $0)
        }
    }
}
