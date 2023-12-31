//
//  OPAppMetaProtocols.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/11/11.
//

import Foundation
import OPFoundation

/// basic data，App级别
public protocol OPApplicationMetaProtocol: AnyObject {

    /// 应用唯一ID
    var appID: String { get }

    /// 应用名称
    var appName: String { get }

    /// 应用发布的版本 （目前这个字段后端并未下发，下发的是形态自己的version）
    var applicationVersion: String { get }

    /// 应用图标
    var appIconUrl: String { get }

    /// 开发者是否配置可信名单
    var openSchemas: [Any]? { get }

    var useOpenSchemas: Bool? { get }

    var botID: String { get }

    var canFeedBack: Bool { get }

    var shareLevel: Int { get }
}

/// basic data, 形态级别 , 真正用户视角运行起来的业务形态的meta
public protocol OPBizMetaProtocol: OPApplicationMetaProtocol {

    var uniqueID: OPAppUniqueID { get }
    /// 能力形态： 小程序，网页，block，widget，Tab小程序等
//    var appType: OPAppType { get }

    /// 形态自己的verison
    var appVersion: String { get }

    /// 形态自己的id： 小程序，网页，Tab小程序、bot就是appId，block是blockId，widget是cardId
//    var appIdentifier: String { get }

    /// 转换为jsonStr
    func toJson() throws -> String

}

/// meta中的包信息抽象
public protocol OPMetaPackageProtocol {

    /// 代码包下载地址数组
    var packageUrls: [String] { get }

    /// 包校验码md5
    var md5CheckSum: String { get }

}
