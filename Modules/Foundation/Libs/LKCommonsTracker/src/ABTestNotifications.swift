//
//  ABTestNotifications.swift
//  LKCommonsTracker
//
//  Created by shizhengyu on 2019/12/18.
//

import Foundation

/// 内部 AB 实验相关的通知常量标识
public extension Tracker {
    /// 实验注册完成
    static let LKExperimentDataDidRegister = "LKExperimentDataDidRegister"
    /// 实验数据获取成功
    static let LKExperimentDataDidFetch = "LKExperimentDataDidFetch"
    /// 实验被曝光
    static let LKExperimentDidExposured = "LKExperimentDidExposured"
    /// adsdkVersions 有改变
    static let LKABSDKVersionsDidChanged = "LKABSDKVersionsDidChanged"
}
