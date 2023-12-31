//
//  KaInterface.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/24.
//

import Foundation
import RxRelay
import LarkAccountInterface

#if SUITELOGIN_KA
typealias KaLoginManager = KaLoginService & KaLoginUI & KaLoginInternalService & KAStoreUpdatable
#else
typealias KaLoginManager = KaLoginService & KaLoginUI & KaLoginInternalService
#endif

protocol KaLoginInternalService: AnyObject {
    func getSettingFeature() -> SettingFeature
}

protocol KaLoginUI: AnyObject {
    func kaLoginVC(context: UniContextProtocol) -> UIViewController
    func kaModifyPwdVC() -> UIViewController
}

#if SUITELOGIN_KA
protocol KAStoreUpdatable: AnyObject {
    func updatePreConfig(_ preConfig: PreConfig)
}
#endif

class KaLoginFactory {
    @available(*, deprecated, message: "Only KAR used before and now aligns with SaaS.")
    static func createKaLoginManager(
        loginStateSub: BehaviorRelay<V3LoginState>,
        httpClient: HTTPClient,
        context: UniContextProtocol
    ) -> KaLoginManager {
        #if SUITELOGIN_KA
        if KAFeatureConfigManager.enableKACRC {
            return KaLoginServiceImpl(
                loginStateSub: loginStateSub,
                httpClient: httpClient,
                context: context
            )
        } else {
            return KaLoginManagerPlaceholder()
        }
        #else
        return KaLoginManagerPlaceholder()
        #endif
    }
}
