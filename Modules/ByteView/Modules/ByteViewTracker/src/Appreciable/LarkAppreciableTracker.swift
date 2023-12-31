//
//  LarkAppreciableTracker.swift
//  ByteViewTracker
//
//  Created by kiri on 2021/12/27.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppReciableSDK

/// 主端可感知耗时，一级分类为appreciable_loading_time
public final class LarkAppreciableTracker {
    public static let shared = LarkAppreciableTracker()
    private let queue = DispatchQueue(label: "ByteViewCommon.LarkAppreciableTracker")
    private var keyParis: [Event: DisposedKey] = [:]

    /// start event
    /// - Parameters:
    ///   - scene: Scene
    ///   - event: eventName
    ///   - extraCategory: 更多的信息，AppReciableSDK.Extra.category
    public func start(scene: Scene, event: Event, extraCategory: [String: Any]? = nil) {
        queue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.keyParis[event] != nil {
                self.cancel(event: event)
            }
            var extra: Extra?
            if let category = extraCategory {
                extra = Extra(category: category)
            }
            let disposedKey = AppReciableSDK.shared.start(biz: .VideoConference, scene: scene, event: event, page: nil, userAction: nil, extra: extra)
            self.keyParis[event] = disposedKey
        }
    }

    /// end
    /// - Parameters:
    ///   - key: start() return value.
    ///   - extraInfo: extra.extra
    ///   - latencyDetail 
    public func end(event: Event, extraInfo: [String: Any]? = nil, latencyDetail: [String: Any]? = nil) {
        queue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            guard let foundKey = self.keyParis[event] else {
                return
            }
            self.keyParis.removeValue(forKey: event)
            let extra = Extra(latencyDetail: latencyDetail, extra: extraInfo)
            AppReciableSDK.shared.end(key: foundKey, extra: extra)
        }
    }

    /// 统计开始事件后如果发生报错可以取消统计
    public func cancel(event: Event) {
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

    /// 统计加载失败
    public func error(scene: Scene, event: Event, errorType: ErrorType, errorLevel: ErrorLevel, errorCode: Int, errorMessage: String? = nil, extraInfo: [String: Any]? = nil) {
        queue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            guard self.keyParis[event] != nil else {
                return
            }
            self.keyParis.removeValue(forKey: event)
            let extra = Extra(extra: extraInfo)
            let error = ErrorParams(biz: .VideoConference, scene: scene, errorType: errorType, errorLevel: errorLevel, userAction: nil, page: nil, errorMessage: errorMessage, extra: extra)
            AppReciableSDK.shared.error(params: error)
        }
    }
}
