//
//  LarkAssemblyBuilder.swift
//  LarkContainer
//
//  Created by yangjing.sniper on 2021/12/23.
//

import Foundation
import BootManager

@resultBuilder
/// Factory for regist bootTask
public struct BootManagerFactory {
    public static func buildBlock(_ components: BootTask.Type...) {
    }
}
