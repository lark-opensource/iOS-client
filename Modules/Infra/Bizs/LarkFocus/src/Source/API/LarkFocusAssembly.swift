//
//  LarkFocusAssembly.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/26.
//

import Foundation
import Swinject
import RxSwift
import BootManager
import LarkAccountInterface
import LarkAssembler
import LarkFocusInterface

public final class FocusAssembly: LarkAssemblyInterface {

    public init() {}

    public func registContainer(container: Container) {

        container.inObjectScope(.userGraph).register(FocusService.self) { _ in
            return LarkFocusServiceImpl()
        }

        container.inObjectScope(.userV2).register(FocusManager.self) { r in
            return FocusManager(userResolver: r)
        }
    }
}
