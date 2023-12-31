//
//  OPMetaChecker.swift
//  OPSDK
//
//  Created by laisanpin on 2022/5/10.
//  Meta信息校验工具类
//  https://meego.feishu.cn/larksuite/story/detail/4876574?parentUrl=%2Fworkbench

import Foundation
import LKCommonsLogging
import ECOInfra
import OPSDK
import TTMicroApp
import OPFoundation

public typealias OPGadgetMetaUpdateStrategy = PKMCommomUpdateStrategy

public final class OPMetaChecker {
    static let logger = Logger.oplog(OPMetaChecker.self, category: "OPMetaChecker")

    private let uniqueID: OPAppUniqueID

    public init(_ uniqueID: OPAppUniqueID) {
        self.uniqueID = uniqueID
    }

    /// 检查meta信息过期状态
    /// - Parameter lastUpdateTimestamp: 上一次更新时间, 单位: 毫秒
    /// - Returns: 返回当前过期的策略
    public func checkGadgetMetaUpdateStrategy(_ lastUpdateTimestamp: TimeInterval) -> OPGadgetMetaUpdateStrategy {
        //isBoxOff true的情况下，应用永远不过期（如果AppID在ODR列表内，永远不过期）
        if OPSDKFeatureGating.isBoxOff() || !OPSDKFeatureGating.canSilenceUpdateOrExpire(self.uniqueID) {
            return .async
        }
        guard let expiredSettingDic = ECOConfig.service().getLatestDictionaryValue(for: "meta_expiration_time_setting"),
              let expiredConfigDic = expiredSettingDic["meta_expired_config"] as? [String : Any]
        else {
            Self.logger.warn("\(uniqueID.fullString) meta_expired_config is nil", tag: String.metaCheckerTag)
            return .async
        }

        Self.logger.info("\(uniqueID.fullString) lastUpdateTime: \(lastUpdateTimestamp)", tag: String.metaCheckerTag)

        // 这边要转换成秒进行对比
        let lastUpdateTimeInt = Int(lastUpdateTimestamp / 1000)

        // 对应应用没有配置过期策略, 则用最外层通用策略
        guard let appExpiredDic = expiredConfigDic[BDPSafeString(uniqueID.appID)] as? [String : Any] else {
            let commonExpirePolicy = parseExpiredInfo(expiredConfigDic)
            Self.logger.info("\(uniqueID.fullString) donnot set expired settings, use common expired policy: \(commonExpirePolicy)", tag: String.metaCheckerTag)
            return checkExpiredState(commonExpirePolicy, lastUpdateTimeInt)
        }

        let appExpiredPolicy = parseExpiredInfo(appExpiredDic)
        Self.logger.info("\(uniqueID.fullString) expired policy: \(appExpiredPolicy)")
        return checkExpiredState(appExpiredPolicy, lastUpdateTimeInt)
    }
}

extension OPMetaChecker {
    func parseExpiredInfo(_ dic: Dictionary<String, Any>) -> (enable: Bool, syncTry: Int, syncForce: Int) {
        let enable = dic["enable"] as? Bool ?? false
        let syncTry = dic["sync_try"] as? Int ?? Int.max
        let syncForce = dic["sync_force"] as? Int ?? Int.max
        return (enable, syncTry, syncForce)
    }

    func checkExpiredState(_ config: (enable: Bool, syncTry: Int, syncForce: Int), _ saveTime: Int) -> OPGadgetMetaUpdateStrategy {
        let now = Int(NSDate().timeIntervalSince1970)

        if (!config.enable) {
            Self.logger.info("\(uniqueID.fullString) expiredConfig enable is false")
            return .async
        }

        if (now - saveTime > config.syncForce) {
            Self.logger.info("\(uniqueID.fullString) meta expired syncForec time")
            return .syncForce
        }

        if (now - saveTime > config.syncTry) {
            Self.logger.info("\(uniqueID.fullString) meta expired syncTry time")
            return .syncTry
        }

        Self.logger.info("\(uniqueID.fullString) meta is unExpired")
        return .async
    }
}


extension OPAppUniqueID {
    private static var _opMetaUpdateStrategyKey: Void?
    public var metaUpdateStrategy: OPGadgetMetaUpdateStrategy {
        get {
            return objc_getAssociatedObject(self, &OPAppUniqueID._opMetaUpdateStrategyKey) as? OPGadgetMetaUpdateStrategy ?? .async
        }

        set {
            objc_setAssociatedObject(self, &OPAppUniqueID._opMetaUpdateStrategyKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

fileprivate extension String {
    static let metaCheckerTag = "[OPMetaChecker]"
}
