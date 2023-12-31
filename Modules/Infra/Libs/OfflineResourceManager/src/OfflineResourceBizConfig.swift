//
//  OfflineResourceBizConfig.swift
//  OfflineResourceManager
//
//  Created by Miaoqi Wang on 2020/9/3.
//

import Foundation

/// 业务类型
public enum BizType {
    /// default
    case unspecific
    /// 动态化
    case dynamic
    /// ccm
    case ccm
    /// email
    case email
    /// ka动态下载资源
    case ka
}

/// biz id type
public typealias BizID = String

/// offline resource biz config
public struct OfflineResourceBizConfig {
    /// unique id for each biz
    public let bizID: BizID
    /// main key for requesting remote resource
    public let bizKey: String
    /// sub key for requesting remote resource
    public let subBizKey: String
    /// type that this biz belong to, will be used to category different biz
    public let bizType: BizType

    /// init biz config
    public init(bizID: BizID, bizKey: String, subBizKey: String, bizType: BizType = .unspecific) {
        self.bizID = bizID
        self.bizKey = bizKey
        self.subBizKey = subBizKey
        self.bizType = bizType
    }
}
