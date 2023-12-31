//
//  NoPermissionDebugRegister.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2022/10/8.
//

import Foundation
import EENavigator
import LarkContainer
import SwiftyJSON
import LarkUIKit
import LarkAccountInterface
import LarkSecurityCompliance
import LarkSecurityComplianceInfra

final class NoPermissionDebugRegister: SCDebugModelRegister {
    
    let userResolver: UserResolver
    
    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }
    
    func registModels() {
        guard let debugEntrance = try? userResolver.resolve(assert: SCDebugEntrance.self) else { return }
        debugEntrance.regist(section: .conditionAccess) {
            SCDebugModel(cellTitle: "ID围栏", cellType: .normal, normalHandler: {
            Self.navigatorToNoPermissionVC("BLOCKED_BY_IP_RULE") })
        }
        debugEntrance.regist(section: .conditionAccess)  { 
            SCDebugModel(cellTitle: "设备归属", cellType: .normal, normalHandler: {
            Self.navigatorToNoPermissionVC("BLOCKED_BY_DEVICE_OWNERSHIP") })
        }
        debugEntrance.regist(section: .conditionAccess)  { 
            SCDebugModel(cellTitle: "设备可信", cellType: .normal, normalHandler: {
            Self.navigatorToNoPermissionVC("BLOCKED_BY_DEVICE_CREDIBILITY") })
        }
        debugEntrance.regist(section: .conditionAccess) { 
            SCDebugModel(cellTitle: "MFA", cellType: .normal, normalHandler: {
            Self.navigatorToNoPermissionVC("ACCESS_MFA", cellParams: ["mfa-token": "12324174-cqc"]) })
        }
        debugEntrance.regist(section: .conditionAccess)  { 
            SCDebugModel(cellTitle: "web授权页测试PUSH", cellType: .normal, normalHandler: { [weak self] in
            let url = URL(string: "/client/security/bind_device?web_id=123414&user_id=1141414&scheme=scheme")!
            guard let vc = Self.currentVC() else { return }
            self?.navigator.push(url, from: vc) })
        }
        debugEntrance.regist(section: .conditionAccess)  { 
            SCDebugModel(cellTitle: "web授权页测试PRESENT", cellType: .normal, normalHandler: { [weak self] in
            let accountService = implicitResolver?.resolve(PassportService.self)
            let userID = accountService?.foregroundUser?.userID ?? ""
            guard let vc = Self.currentVC() else { return }
            self?.navigator.present(body: NoPermissionAuthBody(webId: "", scheme: "", userId: userID), from: vc) })
        }
        debugEntrance.regist(section: .conditionAccess)  { 
            SCDebugModel(cellTitle: "设备状态页", cellType: .normal, normalHandler: {
            Self.navigatorToDeviceStatusVC() })
        }
        debugEntrance.regist(section: .conditionAccess)  { 
            SCDebugModel(cellTitle: "申报理由页", cellType: .normal, normalHandler: {
            Self.navigatorToDeviceDeclareVC() })
        }
        
    }
    
    // 无权限页面跳转方法
    static func navigatorToNoPermissionVC(_ cellName: String, cellParams: [String: JSON] = [:]) {
        let service = implicitResolver?.resolve(SCDebugService.self)
        service?.gotoNoPermissionPage(cellName, cellParams: cellParams)
    }
    
    static func navigatorToDeviceStatusVC() {
        let service = implicitResolver?.resolve(SCDebugService.self)
        service?.showDeviceStatusPage(isLimited: false)
    }
    
    static func navigatorToDeviceDeclareVC() {
        let service = implicitResolver?.resolve(SCDebugService.self)
        service?.showDeviceDeclarationPage()
    }
    
    static func currentVC() -> UIViewController? {
        return LayoutConfig.currentWindow?.lu.visibleViewController()
    }
}
