//
//  LarkAssemblyBuilder.swift
//  LarkContainer
//
//  Created by yangjing.sniper on 2021/12/23.
//

import Foundation
import LarkDebugExtensionPoint

@resultBuilder
public struct DebugItemFactory {
    public static func buildBlock(_ components: (DebugItemProvider, SectionType)...) {
        components.forEach { compent in
            DebugRegistry.registerDebugItem(compent.0(), to: compent.1)
        }
    }
}
