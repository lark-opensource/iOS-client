//
//  PKMBizMetaAdapter.swift
//  TTMicroApp
//
//  Created by Nicholas Tau on 2022/11/22.
//

import Foundation
import ECOInfra
import LKCommonsLogging

private let log = Logger.oplog(GadgetMeta.self, category: "PKMBizMetaAdapter")
extension GadgetMeta: PKMBaseMetaProtocol {
    // 应用ID（不一定唯一，可以不同形态使用同一个appID）
    public var pkmID: PKMUniqueID {
        return PKMUniqueID(appID: self.uniqueID.appID, identifier: nil)
    }
    // 业务类型
    public var bizType: String {
        return OPAppTypeToString(self.uniqueID.appType)
    }
    // 包地址信息
    public var urls: [String] {
        return self.packageData.urls.compactMap { $0.absoluteString }
    }
    // 包的md5信息
    public var md5: String? {
        return self.packageData.md5
    }
    // 包的应用版本信息
//    var appVersion: String {  }
    // meta 原始数据
    public var originalJSONString: String {
        var originalJSONString = ""
        do {
            originalJSONString = try toJson()
        } catch  {
            log.error("convert to json string error:\(error)")
        }
        return originalJSONString
    }
}

extension GadgetMeta: PKMBaseMetaPkgProtocol {
    //安装包路径
    public func localPath() -> String? {
        return nil
    }
    
    //安装包路径
    public func packageName() -> String? {
        return self.packageData.urls.first?.path.bdp_fileName()
    }
    
    //是否已安装
    public func isInstalled() -> Bool {
        guard let packageName = self.packageName() else { return false }
        return BDPPackageLocalManager.isLocalPackageExsit(self.uniqueID, packageName: packageName)
    }
    
    //有分包
    public func hasSubpackage() -> Bool {
        if let subpackages = self.packageData.subPackages {
            return subpackages.count > 0
        }
        return false
    }
    
    //是否有增量包
    public func hasIncremental() -> Bool {
        return false
    }
}

extension GadgetMeta: PKMBaseMetaDBProtocol {
    // 是否是预览版
    public var isPreview: Bool {
        self.uniqueID.versionType == .preview
    }
    // meta 来源信息（预留字段）
    public var metaFrom: Int {
        return 0
    }
    //组合值，必须唯一。作为数据库的 UNIQUE KEY，用来查询/更新（可以是appID+version+pkgName）
    public var identifier: String {
        return "\(self.uniqueID.appID)-\(self.bizType)-\(self.appVersion)-\(self.packageName() ?? "")"
    }
}
