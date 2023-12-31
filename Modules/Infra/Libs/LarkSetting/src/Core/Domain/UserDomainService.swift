//
//  UserDomainService.swift
//  LarkSetting
//
//  Created by ByteDance on 2023/10/31.
//

import Foundation
import LarkContainer
import LarkEnv
import LarkAccountInterface
import RxSwift
import EEAtomic


public protocol UserDomainService {

    /// 获取用户域名
    /// 取值策略:
    /// 1. 获取user_id对应的域名
    /// 2. 如果用户域名不存在, 使用user env对应的域名
    /// 3. user env对应的域名不存在, 从包兜底域名中取
    func getDomainSetting() -> DomainSetting

    /// 监听域名配置变更
    func observeDomainSettingUpdate() -> Observable<Void>

    /// 更新用户域名
    func updateUserDomainSetting(new domainSettings: DomainSetting)
}

struct UserDomainServiceImpl: UserDomainService {
    
    let userResolver: UserResolver

    init(_ resolver: UserResolver) {
        userResolver = resolver
    }

    func getDomainSetting() -> DomainSetting {
        return DomainSettingManager.shared.getUserDomainSettings(with: userResolver.userID, fallback: getUserEnv())
    }

    func observeDomainSettingUpdate() -> Observable<Void> {
        return DomainSettingManager.shared.observeDomainSettingUpdate(with: userResolver.userID)
    }

    func updateUserDomainSetting(new domainSettings: DomainSetting) {
        if userResolver.foreground {
            DomainSettingManager.shared.beforeFroniterDomainUpdate(domain: domainSettings)
        }
        DomainSettingManager.shared.updateUserDomainSettings(with: userResolver.userID, new: domainSettings)
        if userResolver.foreground {
            // 触发之前的更新
            DomainSettingManager.shared.triggerFroniterDomainUpdate()
        }
    }

    private func getUserEnv() -> Env {
        var userEnv = (try? userResolver.resolve(assert: UserEnvironmentService.self))?.userEnvironment.1
        if userEnv == nil {
            userEnv = userResolver.resolve(GlobalEnvironmentService.self)?.packageEnvironment.1
        }
        return userEnv ?? EnvManager.getPackageEnv()
    }
}
