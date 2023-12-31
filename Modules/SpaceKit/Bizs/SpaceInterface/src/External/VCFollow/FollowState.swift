//
//  FollowAction.swift
//  SpaceInterface
//
//  Created by nine on 2019/9/8.
//

import Foundation

/// 用于监听事件
public enum FollowEvent: String {
    case newAction = "NEW_ACTIONS"              // 有新的action产生
    case titleChange = "SUITE_TITLE_CHANGE"     // 文档标题变化
    case followLog = "FOLLOW_LOG"               // 日志信息
    case positionChange = "POSITION_CHANGE"     // 文档阅读者位置变化
    case touchPositionChange = "TOUCH_POSITION_CHANGE" //sheet touch事件
    case presenterFollowerLocation = "PRESENTER_FOLLOWER_LOCATION" //共享者&跟随者位置
    case versionLag = "FOLLOW_ACTION_VERSION_LAG"
    case track = "FOLLOW_TRACK"
    case lifeCycleChange = "FOLLOW_ACTION_LIFECYCLE_CHANGE"
    case actionChangeList = "FOLLOW_ACTION_CHANGE_LIST" //Magic Share Action 统计数据上报调整
    case firstPositionChangeAfterFollow = "FIRST_POSITION_CHANGE_AFTER_FOLLOW" //Magic Share分享后首次滑动文档埋点上报
    case relativePositionChange = "RELATIVE_POSITION_CHANGE" //Magic Share 获取相对位置
    case magicShareInfo = "MAGIC_SHARE_INFO" // magic share 共享信息
    case newPatches = "NEW_PATCHES"
}

/// FollowState的数据类型
public protocol FollowState {
    /// 将FollowState 转化为可被传输的JSON 字符串
    ///
    /// - Returns: JSON 字符串
    func toJSONString() -> String
}
