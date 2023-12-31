//
//  HeimdallrDependency.swift
//  ByteViewDependency
//
//  Created by Tobb Huang on 2023/7/10.
//

import Foundation

/// 外部依赖： 获取外部Heimdallr服务
public protocol HeimdallrDependency {
    func setCustomContextValue(_ value: Any?, forKey key: String?)
    func setCustomFilterValue(_ value: Any?, forKey key: String?)
    func removeCustomContextKey(_ key: String?)
    func removeCustomFilterKey(_ key: String?)
}
