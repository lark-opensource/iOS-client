//
//  OPApplicationServiceProtocol.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/16.
//

import Foundation
import FMDB
import OPFoundation

@objcMembers public final class OPApplicationServiceContext: NSObject {
    
    // 整个应用的活跃状态
    public internal(set) var applicationActive: Bool
    
    public override init() {
        // 应用创建时的状态
        applicationActive = UIApplication.shared.applicationState != .background
    }
    
}

/// 管理所有应用的服务类，管理了各应用的生命周期，包括创建、获取、移除等。
public protocol OPApplicationServiceProtocol: OPNodeProtocol {
    
    var applicationServiceContext: OPApplicationServiceContext { get }
    
    /// 创建一个 Application
    ///
    /// 由于一个 appID 只会有一个 Application 实例，所以如果已经存在一个对应的 Application 实例，会先杀死该实例然后再重新创建。
    /// 如果只是希望获取一个已经创建的 Application，可以使用 getApplication 接口
    /// - Parameter appID: appID
    /// - returns: 返回一个 OPApplication 实例
    func createApplication(appID: String) -> OPApplicationProtocol
        
    
    /// 获取一个已经创建的 Application
    /// - Parameter appID: appID
    /// - Returns: 返回 OPApplicationProtocol 实例。如果未创建则返回 nil
    func getApplication(appID: String) -> OPApplicationProtocol?
    
    
    /// 移除一个 Application，会回收相关资源
    /// - Parameter appID: appID
    func removeApplication(appID: String)

    /// 一种类型的 Application 的公共 PluginManager
    func pluginManager(for type: OPAppType) -> OPPluginManagerProtocol
    
    /// 注册应用类型相关的全局服务
    func registerContainerService(for type: OPAppType, service: OPContainerServiceProtocol)

    /// 获取应用类型相关的全局服务
    func containerService(for type: OPAppType) -> OPContainerServiceProtocol?
    
    /// 帮助函数：获取当前正在运行的容器实例
    func getContainer(uniuqeID: OPAppUniqueID?) -> OPContainerProtocol?
    
    /// 帮助函数：快速清理一个正在运行的容器实例
    func removeContainer(uniuqeID: OPAppUniqueID?)
}
