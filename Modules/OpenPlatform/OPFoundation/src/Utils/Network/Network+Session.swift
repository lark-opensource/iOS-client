//
//  Network+Session.swift
//  TTMicroApp
//
//  Created by Meng on 2021/4/9.
//

import Foundation


@objcMembers
public final class GadgetSessionFactory: NSObject {
    @nonobjc
    public class func storage(for apiContext: OPAPIContextProtocol) -> GadgetSessionStorage {
        return GadgetSessionPlugin(context: apiContext)
    }

    @objc(storageForPluginContext:)
    public class func storage(for pluginContext: BDPPluginContext) -> GadgetSessionStorage {
        return GadgetSessionPlugin(context: pluginContext)
    }

    @objc(storageForAuthModule:)
    public class func storage(for authModule: BDPAuthorization) -> GadgetSessionStorage {
        return GadgetSessionPlugin(authModule: authModule)
    }
}

public enum SessionKey: String {
    case sessionType = "Session-Type"
    case sessionValue = "Session-Value"
    case minaSession = "mina_session"
    case h5Session = "h5_session"
}

final class GadgetSessionPlugin: NSObject, GadgetSessionStorage {

    let storage: GadgetSessionStorage?

    init(context: OPAPIContextProtocol) {
        let uniqueId = context.uniqueID
        switch uniqueId.appType {
        case .gadget, .block:
            self.storage = GadgetMinaSessionPlugin(uniqueId: uniqueId)
        case .webApp:
            self.storage = GadgetH5SessionPlugin(context: context)
        default:
            self.storage = nil
        }
    }

    init(context: BDPPluginContext) {
        guard let uniqueId = context.engine?.uniqueID else {
            self.storage = nil
            return
        }
        switch uniqueId.appType {
        case .gadget, .block:
            self.storage = GadgetMinaSessionPlugin(uniqueId: uniqueId)
        case .webApp:
            self.storage = GadgetH5SessionPlugin(context: context)
        default:
            self.storage = nil
        }
    }

    init(authModule: BDPAuthorization) {
        let uniqueId = authModule.source.uniqueID
        switch uniqueId.appType {
        case .gadget, .block:
            self.storage = GadgetMinaSessionPlugin(uniqueId: uniqueId)
        case .webApp:
            self.storage = GadgetH5SessionPlugin(authModule: authModule)
        default:
            self.storage = nil
        }
    }

    var sessionHeader: [String: String] {
        return storage?.sessionHeader ?? [:]
    }
}

final class GadgetMinaSessionPlugin: NSObject, GadgetSessionStorage {
    private let uniqueId: OPAppUniqueID

    init(uniqueId: OPAppUniqueID) {
        self.uniqueId = uniqueId
    }

    var sessionHeader: [String: String] {
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueId),
              let session = TMASessionManager.shared()?.getSession(common.sandbox) else {
            return [:]
        }
        return [
            SessionKey.sessionType.rawValue: SessionKey.minaSession.rawValue,
            SessionKey.sessionValue.rawValue: session
        ]
    }
}

final class GadgetH5SessionPlugin: NSObject, GadgetSessionStorage {
    private var pluginContext: BDPPluginContext?
    private var apiContext: OPAPIContextProtocol?
    private var authModule: BDPAuthorization?

    init(context: BDPPluginContext) {
        self.pluginContext = context
    }

    init(context: OPAPIContextProtocol) {
        self.apiContext = context
    }

    init(authModule: BDPAuthorization) {
        self.authModule = authModule
    }

    var sessionHeader: [String: String] {
        guard let session = getSession() else { return [:] }
        return [
            SessionKey.sessionType.rawValue: SessionKey.h5Session.rawValue,
            SessionKey.sessionValue.rawValue: session
        ]
    }

    private func getPluginContextSession() -> String? {
        guard let uniqueId = pluginContext?.engine?.uniqueID,
              let auth = BDPModuleManager(of: uniqueId.appType).resolveModule(with: BDPAuthModuleProtocol.self) as? BDPAuthModuleProtocol,
              let session = auth.getSessionContext(pluginContext) else {
            return nil
        }
        return session
    }

    private func getSession() -> String? {
        if let apiContextSession = apiContext?.session {
            return apiContextSession
        }
        if let pluginContextSession = getPluginContextSession() {
            return pluginContextSession
        }
        if let authSession = authModule?.authSyncSession?() {
            return authSession
        }
        assertionFailure()
        return nil
    }
}
