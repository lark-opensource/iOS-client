//
//  ChatPreloadConfiguration.swift
//  LarkAccountInterface
//
//  Created by CharlieSu on 11/12/19.
//

import Foundation

/// Rust configuration
public protocol RustConfigurationService {
    /// 预加载的群成员数量
    var preloadGroupPreviewChatterCount: Int { get }
}
