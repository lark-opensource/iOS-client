//
//  SnsConfiguration.swift
//  LarkSnsShare
//
//  Created by shizhengyu on 2020/3/18.
//

/// 飞书saas 默认的分享配置
import Foundation
public final class LarkSnsConfiguration: SnsConfiguration {
    public var snsAppIDMapping: [SnsType: String] {
        return [.wechat: "wx2dccad7bcdbdab7e",
                .weibo: "1426943654",
                .qq: "1107733183"]
    }

    public var universalLink: String {
        return "https://applink.feishu.cn/"
    }
}

public enum SnsAppIDKey {
    public static let wechat = "Sns_Wechat_AppID"
    public static let qq = "Sns_QQ_AppID"
    public static let weibo = "Sns_Weibo_AppID"
}

public enum SnsInfoKey {
    public static let universalLink = "Sns_UniversalLink"
}

/// info.plist 内预置的分享配置，目前由 zeus 提供 config patch
public final class BundleSnsConfiguration: SnsConfiguration {
    public var snsAppIDMapping: [SnsType: String] {
        var mapping: [SnsType: String] = [:]
        let infoDict = Bundle.main.infoDictionary
        if let wechatSnsAppID = infoDict?[SnsAppIDKey.wechat] as? String {
            mapping[.wechat] = wechatSnsAppID
        }
        if let qqSnsAppID = infoDict?[SnsAppIDKey.qq] as? String {
            mapping[.qq] = qqSnsAppID
        }
        if let weiboSnsAppID = infoDict?[SnsAppIDKey.weibo] as? String {
            mapping[.weibo] = weiboSnsAppID
        }
        return mapping
    }

    public var universalLink: String {
        let infoDict = Bundle.main.infoDictionary
        return infoDict?[SnsInfoKey.universalLink] as? String ?? LarkSnsConfiguration().universalLink
    }
}
