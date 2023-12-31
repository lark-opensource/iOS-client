//
//  PKMBaseMeta.swift
//  TTMicroApp
//
//  Created by Nicholas Tau on 2022/11/18.
//

import Foundation 

public protocol PKMBaseMetaProtocol: AnyObject {
    // 应用ID（不一定唯一，可以不同形态使用同一个appID）
    var pkmID: PKMUniqueID { get }
    // 业务类型
    var bizType: String { get }
    // 包地址信息
    var urls: [String] { get }
    // 包的md5信息
    var md5: String? { get }
    // 包的应用版本信息
    var appVersion: String { get }
    // meta 原始数据
    var originalJSONString: String { get }
}

public protocol PKMBaseMetaDBProtocol: AnyObject {
    // 是否是预览版
    var isPreview: Bool { get }
    // meta 来源信息
    var metaFrom: Int { get }
    //组合值，必须唯一。作为数据库的 UNIQUE KEY，用来查询/更新（可以是appID+version+pkgName）
    var identifier: String {get}
}

public protocol PKMBaseMetaPkgProtocol: AnyObject {
    //安装包路径
    func localPath() -> String?
    
    //安装包路径
    func packageName() -> String?
    
    //是否已安装
    func isInstalled() -> Bool
    
    //是有有分包
    func hasSubpackage() -> Bool
    
    //是否有增量包
    func hasIncremental() -> Bool
}



public struct PKMUniqueID {
    ///应用ID，cli_xxx
    public let appID: String
    /// 应用标识，在block类似的业务使用（默认为空）
    /// （一个appID下又有多个不同的blk_id）
    public let identifier: String?

    public init(appID: String, identifier: String?) {
        self.appID = appID
        self.identifier = identifier
    }
    
    /// 应用池内的作为查询app对象的键
    /// - Returns: identifier 存在时优先返回，否则返回 appID
    public func queryKey() -> String {
        if let identifier = identifier {
            return identifier
        }
        return appID
    }
}
