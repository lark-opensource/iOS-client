//
//  OPGadgetContextAllocator.swift
//  EEMicroAppSDK
//
//  Created by 尹清正 on 2021/3/24.
//

import Foundation
import TTMicroApp

/// 负责收集与目标对象中与小程序相关的上下文信息
struct OPGadgetContextAllocator: OPMemoryInfoAllocator {

    func allocateMemoryInfo(with target: NSObject, monitor: OPMonitor) {
        if let uniqueID = OPAllocatorUtil.getUniqueID(with: target) {
            _ = monitor.setUniqueID(uniqueID)
            allocateGadgetCommonInfo(uniqueID, monitor)
        }

        if let currentPagePath = OPAllocatorUtil.getCurrentPagePath(with: target) {
            _ = monitor.addCategoryValue(BDPTrackerCurrentPagePathKey, currentPagePath)
        }

        if let currentPageQuery = OPAllocatorUtil.getCurrentPageQuery(with: target) {
            _ = monitor.addCategoryValue(BDPTrackerCurrentPageQueryKey, currentPageQuery)
        }
    }

}

/// 应用是否为活跃状态
fileprivate let isAppActiveKey = "is_app_active"
/// 应用是否已经DocumentReady
fileprivate let isDocumentReadyKey = "is_document_ready"
/// 应用是否已经被销毁
fileprivate let isAppDestroyed = "is_app_destroyed"
/// 应用是否可以跳端加载其他应用
fileprivate let canAppLaunchApp = "can_app_launch_app"
/// 应用是否在前台
fileprivate let isAppForeground = "is_app_foreground"
/// 应用是否已经SnapshotReady
fileprivate let isAppSnapshotReady = "is_app_snapshot_ready"
/// 是否为常用应用
fileprivate let isCommonApp = "is_common_app"

private extension OPGadgetContextAllocator {

    func allocateGadgetCommonInfo(_ uniqueID: OPAppUniqueID, _ monitor: OPMonitor) {
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
            return
        }

        _ = monitor.addCategoryValue(isAppActiveKey, common.isActive)
        _ = monitor.addCategoryValue(isDocumentReadyKey, common.isReady)
        _ = monitor.addCategoryValue(isAppDestroyed, common.isDestroyed)
        _ = monitor.addCategoryValue(canAppLaunchApp, common.canLaunchApp)
        _ = monitor.addCategoryValue(isAppForeground, common.isForeground)
        _ = monitor.addCategoryValue(isAppSnapshotReady, common.isSnapshotReady)
        _ = monitor.addCategoryValue(isCommonApp, common.isCommonApp)
    }

}
