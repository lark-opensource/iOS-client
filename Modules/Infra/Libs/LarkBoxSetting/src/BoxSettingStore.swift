//
//  BoxSettingStore.swift
//  LarkBoxSetting
//
//  Created by aslan on 2023/3/16.
//

import Foundation
import LarkStorage
import LKCommonsLogging
import LarkSetting
import LarkAccountInterface
import LarkContainer

public struct BoxSettingStore {

    static let logger = Logger.log(BoxSetting.self)

    private var store: KVStore = KVStores.udkv(space: .global, domain: Domain.biz.core.child(BoxSettingConf.domain))

    private var lock = NSLock()

    public init() {}

    private func isBlockTenant() -> Bool {
        guard let passportService = Container.shared.resolve(PassportService.self) else {
            return false
        }

        guard let user = passportService.foregroundUser else {//Global  这里改造成本有些高，串用户风险应该不大
            return false
        }

        if let settingConfig = try? SettingManager.shared.setting( //Global
            with: BoxSettingConf.settingField
        ) as? [String: [String]] {
            let tenantID = user.tenant.tenantID
            let tenants = settingConfig["tenants"] as? [String] ?? []
            Self.logger.info("tenants: \(tenants)")
            let tenantId = tenantID.data(using: .utf8)?.base64EncodedString() ?? ""
            Self.logger.info("tenant ID: \(tenantID), base64: \(tenantId)")
            if (tenants.contains(tenantId)) {
                return true
            }
        }
        return false
    }

    public func save(config: Bool) {
        lock.lock()
        defer {
            lock.unlock()
        }
        Self.logger.info("save setting config: \(config)")
        if !isBlockTenant() {
            /// 审核租户开关恒为true，不需要发送变更信号，业务依赖该信号实时响应策略
            BoxSetting.shared.dataChangeSubject.onNext(config)
        }
        self.store.set(config, forKey: BoxSettingConf.storeKey)
    }

    internal func getConfig() -> Bool {
        lock.lock()
        defer {
            lock.unlock()
        }

        /// 如果是黑名单里租户，开关恒为true，即不支持动态能力和敏感入口
        if isBlockTenant() {
            Self.logger.info("block user in list, return true")
            return true
        }

        if let isOn: Bool = self.store.value(forKey: BoxSettingConf.storeKey) {
            Self.logger.info("get setting config: \(isOn)")
            return isOn
        }
        /// 都默认值返回false，不影响正常使用
        return false
    }
}

enum BoxSettingConf {
    static let domain = "BoxSetting"
    static let storeKey = "box_setting"
    static let settingField = UserSettingKey.make(userKeyLiteral: "box_setting_blacklist")
}
