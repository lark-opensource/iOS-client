//
//  KaStore.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/22.
//

import Foundation
import LKCommonsLogging

class KaStore {

    static let logger = Logger.log(KaStore.self, category: "SuiteLogin.KaStore")

    private var identityKey: String = genKey("com.bytedance.ee.ka.identity")
    private var preConfigKey: String = genKey("com.bytedance.ee.ka.preConfig")
    private var indicateIdpTypeKey: String = genKey("com.bytedance.ee.ka.indicateIdpType")

    let userDefaults: UserDefaults

    init() {
        if let ud = UserDefaults(suiteName: "com.bytedance.ee.ka") {
            userDefaults = ud
        } else {
            userDefaults = UserDefaults.standard
            KaStore.logger.error("UserDefaults init with suiteName failed.")
        }
    }

    var preConfig: PreConfig? {
        get {
            guard let data = userDefaults.data(forKey: preConfigKey) else {
                KaStore.logger.warn("get preConfig from userDefaults nil")
                return nil
            }
            do {
                let decoder = JSONDecoder()
                let conf = try decoder.decode(PreConfig.self, from: data)
                KaStore.logger.info("get preConfig success")
                return conf
            } catch {
                KaStore.logger.error("decode data to preConfig error: \(error)")
                return nil
            }

        }
        set {
            guard let nValue = newValue else {
                KaStore.logger.warn("preConfig store nil")
                userDefaults.set(nil, forKey: preConfigKey)
                return
            }
            do {
                let data = try nValue.asData()
                userDefaults.setValue(data, forKey: preConfigKey)
                KaStore.logger.info("store preConfig success")
                userDefaults.synchronize()
            } catch {
                KaStore.logger.error("encode preConfig to data error: \(error)")
            }
        }
    }

    var identity: KaIdentity? {
        get {
            guard let data = userDefaults.data(forKey: identityKey) else {
                KaStore.logger.warn("get identity from userDefaults nil")
                return nil
            }
            do {
                let decoder = JSONDecoder()
                let id = try decoder.decode(KaIdentity.self, from: data)
                KaStore.logger.info("get identity success")
                return id
            } catch {
                KaStore.logger.error("decode data to identity error: \(error)")
                return nil
            }

        }
        set {
            guard let nValue = newValue else {
                KaStore.logger.warn("identity store nil")
                userDefaults.set(nil, forKey: identityKey)
                return
            }
            do {
                let data = try nValue.asData()
                userDefaults.setValue(data, forKey: identityKey)
                KaStore.logger.warn("store identity success")
                userDefaults.synchronize()
            } catch {
                KaStore.logger.error("encode identity to data error: \(error)")
            }
        }
    }

    /// indicateIdp for KA  DEBUG
    var indicateIdpType: String? {
        get {
            let value = userDefaults.string(forKey: indicateIdpTypeKey)
            KaStore.logger.info("get defaultIdp: \(String(describing: value))")
            return value
        }
        set {
            KaStore.logger.info("set defaultIdp: \(String(describing: newValue))")
            userDefaults.setValue(newValue, forKey: indicateIdpTypeKey)
        }
    }

    func removeAll() {
        KaStore.logger.info("remove all ka storage")
        for key in [identityKey, preConfigKey] {
            userDefaults.removeObject(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
        userDefaults.synchronize()
        UserDefaults.standard.synchronize()
    }

}
