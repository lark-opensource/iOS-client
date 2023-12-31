//
//  WikiContextProvider.swift
//  SpaceInterface
//
//  Created by Weston Wu on 2023/7/12.
//

import Foundation

public protocol WikiContextProxy {
    var wikiContextProvider: WikiContextProvider? { get set }
}

/// 文档内注入的 Wiki 上下文信息
public protocol WikiContextProvider: AnyObject {
    var synergyUUID: String { get }
}
