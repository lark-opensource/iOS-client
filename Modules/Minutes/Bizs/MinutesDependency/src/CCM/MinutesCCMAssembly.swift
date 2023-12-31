//
//  MinutesCCMAssembly.swift
//  ByteViewMod
//
//  Created by kiri on 2021/10/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import EENavigator
import LarkAssembler
import LarkContainer
import Minutes


public final class MinutesCCMAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let userTransient = container.inObjectScope(.userTransient)
        userTransient.register(MinutesCommentDependency.self) { r in
            MinutesCommentDependencyImpl(resolver: r)
        }
    }
}
