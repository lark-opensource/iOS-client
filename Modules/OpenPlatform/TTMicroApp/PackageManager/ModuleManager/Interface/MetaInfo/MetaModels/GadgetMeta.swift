//
//  GadgetMeta.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/6/28.
//

import Foundation
import OPFoundation

/// 小程序引擎 H5小程序 Meta模型（备注：H5小程序领导说需要删除，目前临时共用）
@objcMembers
/// [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
public final class GadgetMeta: NSObject, AppMetaProtocol, AppMetaComponentsProtocol {
/// public class GadgetMeta: NSObject, AppMetaProtocol {

    /// 唯一标志符（此处为应用ID）
    public private(set) var uniqueID: BDPUniqueID

    /// 版本（此处为小程序version）【包版本】
    public let version: String
    
    /// 应用版本（关于页展示）【应用版本】
    public let appVersion: String
    
    /// 编译产物版本
    public let compileVersion: String

    /// 小程序名称
    public let name: String

    /// 小程序图标
    public let iconUrl: String

    /// [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
    /// 依赖的大组件列表
    public let components: [[String:Any]]

    /// 包属性
    public var packageData: AppMetaPackageProtocol

    /// 权限属性
    public var authData: AppMetaAuthProtocol

    /// 业务数据
    public var businessData: AppMetaBusinessDataProtocol
    
    /// 批量获取的版本的类型
    public var batchMetaVersion: Int = 0

    public init(
        uniqueID: BDPUniqueID,
        version: String,
        appVersion: String,
        compileVersion: String,
        name: String,
        iconUrl: String,
        // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
        components: [[String:Any]]?,
        packageData: GadgetMetaPackage,
        authData: GadgetMetaAuth,
        businessData: GadgetBusinessData
    ) {
        self.uniqueID = uniqueID
        self.version = version
        self.appVersion = appVersion
        self.compileVersion = compileVersion
        self.name = name
        self.iconUrl = iconUrl
        self.packageData = packageData
        self.authData = authData
        self.businessData = businessData
        // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
        self.components = components ?? []
        super.init()
    }

    // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
     public func getComponentNames() -> [String] {
        return self.components.compactMap { (component) -> String? in
            return component["name"] as? String
        }
    }
    
    public func updateUniqueID(_ uniqueID: BDPUniqueID) {
        self.uniqueID = uniqueID
    }

    /// metaModel转化为json字符串用于持久化（如果纯Swift可以用Codable，纯OC可以NSCoding，混编比较痛苦）
    public func toJson() throws -> String {
        var mobileSubPackage: [String: Any] = [:]
        packageData.subPackages?.forEach {
            mobileSubPackage[$0.path] = ["md5": $0.md5,
                                         "independent": $0.isIndependent,
                                         "path": $0.urls.map{ $0.absoluteString },
                                         "pages": $0.pages]
        }

        var diffPkgPath: MetaDiffPkgPathInfo? = nil
        if OPSDKFeatureGating.packageIncremetalUpdateEnable() {
            if let _diffPathData = packageData as? AppMetaDiffPackageProtocol {
                diffPkgPath = _diffPathData.diffPkgPath
            }
        }

        let dic: [String: Any] = [
            "appType": uniqueID.appType.rawValue,
            "identifier": uniqueID.identifier,
            "appID": uniqueID.appID,
            "version": version,
            "appVersion": appVersion,
            "compileVersion": compileVersion,
            "versionType": OPAppVersionTypeToString(uniqueID.versionType),
            "name": name,
            "iconUrl": iconUrl,
            /// [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
            "components": components,
            "batchMetaVersion": batchMetaVersion,
            "packageData": [
                "urls": packageData.urls.map { $0.absoluteString },
                "md5": packageData.md5,
                "diffPath" : diffPkgPath ?? [:]
            ],
            //json反转时恢复分包的原始数据，如果有则恢复，没有设置为空数组[]
            "mobileSubPackage": mobileSubPackage,
            "authData": [
                "appStatus": (authData as! GadgetMetaAuth).appStatus.rawValue,
                "versionState": (authData as! GadgetMetaAuth).versionState.rawValue,
                "authList": (authData as! GadgetMetaAuth).authList,
                "blackList": (authData as! GadgetMetaAuth).blackList,
                "gadgetSafeUrls": (authData as! GadgetMetaAuth).gadgetSafeUrls,
                "domainsAuthDict": (authData as! GadgetMetaAuth).domainsAuthDict,
                "versionUpdateTime": (authData as! GadgetMetaAuth).versionUpdateTime
            ],
            "businessData": [
                "extraDict": (businessData as! GadgetBusinessData).extraDict,
                "shareLevel": (businessData as! GadgetBusinessData).shareLevel.rawValue,
                "versionCode": (businessData as! GadgetBusinessData).versionCode,
                "minJSsdkVersion": (businessData as! GadgetBusinessData).minJSsdkVersion,
                "minLarkVersion" : (businessData as! GadgetBusinessData).minLarkVersion,
                "webURL": (businessData as! GadgetBusinessData).webURL,
                "message_action": (businessData as! GadgetBusinessData).abilityForMessageAction,
                "chat_action": (businessData as! GadgetBusinessData).abilityForChatAction,
                "isFromBuildin": (businessData as! GadgetBusinessData).isFromBuildin,
            ]
        ]
        guard JSONSerialization.isValidJSONObject(dic) else {
            let msg = "jsonDic to data failed(for gadget meta db), jsondic is invaild"
            BDPLogError(tag: .gadgetProvider, msg)
            throw NSError(domain: "gadget", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        var data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: dic)
        } catch {
            BDPLogError(tag: .gadgetProvider, "\(error)")
            throw error
        }
        guard let json = String(data: data, encoding: .utf8) else {
            let msg = "data to string failed(for gadget meta db)"
            let err = NSError(domain: "gadget", code: -1, userInfo: [NSLocalizedDescriptionKey: "data to string failed"])
            BDPLogError(tag: .gadgetProvider, msg)
            throw err
        }
        return json
    }

}

@objcMembers
public final class GadgetSubPackage: GadgetMetaPackage, AppMetaSubPackageProtocol {
    //分包的页面路径，如果是主包，则是 __APP__
    public let path: String
    //当前分包允许的分包页面
    public let pages: [String]
    //是否是独立分包
    public let isIndependent: Bool
    //是否是主包（path 是 __APP__）
    public let isMainPackage: Bool
    
    public static let kMainAppTag = "__APP__"
    public init(path: String, package: [String : AnyHashable]) {
        self.path = path
        self.isIndependent = package["independent"] as? Bool ?? false
        self.isMainPackage = path == GadgetSubPackage.kMainAppTag
        self.pages = package["pages"] as? [String] ?? []
        //服务端返回的是 path 字段，就是cdn地址列表
        let urls = (package["path"] as? [String] ?? []).compactMap{ URL(string: $0) }
        let md5 = package["md5"] as? String ?? ""
        super.init(urls: urls, md5: md5, packages: nil, diffPkgPath: nil)
    }
}

/// 小程序引擎 H5小程序 meta中的包信息抽象
@objcMembers
public class GadgetMetaPackage: NSObject, AppMetaPackageProtocol, AppMetaDiffPackageProtocol {

    /// 代码包下载地址数组
    public let urls: [URL]

    /// 包校验码md5
    public let md5: String

    public let subPackages: [AppMetaSubPackageProtocol]
    /// 包增量更新diff包信息
    public let diffPkgPath: MetaDiffPkgPathInfo

    public init(
        urls: [URL],
        md5: String,
        packages: [String: AnyHashable]?,
        diffPkgPath: MetaDiffPkgPathInfo?
    ) {
        self.urls = urls
        self.md5 = md5
        self.subPackages = packages?.compactMap({ path, value in
            GadgetSubPackage(path: path, package: value as? [String: AnyHashable] ?? [:])
        }) ?? []
        self.diffPkgPath = diffPkgPath ?? [:]
        super.init()
    }
}

/// 小程序引擎 H5小程序 meta中的权限信息
@objcMembers
public final class GadgetMetaAuth: NSObject, AppMetaAuthProtocol {

    /// 小程序状态 - 未发布 已发布 已下架
    public let appStatus: BDPAppStatus

    /// 小程序版本状态 - 正常状态 当前用户无权限访问小程序 小程序不支持当前宿主环境 预览版二维码已过期（有效期1d）
    public let versionState: BDPAppVersionStatus
    
    /// 小程序版本更新时间
    public let versionUpdateTime: Int64

    /// ttcode??
    public let authList: [String]

    /// 黑名单API，目前没有使用，兼容BDPModel的workaround的代码
    public let blackList: [String]

    /// 小程序webview安全域名限制列表： https://bits.bytedance.net/meego/larksuite/story/detail/1844631
    public let gadgetSafeUrls: [String]

    /// 域名权限字典？
    public let domainsAuthDict: [String: [String]]

    public init(
        appStatus: BDPAppStatus,
        versionState: BDPAppVersionStatus,
        authList: [String],
        blackList: [String],
        gadgetSafeUrls: [String],
        domainsAuthDict: [String: [String]],
        versionUpdateTime: Int64
    ) {
        self.appStatus = appStatus
        self.versionState = versionState
        self.authList = authList
        self.blackList = blackList
        self.gadgetSafeUrls = gadgetSafeUrls
        self.domainsAuthDict = domainsAuthDict
        self.versionUpdateTime = versionUpdateTime
        super.init()
    }

}

/// 小程序引擎 H5小程序 meta业务数据，存放卡片独有的属性
@objcMembers
public final class GadgetBusinessData: NSObject, AppMetaBusinessDataProtocol {

    /// 额外信息 is_inner 0=不是头条内部小程序 1=头条内部小程序
    public let extraDict: [String: Any]

    /// 小程序分享级别
    public let shareLevel: BDPAppShareLevel

    /// 版本更新时间戳
    public let versionCode: Int64

    /// 最低jssdk版本
    public let minJSsdkVersion: String

    /// 最低jssdk版本
    public let minLarkVersion: String

    /// H5 版本小程序 URL 标识
    public let webURL: String
    
    /// 应用是否具备对应能力 Message Action
    public let abilityForMessageAction: Bool
    
    /// 应用是否具备对应能力 +号
    public let abilityForChatAction: Bool

    public var isFromBuildin: Bool = false

    public let realMachineDebugSocketAddress: String?
    
    public let performanceProfileAddress: String?
    
    public init(
        extraDict: [String: Any],
        shareLevel: BDPAppShareLevel,
        versionCode: Int64,
        minJSsdkVersion: String,
        minLarkVersion: String,
        webURL: String,
        abilityForMessageAction: Bool,
        abilityForChatAction: Bool,
        isFromBuildin: Bool,
        realMachineDebugSocketAddress: String?,
        performanceProfileAddress: String?
    ) {
        self.extraDict = extraDict
        self.shareLevel = shareLevel
        self.versionCode = versionCode
        self.minJSsdkVersion = minJSsdkVersion
        self.minLarkVersion = minLarkVersion
        self.webURL = webURL
        self.abilityForMessageAction = abilityForMessageAction
        self.abilityForChatAction = abilityForChatAction
        self.isFromBuildin = isFromBuildin
        self.realMachineDebugSocketAddress = realMachineDebugSocketAddress
        self.performanceProfileAddress = performanceProfileAddress
        super.init()
    }
}
