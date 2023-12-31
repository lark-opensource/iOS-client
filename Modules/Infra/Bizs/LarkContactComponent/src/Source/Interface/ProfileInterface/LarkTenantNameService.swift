//
//  LarkTenantNameService.swift
//  LarkContactComponent
//
//  Created by ByteDance on 2023/3/20.
//

import Foundation
import UIKit
import UniverseDesignColor

public struct LarkTenantNameUIConfig {
    
    /// 租户信息字体大小
    public var tenantNameFont: UIFont
    
    /// 租户信息字体颜色
    public var tenantNameColor: UIColor
    
    /// 是否显示企业认证，默认true
    public var isShowCompanyAuth: Bool
    
    /// 是否支持企业认证点击，默认false
    public var isSupportAuthClick: Bool
    
    /// 是否只显示单行 (目前单行展示，可参考联系人展示效果，多行展示参考Profile、侧边栏展示效果)
    public var isOnlySingleLineDisplayed: Bool

    public init(tenantNameFont: UIFont = UIFont.systemFont(ofSize: 12),
                tenantNameColor: UIColor = UIColor.ud.textPlaceholder,
                isShowCompanyAuth: Bool = true,
                isSupportAuthClick: Bool = false,
                isOnlySingleLineDisplayed: Bool = false) {
        self.tenantNameFont = tenantNameFont
        self.tenantNameColor = tenantNameColor
        self.isShowCompanyAuth = isShowCompanyAuth
        self.isSupportAuthClick = isSupportAuthClick
        self.isOnlySingleLineDisplayed = isOnlySingleLineDisplayed
    }
    
    public static func defaultConfig() -> LarkTenantNameUIConfig {
        return LarkTenantNameUIConfig()
    }
}

public protocol LarkTenantNameService {
    func generateTenantNameView(with description: LarkTenantNameUIConfig) -> LarkTenantNameViewInterface
}
