//
//  SKCreateEnableTypesCache.swift
//  SpaceInterface
//
//  Created by ByteDance on 2023/3/20.
//

import Foundation
/// 某些业务需要知道当前用户能创建哪些内容，这个实例用来记录计算结果
public protocol SKCreateEnableTypesCache {
    var createEnableTypes: [DocsType] { get set }
    func updateCreateEnableTypes()
}
