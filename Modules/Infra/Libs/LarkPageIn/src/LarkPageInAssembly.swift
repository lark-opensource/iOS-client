//
//  LarkPageInAssembly.swift
//  LarkPageIn
//
//  Created by huanglx on 2022/12/15.
//

import Foundation
import Swinject
import BootManager
import LarkAssembler

public final class LarkPageInAssembly: LarkAssemblyInterface {
    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(PageInTask.self)
    }
}
