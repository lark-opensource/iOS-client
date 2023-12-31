//
//  OPJSLoadScript.swift
//  OPJSEngine
//
//  Created by Jiayun Huang on 2022/2/21.
//

import Foundation

@objc public protocol OPJSLoadScript: AnyObject {
    func loadScript(relativePath: NSString, requiredModules: NSArray) -> Any?
}
