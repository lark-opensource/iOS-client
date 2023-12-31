//
//  PreloadManagerImpl.swift
//  LarkMail
//
//  Created by ByteDance on 2023/5/11.
//

import Foundation
import LarkPreload
import MailSDK

// Bridge Mail SDK Dependency
class PreloadManagerImpl: PreloadManagerProxy {
    func addTask(preloadName: String, taskAction: @escaping TaskAction, stateCallBack: MailSDK.TaskStateCallBack?, diskCacheId: String?) -> String {
        return PreloadMananger.shared.addTask(preloadName: preloadName,
                                              biz: .Mail,
                                              preloadType: .OtherType,
                                              hasFeedback: true,
                                              taskAction: taskAction,
                                              stateCallBack: { state in
            stateCallBack?(state.mailTaskState)
        },
                                              diskCacheId: diskCacheId)
    }
    func cancelTaskByTaskId(taskId: String) {
        PreloadMananger.shared.cancelTaskByTaskId(taskId: taskId)
    }
    func scheduleTaskById(taskId: String) {
        PreloadMananger.shared.scheduleTaskById(taskId: taskId)
    }
    func preloadFeedback(taskId: String, hitPreload: Bool) {
        PreloadMananger.shared.preloadFeedback(taskId: taskId, hitPreload: hitPreload)
    }
    func feedbackForDiskCache(diskCacheId: String, hitPreload: Bool) {
        PreloadMananger.shared.feedbackForDiskCache(diskCacheId: diskCacheId, preloadBiz: .Mail, preloadType: .OtherType, hitPreload: hitPreload)
    }
    ///是否使用新预加载框架 注：业务侧也框架测都需要一个开关，只有同时打开才走新预加载框架。
    func preloadEnable() -> Bool {
        return PreloadMananger.shared.preloadEnable()
    }
    func switchAccount() {
        return PreloadMananger.shared.switchAccount()
    }
}

extension LarkPreload.TaskState {
    var mailTaskState: MailSDK.PreloadTaskState {
        switch self {
        case .unStart:
            return .unStart
        case .await:
            return .wait
        case .start:
            return .start
        case .run:
            return .run
        case .end:
            return .end
        case .cancel:
            return .cancel
        case .disableByLowDevice:
            return .disableByLowDevice
        case .disableByHitRate:
            return .disableByHitRate
        }
    }
}
