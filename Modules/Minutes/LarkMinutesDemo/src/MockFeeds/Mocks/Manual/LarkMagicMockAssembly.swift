//
//  LarkMagicMockAssembly.swift
//  LarkMessengerDemo
//
//  Created by mochangxing on 2020/11/9.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

#if canImport(LarkMagic)
import Foundation
import Swinject
import LarkMagic

class LarkMagicMockAssembly: Assembly {

    private var dependency: (Resolver) -> LarkMagicDependency

    public init(dependency: ((Resolver) -> LarkMagicDependency)? = nil) {
        self.dependency = dependency ?? { _ in return LarkMagicMockDependency() }
    }

    public func assemble(container: Container) {
        let resolver = container
        let dependency = self.dependency
        container.register(LarkMagicDependency.self) { _ -> LarkMagicDependency in
            return dependency(resolver)
        }
    }
}

open class LarkMagicMockDependency: LarkMagicDependency {
    init() {}

    public var isInMeeting: Bool {
        return false
    }

    public var isGuideShowing: Bool {
        return false
    }

    public var isAppRateShowing: Bool {
        return false
    }
}
#endif
