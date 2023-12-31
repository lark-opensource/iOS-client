//
//  OPPackageUpdate.swift
//  OPSDK
//
//  Created by laisanpin on 2022/3/23.
//

import Foundation
import OPFoundation

// 产品化止血策略协议
// (产品化止血方案: https://bytedance.feishu.cn/docx/doxcnvkVGnpBgzefnP4wtZeMcdg)
@objc
public protocol OPPackageSilenceUpdateProtocol: AnyObject {
    /// 拉取止血配置是否已经结束
    var fetchUpdateInfoIsFinish: Bool { get }

    /// 拉取止血配置
    func fetchSilenceUpdateSettings(_ uniqueIDs: [OPAppUniqueID])

    /// 拉取止血配置
    /// - Parameters:
    ///   - uniqueIDs: 应用uniqueID数组
    ///   - needSorted: 是否需要根据应用启动时间进行排序
    func fetchSilenceUpdateSettings(_ uniqueIDs: [OPAppUniqueID], needSorted: Bool)
    
    /// 获取对应id的止血配置信息
    /// - Returns: 止血配置信息
    func getSilenceUpdateInfo(_ uniqueID: OPAppUniqueID) -> OPPackageSlinceUpdateInfoProtocol?


    /// 是否满足止血条件
    /// - Returns: 是否满足止血条件
    func canSilenceUpdate(uniqueID: OPAppUniqueID, metaAppVersion: String?) -> Bool

    /// 是否满足止血条件
    /// - Parameters:
    ///   - uniqueID: 应用UniqueID
    ///   - metaAppVersion: meta信息中的版本信息(小程序是appVersion; H5离线应用是applicationVersion)
    ///   - launchLeastAppVersion: 启动参数中用户传入的止血版本信息
    /// - Returns: 是否满足止血条件
    func canSilenceUpdate(uniqueID: OPAppUniqueID,
                          metaAppVersion: String?,
                          launchLeastAppVersion: String?) -> Bool

    /// 是否开启止血方案
    /// - Returns: 产品化止血FG开关状态
    func enableSlienceUpdate() -> Bool


    /// 更新应用启动时间;
    /// - Parameter uniqueID: uniqueID
    func updateAppLaunchTime(_ uniqueID: OPAppUniqueID)
}

// 获取到的止血配置信息协议
@objc
public protocol OPPackageSlinceUpdateInfoProtocol {
    var gadgetMobile: String { get }
    var h5OfflineVersion: String { get }
}
