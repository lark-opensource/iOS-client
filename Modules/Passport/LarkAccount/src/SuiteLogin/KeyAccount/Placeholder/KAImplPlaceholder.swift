//
//  KAImplPlaceholder.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/24.
//

import Foundation
import LarkAccountInterface

class KaLoginManagerPlaceholder: KaLoginManager {

    enum KaPlaceholderError: Error, CustomStringConvertible {
        case noImpl

        var description: String {
            switch self {
            case .noImpl:
                return "KaPlaceholderError.noImpl"
            }
        }
    }
    func getKaConfig() -> [String: Any]? {
        return nil
    }

    func getExtraIdentity(onSuccess: @escaping ([String: Any]) -> Void, onError: @escaping (Error) -> Void) {
        onError(KaPlaceholderError.noImpl)
    }

    func kaLoginResult(args: [String: Any]) { }

    func switchIdp(_ idp: String) { }

    func kaLoginVC(context: UniContextProtocol) -> UIViewController {
        return UIViewController()
    }

    func kaModifyPwdVC() -> UIViewController {
        return UIViewController()
    }

    func getSettingFeature() -> SettingFeature {
        return .init()
    }
    
    func updateExtraIdentity(_ extraIdentity: ExtraIdentity) { }

    #if SUITELOGIN_KA
    func updatePreConfig(_ preConfig: PreConfig) { }
    #endif
}
