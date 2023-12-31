//
//  LarkIconAssembly.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/14.
//

import Foundation
import LarkAssembler
import LarkContainer
import LarkSetting

public final class LarkIconAssembly: LarkAssemblyInterface {
    
    public init() {}
    
    public func registContainer(container: Container) {
        container.inObjectScope(.userGraph).register(LarkIconManager.self) { r in
            return LarkIconManager(userResolver: r)
        }

        container.inObjectScope(.userGraph).register(LarkIconSetting.self) { r in
            return LarkIconSetting(userResolver: r)
        }

    }
    
}
