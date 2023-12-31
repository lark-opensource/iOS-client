//
//  CardModels.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/9.
//

import Foundation

/// 卡片Meta模型
@objcMembers
public final class CardMeta: NSObject, AppMetaProtocol {

    /// 唯一标志符（此处为card id）
    public let uniqueID: BDPUniqueID

    /// 版本（此处为卡片version）
    public let version: String

    /// 卡片名称
    public let name: String

    /// 卡片图标
    public let iconUrl: String

    /// 最低客户端版本号
    public let minClientVersion: String

    /// 包属性
    public var packageData: AppMetaPackageProtocol

    /// 权限属性
    public var authData: AppMetaAuthProtocol

    /// 业务数据
    public var businessData: AppMetaBusinessDataProtocol

    public init(
        uniqueID: BDPUniqueID,
        version: String,
        name: String,
        iconUrl: String,
        minClientVersion: String,
        packageData: CardMetaPackage,
        authData: CardMetaAuth,
        businessData: CardBusinessData
    ) {
        self.uniqueID = uniqueID
        self.version = version
        self.name = name
        self.iconUrl = iconUrl
        self.minClientVersion = minClientVersion
        self.packageData = packageData
        self.authData = authData
        self.businessData = businessData
        super.init()
    }

    /// metaModel转化为json字符串用于持久化（如果纯Swift可以用Codable，纯OC可以NSCoding，混编比较痛苦）
    public func toJson() throws -> String {
        let dic: [String: Any] = [
            "appType": uniqueID.appType.rawValue,
            "identifier": uniqueID.identifier,
            "appID": uniqueID.appID,
            "version": version,
            "versionType": OPAppVersionTypeToString(uniqueID.versionType),
            "name": name,
            "iconUrl": iconUrl,
            "minClientVersion": minClientVersion,
            "packageData": [
                "urls": packageData.urls.map { $0.absoluteString },
                "md5": packageData.md5
            ],
            "authData": "",
            "businessData": [
                "extra": (businessData as! CardBusinessData).extra
            ]
        ]
        guard JSONSerialization.isValidJSONObject(dic) else {
            let msg = "jsonDic to data failed(for card meta db), jsondic is invaild"
            BDPLogError(tag: .cardProvider, msg)
            throw NSError(domain: "cardMeta", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        var data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: dic)
        } catch {
            BDPLogError(tag: .cardProvider, "\(error)")
            throw error
        }
        guard let json = String(data: data, encoding: .utf8) else {
            let msg = "data to string failed(for card meta db)"
            let err = NSError(domain: "cardMeta", code: -1, userInfo: [NSLocalizedDescriptionKey: "data to string failed"])
            BDPLogError(tag: .cardProvider, msg)
            throw err
        }
        return json
    }

}

/// 卡片meta中的包信息抽象
@objcMembers
public final class CardMetaPackage: NSObject, AppMetaPackageProtocol {

    /// 代码包下载地址数组
    public let urls: [URL]

    /// 包校验码md5
    public let md5: String

    public init(
        urls: [URL],
        md5: String
    ) {
        self.urls = urls
        self.md5 = md5
        super.init()
    }
}

/// 卡片meta中的权限信息
@objcMembers
public final class CardMetaAuth: NSObject, AppMetaAuthProtocol {
}

/// 卡片meta业务数据，存放卡片独有的属性
@objcMembers
public final class CardBusinessData: NSObject, AppMetaBusinessDataProtocol {

    /// 额外信息
    public let extra: String

    public init(
        extra: String
    ) {
        self.extra = extra
        super.init()
    }
}
