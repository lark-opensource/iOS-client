//
//  OPApplicationProtocol.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/16.
//

import Foundation
import OPFoundation

/// 应用协议
///
/// 提供 Application 上下文信息，以及 Container 的管理能力
///
/// please add extenssion functions for the  new appType in your module
/// ```
///    extenssion OPApplication{
///
///         public func create[AppType]Container(
///             appIdentifier: String,
///             containerConfig: OP[AppType]ContainerConfigProtocol
///         ) -> OP[AppType]ContainerProtocol {
///             // new instance for the appType
///             let container = OP[AppType]Container(
///                 applicationContext: applicationContext,
///                 appIdentifier: appIdentifier,
///                 containerConfig: containerConfig
///             )
///             // add container as child node
///             addChild(node: container)
///
///             return container
///         }
///    }
/// ```
@objc public protocol OPApplicationProtocol: OPNodeProtocol {
    
    /// Application 上下文
    var applicationContext: OPApplicationContext { get }
    
    
    /// 创建一个 container
    /// - Parameters:
    ///   - uniqueID: OPAppUniqueID
    ///   - containerConfig: OPContainerConfigProtocol
    func createContainer(
        uniqueID: OPAppUniqueID,
        containerConfig: OPContainerConfigProtocol
    ) -> OPContainerProtocol
    
    
    /// 获取一个正在运行的 Container
    /// - Parameters:
    ///   - uniqueID: OPAppUniqueID
    func getContainer(uniqueID: OPAppUniqueID) -> OPContainerProtocol?
    
    /// 移除一个 Container 并回收相关资源
    ///
    /// 如果该 Container 正在运行或显示，会强制退出
    /// - Parameter container: OPContainerProtocol
    func removeContainer(container: OPContainerProtocol)
}


/// Application 上下文
///
/// - Note: ⚠️该对象在体系内广泛传播和被持有，因此不允许强引用持有大的对象，否则可能会造成严重的内存泄露。如果一定要持有大对象，请使用 weak。
/// - Note: ⚠️只有在体系内被广泛传播和使用的信息，才有资格放入Context对象之内。该对象的所有增加项都应当得到充分的考虑和严谨的评估。
@objcMembers public final class OPApplicationContext: NSObject {
    
    public let applicationServiceContext: OPApplicationServiceContext
    
    /// Application 全局唯一的 ID
    public let appID: String
    
    public init(applicationServiceContext: OPApplicationServiceContext, appID: String) {
        self.applicationServiceContext = applicationServiceContext
        self.appID = appID
    }
}
