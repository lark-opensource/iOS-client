//
//  TenantUniversalSettingConfig.swift
//  LarkSDK
//
//  Created by ByteDance on 2022/8/16.
//

import Foundation
import LarkSDKInterface
import LKCommonsLogging
import RustPB
import LarkContainer
import RxCocoa
import RxSwift
import ThreadSafeDataStructure

final class TenantUniversalSettingConfig: TenantUniversalSettingService, UserResolverWrapper {

    //当撤回有效时间RecallEffectiveTime、二次编辑有效时间EditEffectiveTime拿到这个值时，表示时间不受限制，任何时候都可以撤回或二次编辑
    public static let EffectiveTimeUnlimited: Int64 = -1
    //当撤回有效时间RecallEffectiveTime、二次编辑有效时间EditEffectiveTime拿到这个值时，表示永远不允许编辑/撤回
    public static let EffectiveTimeDoNotAllow: Int64 = 0
    //弹出menu时，如果重新编辑的剩余有效时间小于这个值，会提前拦截，不展示对应的item
    public static let MultiEditEarlyInterceptionTime: TimeInterval = 5

    let userResolver: UserResolver
    let pushCenter: PushNotificationCenter
    @ScopedProvider private var tenantAPI: TenantAPI?
    private var disposeBag = DisposeBag()
    private static let logger = Logger.log(TenantUniversalSettingConfig.self, category: "Module.LarkSDK.TenantSettingConfig")
    private var config: RustPB.Im_V1_TenantMessageConf? {
        get { _config.value }
        set {
            Self.logger.info("config update", additionalData: ["recallEffectiveTime": "\(newValue?.recallEffectiveTime)",
                                                               "editEffectiveTime": "\(newValue?.editEffectiveTime)",
                                                               "inputBoxPlacehold": newValue?.inputBoxPlacehold ?? "",
                                                               "isSupportRestrictMessage": newValue?.isSupportRestrictMessage.stringValue ?? ""])
            _config.value = newValue
        }
    }
    private var _config: SafeAtomic<RustPB.Im_V1_TenantMessageConf?> = nil + .readWriteLock

    func loadTenantMessageConf(forceServer: Bool, onCompleted: ((Error?) -> Void)?) {
        guard let tenantAPI = self.tenantAPI else { return }
        tenantAPI.getTenantMessageConf(confTypes: [
            //全量拉取所有配置
            .editEffectiveTime,
            .recallEffectiveTime,
            .inputBoxPlaceholder,
            .isSupportRestrictMessage
        ], forceServer: forceServer)
        .subscribe(onNext: { [weak self] response in
            self?.config = response.conf
            onCompleted?(nil)
        }, onError: { error in
            onCompleted?(error)
        }).disposed(by: disposeBag)
    }

    /// 是否支持保密消息功能 租户维度
    /// - Returns: 是否支持
    func supportRestrictMessage() -> Bool {
        return config?.isSupportRestrictMessage ?? false
    }

    func getRecallEffectiveTime() -> Int64 {
        return config?.recallEffectiveTime ?? 0
    }

    func getEditEffectiveTime() -> Int64 {
        return config?.editEffectiveTime ?? 0
    }

    func getInputBoxPlaceholder() -> String? {
        guard userResolver.fg.staticFeatureGatingValue(with: "messenger.editor.placeholder") else {
            return nil
        }
        guard let config = config, config.hasInputBoxPlacehold else {
            return nil
        }
        return config.inputBoxPlacehold.isEmpty ? nil : config.inputBoxPlacehold
    }

    func replaceTenantPlaceholderEnable() -> Bool {
        return self.userResolver.fg.dynamicFeatureGatingValue(with: "messenger.editor.placeholder.replace")
    }

    func getIfMessageCanMultiEdit(createTime: TimeInterval) -> Bool {
        let effectiveTime = getEditEffectiveTime()
        if effectiveTime != Self.EffectiveTimeUnlimited,
           Date().timeIntervalSince1970 - createTime > Double(effectiveTime) - Self.MultiEditEarlyInterceptionTime {
            return false
        }
        return true
    }

    func getIfMessageCanRecall(createTime: TimeInterval) -> Bool {
        let effectiveTime = getRecallEffectiveTime()
        if effectiveTime != Self.EffectiveTimeUnlimited,
           Date().timeIntervalSince1970 - createTime > Double(effectiveTime) {
            return false
        }
        return true
    }

    func getIfMessageCanRecallBySelf() -> Bool {
        return getRecallEffectiveTime() != Self.EffectiveTimeDoNotAllow
    }

    init(pushCenter: PushNotificationCenter, userResolver: UserResolver) {
        self.pushCenter = pushCenter
        self.userResolver = userResolver
        configPushCenter()
        Self.logger.info("config init")
    }

    private func configPushCenter() {
        pushCenter.observable(for: PushTenantMessageConf.self)
            .subscribe { [weak self] push in
                self?.config = push.conf
            } onError: { error in
                Self.logger.error("receive PushTenantMessageConf error, error: \(error)")
            }.disposed(by: disposeBag)
    }
}
