//
//  ContainerManagerInterface.swift
//  LarkAccountInterface
//
//  Created by SolaWing on 2023/10/31.
//

import Foundation
import LarkContainer

// swiftlint:disable missing_docs

/// TODO: 容器管理实现组件目前没有整理下沉，但passport需要调用，所以接口先放在Interface里，以后变成独立库后再迁移

/// 容器生命周期管理类接口。负责端上和Rust容器的上下线管理
/// 设计文档：https://bytedance.feishu.cn/docx/ECwfdXcT4oBVLfxdPN8chX0gnYg#S66SdY5SfoP6BLxJ83ucLcQ0n7C
public protocol LarkContainerManagerInterface {
    /// input: user list change
    /// 触发用户列表变化流程。该流程为串行执行，新的变化流程需要等之前的流程中断后才能开始..
    /// - Parameters:
    ///     - userList: 要上线的用户列表，包含前台用户.. TODO: 如果用户的sessionKey和当前不一致，会强制重新登录
    ///     - delegate: 会持有到流程结束。调用方应该创建隔离实例避免不同的调用之间串回调
    func userListChange(userList: [User], foregroundUser: User?, action: PassportUserAction,
                               delegate: LarkContainerManagerFlowProgressDelegate)
}

/// 会导致流程异常结束的error
public enum LarkContainerManagerFlowError: Error {
    /// 未区分其他错误
    case other(Error?)
    /// 前台上线失败，内部无法处理，需要触发新的流程
    case foregroundOnlineFailed(Error)
    /// 还没执行，就被新的流程打断
    case cancelled
    /// 执行后完结前，被新的流程打断
    case interruptted
}

public protocol LarkContainerManagerFlowProgressDelegate {
    /// 流程生命结束时必定调用
    /// 正常流程调用时机为所有的userList都处理完毕。异常结束流程时机参考LarkContainerManagerFlowError
    func didCompleteWithError(_ error: LarkContainerManagerFlowError?)

    // MARK: 正常流程通知

    /// 前台上线或者切换完成
    func afterForegroundChange()
}

public extension LarkContainerManagerFlowProgressDelegate {
    func afterForegroundChange() {}
}
// swiftlint:enable missing_docs
