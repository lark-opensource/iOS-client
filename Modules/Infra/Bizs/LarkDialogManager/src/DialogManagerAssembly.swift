//
//  DialogManagerAssembly.swift
//  LarkDialogManager
//
//  Created by ByteDance on 2022/8/30.
//

import Foundation
import AppContainer
import Swinject
import LarkAssembler

// MARK: - Assembly
public final class DialogManagerAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        container.register(DialogManagerService.self) { (_) -> DialogManagerService in
            return DialogManagerImpl.shared
        }.inObjectScope(.user)
    }
}
