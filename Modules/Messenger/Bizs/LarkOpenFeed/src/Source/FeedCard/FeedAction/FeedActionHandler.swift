//
//  FeedActionHandler.swift
//  LarkOpenFeed
//
//  Created by liuxianyu on 2023/8/22.
//

import RxSwift
import RustPB
import LarkModel

public protocol FeedActionHandlerInterface {
    // Action 状态回调
    var actionStatus: Observable<FeedActionStatus> { get }
    // 代理
    var delegate: FeedActionHandlerDelegate? { get set }
    // Action 具体执行操作
    func executeTask()
    // Action 结果默认处理策略
    func handleResultByDefault(error: Error?)
}

public protocol FeedActionHandlerDelegate: AnyObject {
    func handleActionResult(handler: FeedActionHandlerInterface,
                            type: FeedActionType,
                            model: FeedActionModel,
                            error: Error?)
    // 由 Feed 方添加埋点
    func trackHandle(status: FeedActionStatus,
                     type: FeedActionType,
                     model: FeedActionModel)
}

// Action 操作状态
public enum FeedActionStatus {
    case willHandle                // 即将执行Action
    case didHandle(error: Error?)  // 已执行完Action(调用失败时返回error,error为空代表成功)
}

open class FeedActionHandler: FeedActionHandlerInterface {
    private var subject: PublishSubject<FeedActionStatus> = PublishSubject<FeedActionStatus>()
    public var actionStatus: Observable<FeedActionStatus> { subject.asObservable() }
    public weak var delegate: FeedActionHandlerDelegate?
    public let type: FeedActionType
    public let model: FeedActionModel

    public func willHandle() {
        subject.onNext(.willHandle)
        trackHandle(status: .willHandle)
        delegate?.trackHandle(status: .willHandle, type: type, model: model)
    }

    public func didHandle(error: Error? = nil) {
        delegate?.handleActionResult(handler: self, type: type, model: model, error: error)
        subject.onNext(.didHandle(error: error))
        trackHandle(status: .didHandle(error: error))
        delegate?.trackHandle(status: .didHandle(error: error), type: type, model: model)
    }

    open func executeTask() {
        assertionFailure("must override")
    }

    // handler 自身添加埋点
    open func trackHandle(status: FeedActionStatus) {}

    open func handleResultByDefault(error: Error?) {}

    public init(type: FeedActionType, model: FeedActionModel) {
        self.type = type
        self.model = model
    }
}
