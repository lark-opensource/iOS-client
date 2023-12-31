//
//  WABridgeServiceType.swift
//  WebAppBridge
//
//  Created by lijuyou on 2023/11/19.
//

import Foundation

/// BridgeService类型
///   方便管理不同类型的Service，也可以拥有不同的生命周期。
///   使用方可以根据需要自行扩展。如扩展出docx/sheet等
public struct WABridgeServiceType: Hashable, RawRepresentable {
    
    public static let base = WABridgeServiceType("base")    //最基础的Service，生命周期
    public static let UI = WABridgeServiceType("UI")        //UI相关Service，需要在打开页面后才能调用
    
    public var rawValue: String
    public init(_ str: String) {
        self.rawValue = str
    }

    public init(rawValue: String) {
        self.init(rawValue)
    }

    public static func == (lhs: WABridgeServiceType, rhs: WABridgeServiceType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
