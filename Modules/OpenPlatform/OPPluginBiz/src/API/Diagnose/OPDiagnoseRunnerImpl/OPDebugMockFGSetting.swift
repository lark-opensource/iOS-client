//
//  OPDebugMockFGSetting.swift
//  EEMicroAppSDK
//
//  Created by qsc on 2023/4/25.
//

import Foundation
import LKCommonsLogging
#if ALPHA
import LarkSetting
import LarkStorage
import LarkContainer
import LarkAccountInterface
import LarkCache
import OPSDK

fileprivate let logger = Logger.oplog(OPDebugMockFGSetting.self, category: "OPDebugMockFGSetting")

final class OPDebugMockFGSetting: OPDiagnoseBaseRunner {
    
    public override func exec(with context: OPDiagnoseRunnerContext) {
        if let mockFG = context.params["fg"] as? Dictionary<String, AnyObject> {
            var fgResult: Dictionary<String, Any> = [:];
            for k in mockFG.keys {
                let enable = mockFG[k] as? Bool ?? false
                logger.info("MOCK FG: \(k), enable: \(enable)")
                Self.updateDebugFeatureGating(fg: k, isEnable: enable, userId: userResolver.userID)
                fgResult[k] = enable
            }
            context.response["fg"] = fgResult;
        }
        
        if let mockSetting = context.params["setting"] as? Dictionary<String, Any> {
            var willSetSettings: Dictionary<String, String> = [:];
            for k in mockSetting.keys {
                if let s = mockSetting[k] as? [String: Any], JSONSerialization.isValidJSONObject(s) {
                    logger.info("MOCK Setting: \(k), setting: \(s)")
                    let data = try? JSONSerialization.data(withJSONObject: s, options: .fragmentsAllowed)
                    if let string = String(data: data ?? .init(), encoding: .utf8) {
                        willSetSettings[k] = string
                    } else {
                        logger.error("MOCK Setting: \(k), encode to string failed!")
                    }
                } else if let c = mockSetting[k] as? String, let d = c.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: d) {
                    logger.info("MOCK Setting: \(k), setting content: \(c)")
                    willSetSettings[k] = c
                } else {
                    logger.error("MOCK setting: \(k), is not valid json object")
                }
            }
            
            Self.updateSetting(content: willSetSettings, userId: userResolver.userID)
            
            context.response["setting"] = willSetSettings;
        }
        context.execCallbackSuccess()
    }
}

extension KVStores {
    enum FG {
        static let domain = Domain.biz.infra.child("FeatureGating")

        /// 构建 FG 业务用户无关的 `KVStore`
        static var global: KVStore { KVStores.udkv(space: .global, domain: domain) }
    }
}

extension OPDebugMockFGSetting {
        
    private static let currentVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    private static var debugFGCache = debugFGDiskCache { didSet { debugFGDiskCache = debugFGCache } }
    
    @KVConfig(key: "debugDiskCache", default: [String: [String: Bool]](), store: KVStores.FG.global.simplified())
    private static var debugFGDiskCache
    
    private static func debugFeatures(of id: String) -> [String: Bool] { Self.debugFGCache[id + currentVersion] ?? [:] }

    fileprivate static func updateDebugFeatureGating(fg: String, isEnable: Bool, userId: String) {
        logger.info("MOCK FG: updateDebugFeatureGating: \(fg) enable: \(isEnable), userId: \(userId)")
        debugFGCache[userId + currentVersion] = debugFeatures(of: userId).merging([fg: isEnable]) { $1 }
    }
}

extension OPDebugMockFGSetting {
    private static let settingDiskCache = CacheManager.shared.cache(relativePath: "setting", directory: .library)
    
    fileprivate static func updateSetting(content: [String: String], userId: String) {
        let settingKey = "setting" + userId
       
        var parsed: [String: String] = [:]
        var successed = false
        

        if let data = settingDiskCache.diskCache?.object(forKey: settingKey) as? NSData {
            do {
                let result = try JSONDecoder().decode(type(of: parsed), from: data as Data)
                parsed = result
                successed = true
            } catch {
                logger.error("[setting] deserialize failed",
                             additionalData: ["data": "\(data)"],
                             error: error)
            }
        } else {
            logger.warn("[setting] no cache from disk, key: \(settingKey)")
        }
        guard successed else {
            logger.warn("[setting] parse not success!")
            return
        }
        
        content.forEach { (key, conf) in
            parsed[key] = conf
        }
        
        do {
            let data = (try JSONEncoder().encode(parsed)) as NSData
            settingDiskCache.diskCache?.setObject(data, forKey: settingKey)
            logger.info("[setting] update disk cache with key: \(settingKey)")
        } catch {
            logger.error("[setting] serialize failed with key: \(settingKey)",
                         additionalData: ["data": "\(parsed)"], error: error)
        }
    }
}

#endif
