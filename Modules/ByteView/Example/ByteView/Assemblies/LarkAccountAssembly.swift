//
//  LarkAccountAssembly.swift
//  ByteViewDemo
//
//  Created by kiri on 2021/3/9.
//

import Foundation
import Swinject
//import ByteViewDemo
import ByteWebImage

class LarkAccountAssembly: Assembly {
    init() {}
    func assemble(container: Container) {
        container.register(AccountDependency.self) { _ in
            DemoAccountDependency()
        }
    }
}

class DemoAccountDependency: DefaultAccountDependencyImpl {
    override var avatarPath: String {
        LarkImageService.shared.thumbCache.diskCache.path
    }
}
