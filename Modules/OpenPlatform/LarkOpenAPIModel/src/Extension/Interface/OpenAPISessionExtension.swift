//
//  OpenAPISessionExtension.swift
//  LarkOpenPluginManager
//
//  Created by baojianjun on 2023/6/10.
//

import Foundation

public protocol OpenAPISessionExtension: AnyObject {
    
    func session() -> String
    
    func sessionHeader() -> [String: String]
}
