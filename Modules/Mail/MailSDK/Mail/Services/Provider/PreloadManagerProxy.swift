//
//  PreloadManagerProxy.swift
//  MailSDK
//
//  Created by ByteDance on 2023/5/11.
//

import Foundation

/// 执行状态
public enum PreloadTaskState : String {
    case unStart
    case wait
    case start
    case run
    case end
    case cancel
    case disableByLowDevice
    case disableByHitRate
}

public typealias TaskStateCallBack = (PreloadTaskState) -> Void
public typealias TaskAction = () -> Void

public protocol PreloadManagerProxy {
    func addTask(preloadName: String, taskAction: @escaping TaskAction, stateCallBack: TaskStateCallBack?, diskCacheId: String?) -> String
    func cancelTaskByTaskId(taskId: String)
    func scheduleTaskById(taskId: String)
    func preloadFeedback(taskId: String, hitPreload: Bool)
    func feedbackForDiskCache(diskCacheId: String, hitPreload: Bool)
    ///是否使用新预加载框架 注：业务侧也框架测都需要一个开关，只有同时打开才走新预加载框架。
    func preloadEnable() -> Bool
    func switchAccount()
}
