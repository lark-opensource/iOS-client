//
//  OPPlugin.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/6.
//

import Foundation

@objc
public protocol OPPluginProtocol: OPEventTargetProtocol, OPEventNameFilterProtocol {
    
}

@objc
public protocol OPEventNameFilterProtocol: NSObjectProtocol {
    
    var filters: [String] { get set }
    
}
