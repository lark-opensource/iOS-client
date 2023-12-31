//
//  OPApplicationService.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/3.
//

import Foundation
import Swinject
import ECOProbe
import LKCommonsLogging
import OPFoundation

private let logger = Logger.oplog(OPApplicationService.self)

/// OPApplicationServiceProtocol 的一个实现。提供一个 current 全局实例。
@objcMembers public final class OPApplicationService: OPNode, OPApplicationServiceProtocol, OPApplicationConfigProtocol {

    public let applicationServiceContext: OPApplicationServiceContext
    
    public let accountConfig: OPAppAccountConfig

    public let envConfig: OPAppEnvironment

    public let domainConfig: OPAppDomainConfig

    public static var notify: (() -> Void)?
    
    private var typePluginManager: [OPAppType: OPPluginManager] = [:]
    
    private var containerServices: [OPAppType: OPContainerServiceProtocol] = [:]

    /// Lark 体系的依赖注入处理器
    public private(set) var resolver: Resolver?
    
    /// 默认提供的全局实例
    public static var current: OPApplicationService {
        if let service = sharedWithConfig {
            return service
        } else {
            assert(false, "setupConfig must be called before use")
            return notSetupedService
        }
    }

    private static var sharedWithConfig: OPApplicationService?
    
    // 无效的兜底配置
    private static var notSetupedService: OPApplicationService = OPApplicationService(
        accountConfig: OPAppAccountConfig(userSession: "", accountToken: "", userID: "", tenantID: ""),
        envConfig: OPAppEnvironment(envType: .online, larkVersion: "", language: ""),
        domainConfig: OPAppDomainConfig(openDomain: "", configDomain: "", pstatpDomain: "", vodDomain: "", snssdkDomain: "", referDomain: "", appLinkDomain: "", openAppInterface: "", webViewSafeDomain: ""),
        resolver: nil)

    public static func setupGlobalConfig(accountConfig: OPAppAccountConfig, envConfig: OPAppEnvironment, domainConfig: OPAppDomainConfig, resolver: Resolver?) {
        logger.info("setupGlobalConfig. accountToken:\(accountConfig.accountToken), language:\(envConfig.language), larkVersion:\(envConfig.larkVersion), openAppInterface:\(domainConfig.openAppInterface)")
        var oldSharedWithConfig = sharedWithConfig  // 需要先保持，否则 sharedWithConfig 的自动清理内会同步调用 current，将会导致 current set 和 get 的递归冲突
        OPApplicationService.sharedWithConfig = OPApplicationService(
            accountConfig: accountConfig,
            envConfig: envConfig,
            domainConfig: domainConfig,
            resolver: resolver
        )
        oldSharedWithConfig = nil
    }

    private init(accountConfig: OPAppAccountConfig, envConfig: OPAppEnvironment, domainConfig: OPAppDomainConfig, resolver: Resolver?) {
        logger.info("init")
        self.accountConfig = accountConfig
        self.envConfig = envConfig
        self.domainConfig = domainConfig
        self.applicationServiceContext = OPApplicationServiceContext()
        self.resolver = resolver
        super.init()
        
        setupNotifications()
    }
        
    public func createApplication(appID: String) -> OPApplicationProtocol {
        logger.info("createApplication. appID:\(appID)")
        // 先移除
        removeApplication(appID: appID)
        let application = OPApplication(applicationServiceContext: applicationServiceContext, appID: appID, containerServices: containerServices)
        addChild(node: application)
        return application
    }
    
    public func getApplication(appID: String) -> OPApplicationProtocol? {
        return getChild(where: { (node) -> Bool in
            if let application = node as? OPApplicationProtocol, application.applicationContext.appID == appID {
                return true
            }
            return false
        }) as? OPApplication
    }
    
    public func removeApplication(appID: String) {
        logger.info("removeApplication. \(appID)")
        guard let child = getApplication(appID: appID) else {
            return
        }
        _ = removeChild(node: child)
    }
    
    public override var description: String {
        "OPApplicationService"
    }
    
    // TODO: 除此之外，还需要支持定义条件的 plugin 注入
    public func pluginManager(for type: OPAppType) -> OPPluginManagerProtocol {
        _pluginManager(for: type)
    }
    
    /// 注册应用类型相关的全局服务
    public func registerContainerService(for type: OPAppType, service: OPContainerServiceProtocol) {
        logger.info("registerContainerService. type:\(type.rawValue)")
        containerServices[type] = service
    }

    /// 获取应用类型相关的全局服务
    public func containerService(for type: OPAppType) -> OPContainerServiceProtocol? {
        containerServices[type]
    }
    
    public func getContainer(uniuqeID: OPAppUniqueID?) -> OPContainerProtocol? {
        guard let uniuqeID = uniuqeID else {
            logger.warn("getContainer uniuqeID is nil")
            return nil
        }
        return getApplication(appID: uniuqeID.appID)?.getContainer(uniqueID: uniuqeID)
    }
    
    public func removeContainer(uniuqeID: OPAppUniqueID?) {
        logger.info("removeContainer. uniuqeID:\(String(describing: uniuqeID))")
        guard let uniuqeID = uniuqeID else {
            return
        }
        guard let application = getApplication(appID: uniuqeID.appID) else {
            logger.info("application is nil. uniuqeID:\(String(describing: uniuqeID))")
            return
        }
        guard let container = application.getContainer(uniqueID: uniuqeID) else {
            logger.info("container is nil. uniuqeID:\(String(describing: uniuqeID))")
            return
        }
        application.removeContainer(container: container)
    }
}

/// 支持对一个 appType 的所有 Application 同时设置 plugin
extension OPApplicationService {
    
    private func _pluginManager(for type: OPAppType) -> OPPluginManager {
        if let pluginManager = typePluginManager[type] {
            return pluginManager
        } else {
            let pluginManager = OPPluginManager()
            typePluginManager[type] = pluginManager
            return pluginManager
        }
    }
    
    public override func interceptEvent(event: OPEvent, callback: OPEventCallback) -> Bool {
        if let appType = event.context.containerContext?.uniqueID.appType {
            // 声明了 appType
            if _pluginManager(for: appType).interceptEvent(event: event, callback: callback) {
                return true
            }
        }
        return super.interceptEvent(event: event, callback: callback)
    }
    
    public override func handleEvent(event: OPEvent, callback: OPEventCallback) -> Bool {
        if let appType = event.context.containerContext?.uniqueID.appType {
            // 声明了 appType
            if _pluginManager(for: appType).handleEvent(event: event, callback: callback) {
                return true
            }
        }
        return super.handleEvent(event: event, callback: callback)
    }
    
    private func setupNotifications() {
        logger.info("setupNotifications")
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(notification:)), name: NSNotification.Name(rawValue: "kBDPInterruptionNotification"), object: nil)
    }
    
    @objc dynamic private func handleInterruption(notification: Notification) {
        let isInterrupted = notification.userInfo?["kBDPInterruptionStatusUserInfoKey"] as? Bool ?? false
        logger.info("handleInterruption \(isInterrupted)")
        _ = getChild { (node) -> Bool in
            _ = node.getChild { (node) -> Bool in
                if let container = node as? OPContainerProtocol {
                    if isInterrupted {
                        container.notifyResume()
                    } else {
                        container.notifyPause()
                    }
                }
                return false
            }
            return false
        }
    }
    
}
