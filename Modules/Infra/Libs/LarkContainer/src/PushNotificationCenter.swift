//
//  PushNotificationCenter.swift
//  LarkContainer
//
//  Created by liuwanlin on 2018/4/22.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public protocol PushMessage {}

private let userInfoKey = String(describing: PushNotificationCenter.self) + ".userInfoKey"

public class PushNotificationCenter {
    final class SharedState {
        let post = DispatchQueue(label: "PushNotificationCenter.postQueue")
        let subscribe: SerialDispatchQueueScheduler
        let observe = { () -> ConcurrentDispatchQueueScheduler in
            let queue = DispatchQueue(
                label: "PushNotificationCenter.observeQueue",
                attributes: .concurrent
            )
            return ConcurrentDispatchQueueScheduler(queue: queue)
        }()
        // 出于兼容性考虑，不影响原来注册到全局单例上的行为
        var replayLatest: [Notification.Name: Any] = [:]

        init() {
            subscribe = SerialDispatchQueueScheduler(
                queue: post, internalSerialQueueName: "PushNotificationCenter.subscribe"
            )
        }
    }
    private static let global = SharedState()
    public init() {}

    /// Post message
    ///
    /// - parameter message: The message to be pushed.
    /// - parameter replay: Whether replay the lastest element for the specified push.
    ///                     If true, you could subscribe the lastest element when pass true in observable(for:replay:).
    public func post<T: PushMessage>(_ message: T, replay: Bool = false) {
        Self.global.post.async { [self] in
            let name = self.name(for: T.self)
            NotificationCenter.default.post(name: name, object: notificationObject, userInfo: [userInfoKey: message])
            if replay {
                storeReplay(name: name, message: message)
            }
        }
    }

    /// Observable for PushMessage
    ///
    /// - parameter type: The specified push type.
    /// - parameter replay: Whether replay the lastest element for the specified push.
    ///                     If true, you must also pass true in post method for that specified push.
    public func observable<T: PushMessage>(for type: T.Type, replay: Bool = false) -> Observable<T> {
        let name = self.name(for: type)
        var ob = NotificationCenter.default.rx.notification(name)
            .flatMap { (notification) -> Observable<T> in
                // notification.object是发送的对象, 可能是用隔离scope对象发送的
                if let notificationObject = self.notificationObject {
                    /// 用户态接收
                    if let userSender = notification.object as? PushNotificationCenter, notificationObject !== userSender {
                        /// 用户不一致，不处理
                        return .empty()
                    }
                    // 用户一致，或者全局command，OK..
                } else {
                    /// 全局态接收
                    if let userSender = notification.object as? ScopedPushNotificationCenter {
                        if !userSender.allowGlobalReceiver {
                            return .empty()
                        }
                        if let userID = userSender.userID {
                            let messageType = String(reflecting: T.self)
                            UserExceptionInfo.log(.init(
                                scene: "PushNotificationCenter", key: messageType,
                                message: "应该使用userPushCenter来接收用户push",
                                calleeState: .old,
                                // 这里需要的是监听方的堆栈，发送方的堆栈没有意义
                                recordStack: false, isError: true))
                        } else {
                            #if DEBUG || ALPHA
                                preconditionFailure("ScopedPushNotificationCenter should have a userID")
                            #endif
                        }
                        // TODO: 用户隔离: 迁移完成后改成拦截
                        // return .empty()
                    }
                }
                guard let userInfo = notification.userInfo,
                    let message = userInfo[userInfoKey] as? T else {
                    return .empty()
                }

                return Observable.just(message)
            }

        if replay {
            ob = Observable.deferred { [ob] in
                // 在subscribe时，从postqueue上获取最新的值, 保证线程安全
                if let latest: T = self.getReplay(name: name) {
                    return ob.startWith(latest)
                }
                return ob
            }.subscribeOn(Self.global.subscribe)
        }

        return ob.observeOn(Self.global.observe)
    }

    public func driver<T: PushMessage>(for type: T.Type, replay: Bool = false) -> Driver<T> {
        return self.observable(for: type, replay: replay).asDriver(onErrorRecover: { _ in
            return Driver<T>.empty()
        })
    }

    // 全局的不做对象的过滤
    var notificationObject: AnyObject? { nil }

    func storeReplay<T: PushMessage>(name: Notification.Name, message: T) {
        Self.global.replayLatest[name] = message
    }
    func getReplay<T: PushMessage>(name: Notification.Name) -> T? {
        return Self.global.replayLatest[name] as? T
    }

    func name<T: PushMessage>(for type: T.Type) -> Notification.Name {
        let name = "PushNotificationCenter." + String(UInt(bitPattern: ObjectIdentifier(type)))
        return Notification.Name(name)
    }
}

/// 原来只有一个全局单例
/// 需要进行用户隔离，只能在接受对应隔离实例上的消息。
/// 因此需要明确的区分全局和用户隔离的对象。
/// 该类创建了一个对应的隔离实例。
///
/// 可能出现以下情况：
/// 1. 发送方和接收方一致。OK
/// 2. 发送方是全局消息，接收方是用户实例，OK
/// 3. 发送方是用户消息，接收方是全局实例，ERROR。迁移期间暂时兼容但最终会禁止
public final class ScopedPushNotificationCenter: PushNotificationCenter {
    public var userID: String? // 统计隔离参数
    public var allowGlobalReceiver: Bool = true
    var replayLatest: [AnyHashable: Any] = [:]

    override func storeReplay<T>(name: Notification.Name, message: T) where T: PushMessage {
        replayLatest[name] = message
        /// 主要是出于兼容性考虑，全局也存一份，如果使用原来的全局监听的也能接收到
        /// TODO: 将来迁移完成，这一部分代码需要清理掉，post和observe的应该是同一实例
        super.storeReplay(name: name, message: message)
    }
    override func getReplay<T>(name: Notification.Name) -> T? where T: PushMessage {
        // 如果是用全局发的，也可以获取对应的replay..
        (replayLatest[name] as? T) ?? super.getReplay(name: name)
    }
    override var notificationObject: AnyObject? { return self }
}
