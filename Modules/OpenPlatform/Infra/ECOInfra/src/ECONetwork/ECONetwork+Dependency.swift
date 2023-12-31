//
//  ECONetwork+Dependency.swift
//  ECOInfra
//
//  Created by MJXin on 2021/4/8.
//

import Foundation
import LarkContainer

@objc
public protocol ECONetworkCommonConfiguration: AnyObject {
    static func getLoginParams(withURLString urlString: String) -> [AnyHashable : Any]
    static func getCommonOpenPlatformRequest(withURLString urlString: String) -> [AnyHashable : Any]
    static func getTimeoutWithURLString(_ urlString: String, timeout: TimeInterval) -> TimeInterval
    static func getMethodWithURLString(_ urlString: String, method: String) -> String
    static func addCommonConfiguration(forRequest request: NSMutableURLRequest)
}

@objc(ECONetworkDependency)
@objcMembers
public final class ECONetworkDependencyForObjc: NSObject {
    private class var dependency: ECONetworkDependency? {
        // TODO: 等待主端提供 Optional Provider
        return implicitResolver?.resolve(ECONetworkDependency.self) // Global
    }
    
    public class func deviceID() -> String {
        Self.dependency?.deviceID() ?? ""
    }
    
    public class func networkMonitorEnable() -> Bool {
        Self.dependency?.networkMonitorEnable() ?? false
    }
    
    public class func localLibVersionString() -> String {
        Self.dependency?.localLibVersionString() ?? ""
    }
    
    public class func localLibGreyHash() -> String {
        Self.dependency?.localLibGreyHash() ?? ""
    }
    
    public class func commonConfiguration() -> ECONetworkCommonConfiguration.Type? {
        Self.dependency?.commonConfiguration()
    }
    
    public class func tempDirectory() -> URL? {
        Self.dependency?.networkTempDirectory()
    }
    
    public class func getUserAgentString() -> String {
        Self.dependency?.getUserAgentString() ?? ""
    }
    
    public class func networkTempDirectory() -> URL? {
        Self.dependency?.networkTempDirectory()
    }
    
    
}
/// ECONetworkDependency
public protocol ECONetworkDependency: AnyObject {
    func deviceID() -> String
    func getUserAgentString() -> String
    func networkMonitorEnable() -> Bool
    func localLibVersionString() -> String
    func localLibGreyHash() -> String
    func commonConfiguration() -> ECONetworkCommonConfiguration.Type?
    func networkTempDirectory() -> URL?
    
}
