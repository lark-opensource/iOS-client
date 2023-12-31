//
//  LarkAssemblyBuilder.swift
//  LarkContainer
//
//  Created by yangjing.sniper on 2021/12/23.
//

import Foundation
import Swinject

@resultBuilder
public struct SubAssembliesFactory {
    public static func buildBlock(_ components: LarkAssemblyInterface...) -> [LarkAssemblyInterface] {
        return components
    }
}
