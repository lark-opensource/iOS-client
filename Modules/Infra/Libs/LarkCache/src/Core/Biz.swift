//
//  Biz.swift
//  LarkCache
//
//  Created by Supeng on 2020/8/11.
//

import Foundation

/// 缓存所属业务模块
public protocol Biz {
    /// 父Biz模块
    static var parent: Biz.Type? { get }
    /// 当前模块路径  e.g.  "messenger"
    static var path: String { get }
}

public extension Biz {
    /// 拼接上所有parent模块后的完整路径
    static var fullPath: String {
        var pathArr: [String] = [path]
        var tempParent = parent
        while let tp = tempParent {
            pathArr.append(tp.path)
            tempParent = tp.parent
        }
        return pathArr.reversed().joined(separator: "/")
    }
}

/// CCM模块，存储路径为"ccm"
public enum CCM: Biz {
    public static var parent: Biz.Type?
    public static var path: String = "DocsSDK"
}

/// Mail模块，存储路径为"mail"
public enum Mail: Biz {
    public static var parent: Biz.Type?
    public static var path: String = "mail"
}

/// MicroApp模块，存储路径为"microApp"
public enum MicroApp: Biz {
    public static var parent: Biz.Type?
    public static var path: String = "microApp"
}
