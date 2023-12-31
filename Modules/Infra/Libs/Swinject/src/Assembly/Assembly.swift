//
//  Assembly.swift
//  SwinjectTest
//
//  Created by CharlieSu on 4/29/20.
//  Copyright © 2020 Lark. All rights reserved.
//

import Foundation

/// The `Assembly` provides a means to organize your `Service` registration in logic groups which allows
/// the user to swap out different implementations of `Services` by providing different `Assembly` instances
/// to the `Assembler`
public protocol Assembly {
    /// Provide hook for `Assembler` to load Services into the provided container
    ///
    /// - parameter container: the container provided by the `Assembler`
    ///
    func assemble(container: Container)
    /// async
    /// - Parameter container: async
    func asyncAssemble()
}

/// async
public extension Assembly {
    /// async
    /// - Parameter container: async
    func asyncAssemble() {

    }
}
