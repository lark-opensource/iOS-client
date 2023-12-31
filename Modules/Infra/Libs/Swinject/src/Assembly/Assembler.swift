//
//  Assembler.swift
//  SwinjectTest
//
//  Created by CharlieSu on 4/29/20.
//  Copyright © 2020 Lark. All rights reserved.
//

import Foundation

/// The `Assembler` provides a means to build a container via `Assembly` instances.
public final class Assembler {
    private var container: Container

    /// expose the container as a resolver so `Service` registration only happens within an assembly
    public var resolver: Resolver { return container }

    /// just for LarkAssembly
    /// - Parameter can: can callResolve
    public func setContainerCanCallResolve(_ can: Bool) {
        self.container.canCallResolve = can
    }

    public init(container: Container) {
        self.container = container
    }

    /// Will create a new `Assembler` with the given `Assembly` instances to build a `Container`
    ///
    /// - parameter assemblies:         the list of assemblies to build the container from
    /// - parameter container:          the baseline container
    ///
    public init(_ assemblies: [Assembly], container: Container = Container()) {
        self.container = container
        container.canCallResolve = false
        assemblies.forEach { assembly in
            assembly.assemble(container: container)
//            signPost(eventName: String(describing: type(of: assembly.self)), signPostName: "Assembly") {
//                assembly.assemble(container: container)
//            }
        }
        container.canCallResolve = true
    }
}
