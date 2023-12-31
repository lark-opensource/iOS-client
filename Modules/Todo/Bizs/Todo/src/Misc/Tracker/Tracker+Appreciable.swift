//
//  CoreTracker.swift
//  Todo
//
//  Created by 张威 on 2021/6/18.
//

import Foundation
import AppReciableSDK
import MetricKit

/// 用户可感知埋点

extension Tracker {
    struct Appreciable { }
}

private typealias SDKScene = Scene
private typealias SDKEvent = Event

// MARK: - Task

extension Tracker.Appreciable {

    /// 可感知埋点 Task
    final class Task {
        var isNeedNet = false
        var latencyDetail = [String: Any]()
        var metric = [String: Any]()
        var category = [String: Any]()
        var extra = [String: Any]()

        private let scene: Scene
        private let event: Event
        private var key: DisposedKey?
        private var isStoped = false

        init(scene: Scene, event: Event) {
            self.isNeedNet = false
            self.scene = scene
            self.event = event
        }

        @discardableResult
        func resume() -> Self {
            key = AppReciableSDK.shared.start(biz: .Todo, scene: scene.asSDKType(), event: event.asSDKType(), page: nil)
            return self
        }

        @discardableResult
        func complete() -> Self {
            guard let key = key else {
                assertionFailure("make sure task has been resumed")
                return self
            }
            guard !isStoped else {
                return self
            }
            isStoped = true
            let sdkExtra = Extra(
                isNeedNet: isNeedNet,
                latencyDetail: latencyDetail.isEmpty ? nil : latencyDetail,
                metric: metric.isEmpty ? nil : metric,
                category: category.isEmpty ? nil : category,
                extra: extra.isEmpty ? nil : extra
            )
            AppReciableSDK.shared.end(key: key, extra: sdkExtra)
            return self
        }

        @discardableResult
        func error(_ msg: String) -> Self {
            guard let key = key else {
                assertionFailure("make sure task has been resumed")
                return self
            }
            let sdkExtra = Extra(
                isNeedNet: isNeedNet,
                latencyDetail: latencyDetail.isEmpty ? nil : latencyDetail,
                metric: metric.isEmpty ? nil : metric,
                category: category.isEmpty ? nil : category,
                extra: extra.isEmpty ? nil : extra
            )
            let errParams = ErrorParams(
                biz: .Todo,
                scene: scene.asSDKType(),
                event: event.asSDKType(),
                errorType: .Network,
                errorLevel: .Exception,
                errorCode: 0,
                userAction: nil,
                page: nil,
                errorMessage: msg,
                extra: sdkExtra
            )
            isStoped = true
            AppReciableSDK.shared.error(params: errParams)
            return self
        }

        @discardableResult
        func error(_ err: Error) -> Self {
            return error(err.localizedDescription)
        }
    }

}

// MARK: - Scene

extension Tracker.Appreciable {
    enum Scene {
        /// 任务中心
        case center
        /// 详情
        case detail
        /// 新建
        case create
        /// 评论
        case comment
        /// 会话内列表
        case listInChat

        fileprivate func asSDKType() -> SDKScene {
            switch self {
            case .center: return .TodoCenter
            case .detail: return .TodoDetail
            case .create: return .TodoCreate
            case .comment: return .TodoComment
            case .listInChat: return .TodoListInChat
            }
        }
    }
}

// MARK: - Event

extension Tracker.Appreciable {
    enum Event {
        /// 任务中心冷启动
        case centerColdLaunch
        /// 任务中心切换 filter
        case centerSwitchFilter
        /// 任务中心加载更多
        case centerLoadMore
        /// 加载详情页
        case detailLoad
        /// 加载任务来源
        case detailLoadSource
        /// 历史记录加载
        case detailEditRecordLoad
        /// 历史记录加载更多
        case detailEditRecordLoadMore
        /// 新建 Todo
        case createTodo
        /// 加载评论首页
        case commentLoadFirstPage
        /// 发送评论（新建/编辑/回复）
        case commentSend
        /// 删除评论
        case commentDelete
        /// 新增评论 reaction
        case commentReactionAdd
        /// 删除评论 reaction
        case commentReactionDelete
        /// 会话内任务列表加载首页
        case inChatLoadFirstPage
        /// 会话内任务列表加载更多
        case inChatLoadMore

        fileprivate func asSDKType() -> SDKEvent {
            switch self {
            case .centerColdLaunch: return .todoCenterColdLaunch
            case .centerSwitchFilter: return .todoCenterSwitchFilter
            case .centerLoadMore: return .todoCenterLoadMore
            case .detailLoad: return .todoDetailLoad
            case .detailLoadSource: return .todoDetailLoadSource
            case .detailEditRecordLoad: return .todoDetailEditRecordLoad
            case .detailEditRecordLoadMore: return .todoDetailEditRecordLoadMore
            case .createTodo: return .todoCreate
            case .commentLoadFirstPage: return .todoCommentLoadFirstPage
            case .commentSend: return .todoCommentSend
            case .commentDelete: return .todoCommentDelete
            case .commentReactionAdd: return .todoCommentReactionAdd
            case .commentReactionDelete: return .todoCommentReactionDelete
            case .inChatLoadFirstPage: return .todoInChatLoadFirstPage
            case .inChatLoadMore: return .todoInChatLoadMore
            }
        }
    }
}
