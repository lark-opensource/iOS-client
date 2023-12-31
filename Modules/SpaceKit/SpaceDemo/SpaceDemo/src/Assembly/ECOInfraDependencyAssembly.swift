//
//  ECOCookieDependencyAssembly.swift
//  EEMicroAppSDK_Example
//
//  Created by Meng on 2021/2/26.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import Swinject
import ECOInfra
import LarkRustClient
import LarkContainer
import RustPB
import RxSwift
import LKCommonsLogging
import LarkFeatureGating
import LarkSetting
import LarkAssembler

class ECOInfraDependencyAssembly: LarkAssemblyInterface {
    func registContainer(container: Swinject.Container) {

        container.register(ECOConfigDependency.self) { _ in
            return ECOConfigDependencyImpl()
        }
    }

}

class ECOConfigDependencyImpl: ECOConfigDependency {
    var urlSession: URLSession {
        return EMANetworkManager.shared().urlSession
    }

    var needStableJsDebug: Bool {
        false
    }

    var noCompressDebug: Bool {
        false
    }

    var userId: String {
        ""
    }
    
    var configDomain: String {
        ""
    }

    func requestConfigParams() -> [String: Any] {
        return ["userId": "", "larkVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""]
    }

    //接入飞书统一FG
    func getFeatureGatingBoolValue(for key: String, defaultValue: Bool) -> Bool {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key))
    }
    func checkFeatureGating(for key: String, completion: @escaping (Bool) -> Void) {
        completion(FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key)))
    }
    func getStaticFeatureGatingBoolValue(for key: String) -> Bool {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key))
    }
}
