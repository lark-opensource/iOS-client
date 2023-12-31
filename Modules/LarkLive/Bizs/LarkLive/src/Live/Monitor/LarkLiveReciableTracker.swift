//
//  LarkLiveReciableTracker.swift
//
//  Created by yangyao on 2021/9/17.
//

import Foundation
import AppReciableSDK

class LarkLiveReciableTracker {
    static let shared = LarkLiveReciableTracker()
    private let queue = DispatchQueue(label: "lark.larklive.AppReciableTracker")
    private var keyParis: [Event: DisposedKey] = [:]

    /// start event
    /// - Parameters:
    ///   - biz: Biz
    ///   - scene: Scene
    ///   - event: eventName
    ///   - page: Which ViewController. 当前事件发生在哪个页面
    ///   - extra: more infomation that user passed. 更多的信息
    public func start(biz: Biz,
                      scene: Scene,
                      event: Event,
                      page: String? = nil,
                      userAction: String? = nil,
                      extra: Extra? = nil) {
        queue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.keyParis[event] != nil {
                self.cancelStart(event: event)
//                assertionFailure("last time no end or cancel for key:\(event)")
            }
            let disposedKey = AppReciableSDK.shared.start(biz: biz, scene: scene, event: event, page: page, userAction: userAction, extra: extra)
            self.keyParis[event] = disposedKey
        }
    }

    /// end
    /// - Parameters:
    ///   - key: start() return value.
    ///   - extra: more infomation that user passed. 更多的信息
    public func end(event: Event, extra: Extra? = nil) {
        queue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            guard let foundKey = self.keyParis[event] else {
                return
            }
            self.keyParis.removeValue(forKey: event)
            AppReciableSDK.shared.end(key: foundKey, extra: extra)
        }
    }

    //统计开始事件后如果发生报错可以取消统计
    public func cancelStart(event: Event) {
        queue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            guard self.keyParis[event] != nil else {
//                assertionFailure("no start key:\(event) when canceled")
                return
            }
            self.keyParis.removeValue(forKey: event)
        }
    }

    public func error(biz: Biz = .VideoConference,
                      scene: Scene,
                      event: Event,
                      errorType: ErrorType = .Network,
                      errorLevel: ErrorLevel = .Exception,
                      page: String? = nil,
                      userAction: String? = nil,
                      error: Error,
                      extra: Extra? = nil) {
        let params = ErrorParams(biz: biz,
                                 scene: scene,
                                 event: event,
                                 errorType: errorType,
                                 errorLevel: errorLevel,
                                 errorCode: error.larkLive.code,
                                 userAction: userAction,
                                 page: page,
                                 errorMessage: error.larkLive.message,
                                 extra: extra)
        AppReciableSDK.shared.error(params: params)
    }
}

