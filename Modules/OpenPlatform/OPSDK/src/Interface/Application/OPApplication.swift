//
//  OPApplication.swift
//  OPSDK
//
//  Created by yinyuan on 2020/10/26.
//

import Foundation
import LarkOPInterface
import ECOProbe
import LKCommonsLogging
import OPFoundation

private let logger = Logger.oplog(OPApplication.self)

/// OPApplicationProtocol 的指定实现，各应用形态通过扩展支持 create 函数
@objcMembers public final class OPApplication: OPNode, OPApplicationProtocol {

    /// 上下文信息。
    public let applicationContext: OPApplicationContext
    
    private let containerServices: [OPAppType: OPContainerServiceProtocol]
    
    init(applicationServiceContext: OPApplicationServiceContext, appID: String, containerServices: [OPAppType: OPContainerServiceProtocol]) {
        logger.info("OPApplication.init. appID:\(appID)")
        self.applicationContext = OPApplicationContext(applicationServiceContext: applicationServiceContext, appID: appID)
        self.containerServices = containerServices
    }
    
    public func createContainer(
        uniqueID: OPAppUniqueID,
        containerConfig: OPContainerConfigProtocol
    ) -> OPContainerProtocol {
        logger.info("OPApplication.createContainer. uniqueID:\(uniqueID) containerConfig:\(containerConfig)")
        let defaultContainer = {  () -> OPContainerProtocol in
            // 不可能运行到这里，如果运行到这里，请立即排查解决是否配置正确
            logger.error("Please check your logic right now! You must register a valid OPAppTypeAbilityProtocol for the appType.")
            assertionFailure("Please check your logic right now! You must register a valid OPAppTypeAbilityProtocol for the appType.")
            return OPBaseContainer(
                containerContext: OPContainerContext(
                    applicationContext: self.applicationContext,
                    uniqueID: uniqueID,
                    containerConfig: containerConfig
                ),
                updater: nil
            )
        }
        
        guard let containerService = containerServices[uniqueID.appType] else {
            logger.warn("return defaultContainer")
            return defaultContainer()
        }
        do {
            let container = try containerService.appTypeAbility.createContainer(
                applicationContext: applicationContext,
                uniqueID: uniqueID,
                containerConfig: containerConfig
            )
            container.addLifeCycleDelegate(delegate: self)
            addChild(node: container)
            return container
        } catch {
            logger.error("createContainer exception. \(error)")
            return defaultContainer()
        }
    }
    
    public func getContainer(uniqueID: OPAppUniqueID) -> OPContainerProtocol? {
        return getChild(where: { (node) -> Bool in
            if let container = node as? OPContainerProtocol,
               container.containerContext.uniqueID.isEqual(uniqueID) {
                return true
            }
            return false
        }) as? OPContainerProtocol
    }
    
    public func removeContainer(container: OPContainerProtocol) {
        logger.info("OPApplication.removeContainer. uniqueID:\(container.containerContext.uniqueID)")
        // 移除子节点
        if !removeChild(node: container) {
            logger.info("OPApplication.removeContainer but not exist. uniqueID:\(container.containerContext.uniqueID)")
            return
        }
        
        if container.containerContext.availability != .destroyed {
            logger.info("OPApplication.removeContainer & destroy. uniqueID:\(container.containerContext.uniqueID)")
            container.destroy(monitorCode: OPSDKMonitorCode.cancel)
        }
    }
    
    public override var description: String {
        "OPApplication(\(applicationContext.appID)"
    }
    
}

extension OPApplication: OPContainerLifeCycleDelegate {
    public func containerDidLoad(container: OPContainerProtocol) {
        logger.info("containerDidLoad. uniqueID:\(container.containerContext.uniqueID)")
    }
    
    public func containerDidReady(container: OPContainerProtocol) {
        logger.info("containerDidReady. uniqueID:\(container.containerContext.uniqueID)")
    }
    
    public func containerDidFail(container: OPContainerProtocol, error: OPError) {
        logger.error("containerDidFail. uniqueID:\(container.containerContext.uniqueID) error:\(error)")
    }
    
    public func containerDidUnload(container: OPContainerProtocol) {
        logger.info("containerDidUnload. uniqueID:\(container.containerContext.uniqueID)")
    }
    
    public func containerDidDestroy(container: OPContainerProtocol) {
        logger.info("containerDidDestroy. uniqueID:\(container.containerContext.uniqueID)")
        // 如果有人直接调用了 container 的 destroy 接口，这里还需要主动移出
        removeContainer(container: container)
    }
    
    public func containerDidShow(container: OPContainerProtocol) {
        logger.info("containerDidShow. uniqueID:\(container.containerContext.uniqueID)")
    }
    
    public func containerDidHide(container: OPContainerProtocol) {
        logger.info("containerDidHide. uniqueID:\(container.containerContext.uniqueID)")
    }
    
    public func containerDidPause(container: OPContainerProtocol) {
        logger.info("containerDidPause. uniqueID:\(container.containerContext.uniqueID)")
    }
    
    public func containerDidResume(container: OPContainerProtocol) {
        logger.info("containerDidResume. uniqueID:\(container.containerContext.uniqueID)")
    }
    
    public func containerConfigDidLoad(container: OPContainerProtocol, config: OPProjectConfig) {
        logger.info("containerConfigDidLoad. uniqueID:\(container.containerContext.uniqueID)")
    }
}

extension OPApplication {
    
    public override func prepareEventContext(context: OPEventContext) {
        logger.info("prepareEventContext.")
        super.prepareEventContext(context: context)
        // 注入 Context
        context.applicationContext = applicationContext
    }
    
}
