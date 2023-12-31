//
//  LarkAssemblyBuilder.swift
//  LarkContainer
//
//  Created by yangjing.sniper on 2021/12/23.
//

import Foundation
import Swinject

@resultBuilder
/// Container factory for create ServiceEntry
public struct ContainerFactory {
    public static func buildBlock(_ components: ServiceEntryProtocol...) {
    }
}
