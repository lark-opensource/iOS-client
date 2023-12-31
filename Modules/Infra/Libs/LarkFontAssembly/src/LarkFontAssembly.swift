//
//  LarkFontAssembly.swift
//  LarkFontAssembly
//
//  Created by 白镜吾 on 2023/3/22.
//

import BootManager
import LarkAssembler
import LarkContainer

public final class LarkFontAssembly: LarkAssemblyInterface {

    public init() { }

    public func registLaunch(container: Container) {
        NewBootManager.register(FontLaunchTask.self)
    }
}
