//
//  ProfileRelationship.swift
//  LarkProfile
//
//  Created by Yuri on 2022/2/24.
//

import Foundation

public enum ProfileRelationship {
    /// 无状态
    case none
    /// 申请添加联系人
    case apply
    /// 申请中，未通过
    case applying
    /// 同意添加请求
    case accept
    /// 已添加好友
    case accepted
}

public enum ProfileCommunicationPermission {
    /// 未知，无状态
    case unown
    /// 已同意申请，有沟通权限
    case agreed
    /// 有申请沟通的权限
    case apply
    /// 申请中未超过可再次申请时间,当前不可再次申请
    case applying
    /// 已申请，已超过申请时间可再次申请
    case applied
    /// 不能申请
    case inelligible
    
}
