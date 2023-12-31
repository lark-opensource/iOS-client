//
//  SCDebugAssembly.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2022/9/18.
//

import LarkAssembler
import LarkContainer
import LarkDebugExtensionPoint
import LarkSecurityCompliance
import LarkSecurityComplianceInfra
import UIKit
import AppContainer
import LarkPrivacyMonitor
import Swinject
import LarkEMM
import LarkSensitivityControl
#if !canImport(LarkSearch) && canImport(LarkQuickLaunchInterface)
import LarkQuickLaunchInterface
#endif

private var models: [SCDebugModelRegister] = []

public final class SCDebugAssembly: NSObject, LarkAssemblyInterface {
    
    public func registContainer(container: Container) {
        let userContainer = container.inObjectScope(SCContainerSettings.userScope)
        userContainer.register(SCDebugEntrance.self) { resolver in
            return SCDebugEntrance(userResolver: resolver)
        }
        
#if !canImport(LarkSearch) && canImport(LarkQuickLaunchInterface)
        userContainer.register(OpenNavigationProtocol.self) { _ in
            OpenNavigationImpl()
        }
#endif
        
        userContainer.register(SCDebugService.self) { resolver in
            let imp = SCDebugServiceImp(resolver: resolver)
            imp.enableFileOperateLog = {
                UserDefaults.standard.bool(forKey: "file_operate_log_open")
            }
            return imp
        }
        userContainer.register(SecurityPolicyDebugService.self) { resolver in
            guard SecurityPolicyAssembly.enableSecurityPolicyV2 else {
                return SecurityPolicyDebugServiceImp(userResolver: resolver)
            }
            return SecurityPolicyV2.SecurityPolicyDebugServiceImp(userResolver: resolver)
        }
        
        userContainer.register(EMMDebugService.self) { resolver in
            EMMDebugServiceImp(userResolver: resolver)
        }
    }
    
    public func registDebugItem(container: Container) {
        /// 暂时先用 getCurrentUserResolver
        ({ SCDebugItem(resolver: container.getCurrentUserResolver()) }, SectionType.debugTool)
    }
}

extension NSObject {
    @objc
    static func startConfigDebugServiceLoader() {
        SCDebugServiceLoader.currentClass = SCDebugAssembly.self
        // 开启 monitor 线下动态检测能力
        MonitorAutoTestManager.shared.start()
        // 子线程获取可能为nil
        let vendorID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 3) {
            DIDManager.shared.updateVendorID(vendorID)
            _ = DIDManager.shared.detectMigration()
            DIDManager.shared.updateCache()
        }
    }
}

#if !canImport(LarkSearch) && canImport(LarkQuickLaunchInterface)
private final class OpenNavigationImpl: OpenNavigationProtocol {
    func notifyNavigationAppInfos(appInfos: [OpenNavigationAppInfo]) {}
}
#endif
