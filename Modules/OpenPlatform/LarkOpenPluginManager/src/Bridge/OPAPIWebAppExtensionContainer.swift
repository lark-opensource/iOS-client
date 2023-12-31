//
//  OPAPIWebAppExtensionContainer.swift
//  LarkOpenPluginManager
//
//  Created by baojianjun on 2023/7/12.
//

import Foundation

public protocol OPAPIWebAppExtensionContainer {
    func register(into pluginManager: OpenPluginManager)
}
