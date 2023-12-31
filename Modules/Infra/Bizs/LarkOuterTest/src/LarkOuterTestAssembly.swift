//
//  LarkOuterTestAssembly.swift
//  LarkOuterTestAssembly
//
//  Created by luyz on 2021/9/23.
//

import Foundation
import Swinject
import BootManager
import LarkAssembler

public class LarkOuterTestAssembly: LarkAssemblyInterface {
    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(SetupIESOuterTestTask.self)
    }
}
