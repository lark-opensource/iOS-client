//
//  WorkPlaceOperationModel.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/11/12.
//

import SwiftyJSON

/// 工作台运营配置
struct WorkPlaceOperationModel: Codable {
    /// 推荐的一键安装应用列表
    let operationalApps: [OperationApp]?
    /// 运营活动配置
    let operationalActivity: OperationalActivity?
    /// 运营类型
    private let operationalType: String?
    /// 是否是管理员
    let isAdmin: Bool?
    /// 是否展示onBoarding弹窗
    let onboardingPopUp: Bool?
    /// 是否展示运营气泡
    let bubblePopup: Bool?

    /// 获取运营类型
    func getoOperationalType() -> OperationalType? {
        return OperationalType(rawValue: operationalType ?? "")
    }

    /// 判断配置内容是否为空
    func isConfigEmpty() -> Bool {
        return operationalApps == nil &&
            operationalActivity == nil &&
            operationalType == nil &&
            isAdmin == nil &&
            onboardingPopUp == nil
    }
}

/// 推荐的一键安装应用
struct OperationApp: Codable {
    let appId: String
    let icon: Icon
    let name: String
    let description: String
    /// PC应用商店url
    let pcAppstoreUrl: String?
    /// 移动应用商店url
    let mobileAppstoreUrl: String?
    /// 应用权限列表
    let scopes: [GuideAppScope]?
    /// 跳转到隐私协议的链接
    let privacyPolicyUrl: String?
    /// 跳转到用户协议的链接
    let clauseUrl: String?
}

/// 运营活动配置
struct OperationalActivity: Codable {
    /// 活动名称
    let name: String?
    /// PC活动URL
    let pcUrl: String?
    /// 移动端活动url
    let mobileUrl: String?
}

/// 运营类型
enum OperationalType: String {
    /// 没有活动
    case none
    /// 推荐安装应用
    case operationalApps
    /// 运营活动
    case operationalActivity
}

/// 图标
struct Icon: Codable {
    let key: String
    let fsUnit: String?
}

/// 权限
struct GuideAppScope: Codable {
    /// 权限描述
    let desc: String
    /// normal: 普通权限, high: 高级权限
    private let level: String
    /// 获取权限等级
    func getLevel() -> InstallGuideAppLevel? {
        return InstallGuideAppLevel(rawValue: level)
    }
}
