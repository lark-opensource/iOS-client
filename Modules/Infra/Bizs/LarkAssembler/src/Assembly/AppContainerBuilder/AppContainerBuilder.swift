//
//  LarkAssemblyBuilder.swift
//  LarkContainer
//
//  Created by yangjing.sniper on 2021/12/23.
//

import Foundation
import AppContainer

@resultBuilder
public struct BootLoaderFactory {
    public static func buildBlock(_ components: (ApplicationDelegate.Type, DelegateLevel)...) {
        components.forEach { compent in
            BootLoader.shared.registerApplication(delegate: compent.0, level: compent.1)
        }
    }
}
