//
//  LarkTenantNameView.swift
//  LarkContactComponent
//
//  Created by ByteDance on 2023/3/20.
//

import Foundation
import UIKit
import RustPB

public struct LarkTenantInfo {
    
    /// 租户名称
    public var tenantName: String
    
    /// 是否与对方是好友
    public var isFriend: Bool
    
    /// 租户名称展示状态
    public var tenantNameStatus: RustPB.Basic_V1_TenantNameStatus
    
    /// 租户认证状态
    public var certificationInfo: RustPB.Contact_V2_GetUserProfileResponse.UserInfo.CertificationInfo?

    /// 点击回调
    public var tapCallback: (() -> Void)?

    public init(tenantName: String,
                isFriend: Bool,
                tenantNameStatus: RustPB.Basic_V1_TenantNameStatus,
                certificationInfo: RustPB.Contact_V2_GetUserProfileResponse.UserInfo.CertificationInfo?,
                tapCallback: (() -> Void)?) {
        self.tenantName = tenantName
        self.isFriend = isFriend
        self.tenantNameStatus = tenantNameStatus
        self.certificationInfo = certificationInfo
        self.tapCallback = tapCallback
    }
}

public protocol LarkTenantNameViewInterface: UIView {

    typealias V2CertificationInfo = RustPB.Contact_V2_GetUserProfileResponse.UserInfo.CertificationInfo
    typealias V1CertificationInfo = Contact_V1_GetUserProfileResponse.Company.CertificationInfo
    typealias BasicV1CertificationInfo = RustPB.Basic_V1_CertificationInfo

    /// 配置数据
    /// - Parameter tenantInfo: 组件数据
    /// - Returns: （租户名称，是否显示租户认证状态标签）
    @discardableResult
    func config(tenantInfo: LarkTenantInfo) -> (tenantName: String, hasShowCompanyAuth: Bool)
    
    /// 配置数据
    /// - Parameters:
    ///   - tenantName: 租户名称
    ///   - authUrlString: 企业认证标签详情，无可传""
    ///   - hasShowTenantCertification: 是否显示认证标签
    ///   - isTenantCertification: 是否已认证
    ///   - tapCallback: 点击回调
    func config(tenantName: String,
                authUrlString: String,
                hasShowTenantCertification: Bool,
                isTenantCertification: Bool,
                tapCallback: (() -> Void)?)
    
    /// 数据转换
    /// - Parameter v1CertificationInfo: V1数据源
    /// - Returns: v2数据源
    func transFormCertificationInfo(v1CertificationInfo: V1CertificationInfo) -> V2CertificationInfo

    /// 数据转换
    /// - Parameter v1CertificationInfo: BasicV1数据源
    /// - Returns: v2数据源
    func transFormCertificationInfo(basicV1CertificationInfo: BasicV1CertificationInfo) -> V2CertificationInfo

    /// 解析获取租户名称
    /// - Parameter tenantInfo: 租户信息
    /// - Returns: 租户名称
    func fetchSecurityTenantName(tenantInfo: LarkTenantInfo) -> String
}
