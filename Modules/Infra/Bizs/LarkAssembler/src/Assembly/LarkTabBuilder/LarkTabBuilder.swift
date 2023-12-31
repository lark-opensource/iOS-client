//
//  LarkAssemblyBuilder.swift
//  LarkContainer
//
//  Created by yangjing.sniper on 2021/12/23.
//

import Foundation
import LarkTab

@resultBuilder
public struct TabRegistryFactory {
    public static func buildBlock(_ components: (Tab, TabEntryProvider)...) {
        components.forEach { compent in
            TabRegistry.register(compent.0, provider: compent.1)
        }
    }
}

@resultBuilder
public struct TabRegistryMatcherFactory {
    public static func buildBlock(_ components: (String, TabEntryProvider)...) {
        components.forEach { compent in
            TabRegistry.registerMatcher(compent.0, provider: compent.1)
        }
    }
}
