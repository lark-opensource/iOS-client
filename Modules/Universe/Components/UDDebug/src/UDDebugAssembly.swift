//
//  UDDebugAssembly.swift
//  UDDebug
//
//  Created by 白镜吾 on 2023/7/24.
//

import Foundation
import Swinject
import AppContainer
import BootManager
import LarkAssembler
import LarkDebugExtensionPoint

public final class UDDebugAssembly: LarkAssemblyInterface {

    public init() { }

#if !LARK_NO_DEBUG
    public func registDebugItem(container: Container) {
        ({ UDDebugItem() }, SectionType.debugTool)
    }
#endif
}
