//
//  PassportDebugItemRegist.swift
//  PassportDebug
//
//  Created by ByteDance on 2022/7/18.
//

import Foundation
import LarkDebugExtensionPoint
import LarkAccountInterface
import EENavigator
import LarkAssembler

struct PassportDebugItem: DebugCellItem {
    let title = "Passport 调试"
    let type: DebugCellType = .disclosureIndicator
    
    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let vc = PassportDebugViewController()
        Navigator.shared.push(vc, from: debugVC)
    }
    init() {
    }
}

@objc public final class PassportDebugItemRegist: NSObject {
    @DebugItemFactory
    static func registDebugItems() {
        /// 老的
        ({ SwitchDevDebugItem(accountService: AccountServiceAdapter.shared) }, SectionType.switchEnv)
        ({ UserIDDebugItem(accountManager: AccountServiceAdapter.shared) }, SectionType.basicInfo)
        ({ TenantIDDebugItem(accountManager: AccountServiceAdapter.shared) }, SectionType.basicInfo)
        ({ DeviceIDItem(accountManager: AccountServiceAdapter.shared) }, SectionType.basicInfo)
        ({ InstallIDItem(accountManager: AccountServiceAdapter.shared) }, SectionType.basicInfo)
        ({ AppLogDeviceIDItem(accountManager: AccountServiceAdapter.shared) }, SectionType.basicInfo)
    }

    @objc static public func regist() {
        DispatchQueue.main.async {
            var cellItems = DebugCellItemRegistries[.debugTool] ?? []
            cellItems.insert({
                PassportDebugItem()
            }, at: 0)
            DebugCellItemRegistries[.debugTool] = cellItems
        }
        registDebugItems()
        PassportDebugRegistry.registerDebugItem(
            SwitchDevDebugItem(accountService: AccountServiceAdapter.shared),
            to: .debugTool)
        PassportDebugRegistry.registerDebugItem(RustNetworkDebugItem(), to: .debugTool)
        PassportDebugRegistry.registerDebugItem(FetchClientLogItem(), to: .debugTool)
        PassportDebugRegistry.registerDebugItem(BOETTEnvItem(), to: .debugTool)
        PassportDebugRegistry.registerDebugItem(ShowEnvInfoItem(), to: .debugTool)
        PassportDebugRegistry.registerDebugItem(NetworkDebugToastItem(), to: .debugTool)
        PassportDebugRegistry.registerDebugItem(NetworkInfoDebugItem(), to: .debugTool)
        EnvInfoManager.shared.initEnvInfoView()
        
    }
}
