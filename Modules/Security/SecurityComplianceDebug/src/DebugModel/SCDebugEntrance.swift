//
//  DebugEntrance.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2022/9/18.
//

import Foundation
import LarkContainer
import LarkDebugExtensionPoint
import LarkSecurityComplianceInfra

public final class SCDebugEntrance {
    public typealias SCDebugModelProvider = () -> SCDebugModel
    public typealias SCDebugRedirectorProvider = ([SCDebugModel], String) -> Void

    private let userResolver: UserResolver

    private var isInitial: Bool = false

    private(set) var modelProviders: [SCDebugSectionType: [SCDebugModelProvider]] = [:]

    private(set) var redirectorProviders: [SCDebugSectionType: SCDebugRedirectorProvider] = [:]

    private var defaultRedirector: SCDebugRedirectorProvider

    private var models: [SCDebugModelRegister] = []

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.defaultRedirector = { (model, title) in
            guard let fromVC = userResolver.navigator.mainSceneTopMost else { return }
            let vc = SCDebugSectionViewController(model: model)
            vc.title = title
            userResolver.navigator.push(vc, from: fromVC)
        }
    }

    public func config() {
        guard !isInitial else { return }
        isInitial = true
        models = registerTypes.map({ $0.init(resolver: userResolver) })
        models.forEach { $0.registModels() }
    }

    public func regist(section: SCDebugSectionType,
                       _ modelProvider: @escaping SCDebugModelProvider) {
        if modelProviders[section] == nil {
            modelProviders.updateValue([SCDebugModelProvider](), forKey: section)
        }
        modelProviders[section]?.append(modelProvider)
    }

    public func registRedirectorForSection(section: SCDebugSectionType,
                                            redirectBlock: @escaping SCDebugRedirectorProvider) {
        guard redirectorProviders[section] == nil else { return }
        redirectorProviders[section] = redirectBlock
    }

    public func generateSectionViewModels(section: SCDebugSectionType) -> [SCDebugModel] {
        let debugModelHandlers = modelProviders[section]
        let models = debugModelHandlers?.map { $0() }
        return models ?? []
    }

    public func generateRedirectorForSection(section: SCDebugSectionType) -> SCDebugRedirectorProvider {
        guard let redirector = redirectorProviders[section] else { return
            defaultRedirector
        }
        return redirector
    }
}

private let registerTypes: [SCDebugModelRegister.Type] = [
    DefaultDebugRegister.self,
    SensitivityControlModelRegister.self,
    NoPermissionDebugRegister.self,
    PasteProtectionRegister.self,
    FileAppealDebugRegister.self,
    ScreenProtectionDebugRegister.self,
    PolicyEngineRegister.self,
    AppLockDebugRegister.self,
    SecurityAuditRegister.self,
    FileCryptoDebugRegister.self,
    NetworkControlRegister.self,
    EncryptionUpgradeDebugRegister.self,
    SettingsRegister.self,
    SecurityPolicyDebugRegister.self
]
