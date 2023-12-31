//
//  WorkplaceOpenAPI.swift
//  LarkOpenWorkplace
//
//  Created by Meng on 2023/8/29.
//

import Foundation

public final class WPAppSubTypeInfo: Equatable {
    /// 常用应用（用户添加）
    public var isUserCommon: Bool

    /// 可移除推荐应用（管理员配置，也叫 B 类应用）
    public var isUserDistributedRecommend: Bool

    /// 不可移除推荐应用（管理员配置，也叫 A 类应用）
    public var isUserRecommend: Bool

    public init(isUserCommon: Bool, isUserDistributedRecommend: Bool, isUserRecommend: Bool) {
        self.isUserCommon = isUserCommon
        self.isUserDistributedRecommend = isUserDistributedRecommend
        self.isUserRecommend = isUserRecommend
    }

    public static func == (lhs: WPAppSubTypeInfo, rhs: WPAppSubTypeInfo) -> Bool {
        return lhs.isUserCommon == rhs.isUserCommon
        && lhs.isUserDistributedRecommend == rhs.isUserDistributedRecommend
        && lhs.isUserRecommend == rhs.isUserRecommend
    }
}

/// 工作台对外 API
public protocol WorkplaceOpenAPI {

    /// 查询常用应用
    /// - Parameters:
    ///   - appId: 要查询的常用应用Id
    ///   - fromCache: 是否从缓存中查询，开启后直接从缓存中查询，不会请求网络
    ///   - success: 成功回调，返回查询目标中的常用应用列表
    ///   - failure: 失败回调
    func queryAppSubTypeInfo(
        appId: String,
        fromCache: Bool,
        success: @escaping (_ info: WPAppSubTypeInfo) -> Void,
        failure: @escaping (_ error: Error) -> Void
    )

    /// 添加常用应用
    /// - Parameters:
    ///   - appIds: 要添加的常用应用Id列表
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func addCommonApp(
        appIds: [String],
        success: @escaping () -> Void,
        failure: @escaping (_ error: Error) -> Void
    )

    /// 删除常用应用
    /// - Parameters:
    ///   - appId: 要删除的常用应用Id
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func removeCommonApp(
        appId: String,
        success: @escaping () -> Void,
        failure: @escaping (_ error: Error) -> Void
    )

    /// [用户打开应用行为统计] 打开小程序上报
    ///
    /// - Parameters:
    ///   - appId: App ID
    ///   - path: 审批模板一类小程序的子路径
    func reportRecentlyMiniApp(appId: String, path: String)

    /// [用户打开应用行为统计] 打开网页上报
    ///
    /// - Parameter appId: App ID
    func reportRecentlyWebApp(appId: String)
}
