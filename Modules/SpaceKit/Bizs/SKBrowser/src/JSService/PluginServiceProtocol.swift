//
//  PluginServiceProtocol.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/3/5.
//

import Foundation

/// 需要工具栏插件的服务
protocol ToolPlugin {
    var tool: BrowserToolConfig? { get }
}
