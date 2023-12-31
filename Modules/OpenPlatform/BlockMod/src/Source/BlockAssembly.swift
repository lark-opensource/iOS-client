//
//  BlockAssembly.swift
//  BlockMod
//
//  Created by Meng on 2023/8/29.
//

import Foundation
import Swinject
import LarkAssembler
import LarkBlockHost
import OPBlock
import Blockit

public final class BlockAssembly: LarkAssemblyInterface {
    public init() {}

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        return [
            BlockitAssembly(),
            OPBlockAssembly(),
            LarkBlockHostAssembly()
        ]
    }
}
