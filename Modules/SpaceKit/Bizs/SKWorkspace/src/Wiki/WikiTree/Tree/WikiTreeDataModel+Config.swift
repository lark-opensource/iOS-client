//
//  WikiTreeDataModel+Config.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/8/1.
//

import Foundation
import SKCommon

// 外部使用方传给目录树DataModel的配置，用来处理部分不同场景的特化处理
public struct WikiTreeDataModelConfig {
    public var ignoreCrossMoveSync: Bool
    
    public static let `default` = WikiTreeDataModelConfig(ignoreCrossMoveSync: false)
    
    // 首页共享树config
    public static let homeSharedConfig = WikiTreeDataModelConfig(ignoreCrossMoveSync: true)
    
    public init(ignoreCrossMoveSync: Bool) {
        self.ignoreCrossMoveSync = ignoreCrossMoveSync
    }
}


