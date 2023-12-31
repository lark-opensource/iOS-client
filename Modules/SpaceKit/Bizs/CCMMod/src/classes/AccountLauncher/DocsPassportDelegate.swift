//
//  DocsPassportDelegate.swift
//  CCMMod
//
//  Created by ByteDance on 2023/4/20.
//

import Foundation
import LarkContainer
import BootManager
import RunloopTools
import LarkAccountInterface
import SKFoundation
import SKInfra
import LarkSetting
import RxSwift
import RxCocoa

// DocsLaunchDelegate 迁移用户态之后使用 DocsPassportDelegate
public final class DocsPassportDelegate: PassportDelegate {

    private let resolver: Resolver

    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    private func doTask(task: @escaping () -> Void) {
        if NewBootManager.shared.context.launchOptions != nil {
            task()
        } else {
            RunloopDispatcher.shared.addTask { task() }
        }
    }
}

// MARK: PassportDelegate
extension DocsPassportDelegate {

    /// online 的原因可能是 login、switch、fastLogin，请注意按需要排除 fastLogin 的场景，避免不需要的逻辑
    public func userDidOnline(state: LarkAccountInterface.PassportState) {
        let userID = state.user?.userID
        let compatibleMode = CCMUserScope.compatibleMode
        let userResolver = try? resolver.getUserResolver(userID: userID, compatibleMode: compatibleMode)
        if let ur = userResolver {
            updateUserScopeSwitch(ur)
        }
        
        if state.action == .login { // 原先DocsLaunchDelegate - afterLoginSucceded 方法只在 login 时调用，fastLogin(自动登录)和switch(切换用户)不会调用
            doTask {
                do {
                    let factory = try userResolver?.resolve(assert: DocsViewControllerFactory.self)
                    factory?.larkUserDidLogin(nil, nil) // account参数目前没有使用，所以传入nil
                } catch {
                    DocsLogger.error("resolve DocsViewControllerFactory error:\(error)")
                }
            }
        }
    }

    /// offline 的原因可能是 switch、logout
    public func userDidOffline(state: LarkAccountInterface.PassportState) {
        let userID = state.user?.userID
        let compatibleMode = CCMUserScope.compatibleMode
        do {
            let userResolver = try resolver.getUserResolver(userID: userID, compatibleMode: compatibleMode)
            let factory = try userResolver.resolve(assert: DocsViewControllerFactory.self)
            factory.larkUserDidLogout(nil, nil) // account参数目前没有使用，所以传入nil
        } catch {
            DocsLogger.error("resolve DocsViewControllerFactory error:\(error)")
        }
    }

    /// 用户状态发生变化，包含所有状态的变化
    /// 用户状态分为 online、offline 两种
    public func stateDidChange(state: LarkAccountInterface.PassportState) {

    }
}

private extension DocsPassportDelegate {
    
    func updateUserScopeSwitch(_ userResolver: UserResolver) {
        let key = UserSettingKey.make(userKeyLiteral: "ccm_common_userscope_biz")
        if let object = try? userResolver.resolve(assert: UserScopedObject.self) {
            userResolver.settings.observe(key: key).subscribe(onNext: { [weak self] in
                self?.saveUserScopeSwitch($0)
            }).disposed(by: object.disposeBag)
        }
    }
    
    func saveUserScopeSwitch(_ dict: [String: Any]) {
        //DocsLogger.info("CCM.userScopeFG: userScope:\(dict)")
        CCMUserScope.saveMainSwitchState(dict)
        let bizs = dict["enabled_bizs"] as? [String] ?? []
        CCMUserScope.saveEnabledBizs(bizs)
    }
}

class UserScopedObject {

    let disposeBag = DisposeBag()

}
