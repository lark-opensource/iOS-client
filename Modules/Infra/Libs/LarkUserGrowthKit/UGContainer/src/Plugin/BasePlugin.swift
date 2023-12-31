//
//  BasePlugin.swift
//  UGContainer
//
//  Created by mochangxing on 2021/1/24.
//

import Foundation
import SwiftProtobuf
import ThreadSafeDataStructure
import LKCommonsTracker
import EENavigator

open class BasePlugin<T: ReachPoint>: ReachPointPlugin, ContainerServiceProvider {

    let id2ReachPoint: SafeDictionary<String, T> = [:] + .readWriteLock
    weak var containerSevice: PluginContainerService?

    private let navigator: Navigatable
    public init(navigator: Navigatable) {
        self.navigator = navigator
    }

    public var curReachPointIds: [String] {
        self.id2ReachPoint.keys.map { $0 }
    }

    public func obtainReachPoint<R>(reachPointId: String) -> R? where R: ReachPoint {
        return getReachPoint(reachPointId: reachPointId) as? R
    }

    public func recycleReachPoint(reachPointId: String) {
        if let reachPoint = id2ReachPoint.removeValue(forKey: reachPointId) {
            if Thread.isMainThread {
                reachPoint.onHide()
            } else {
                DispatchQueue.main.async {
                    reachPoint.onHide()
                }
            }
        }
        reportEvent(eventName: .onDestroy, reachPointId)
    }

    public func onShow(reachPointId: String, data: Data) {
        PluginContainerServiceImpl.log.info("onShow reachPointId: \(reachPointId), reachPointType: \(T.reachPointType)")
        guard let reachPoint = id2ReachPoint[reachPointId] else {
            PluginContainerServiceImpl.log.error("reachPoint not exist for \(reachPointId), reachPointType: \(T.reachPointType)")
            return
        }
        guard let model = decode(payload: data) else {
            Tracker.post(SlardarEvent(name: "ug_reach_container_deserialize_error", metric: [:], category: ["rpId":reachPointId], extra: [:]))
            PluginContainerServiceImpl.log.error("data can not be decode, \(reachPointId), reachPointType: \(T.reachPointType)")
            return
        }
        func doShow() {
            _ = reachPoint.onUpdateData(data: model)
            reachPoint.onShow()
        }

        if Thread.isMainThread {
            doShow()
        } else {
            DispatchQueue.main.async {
                doShow()
            }
        }
    }

    public func onHide(reachPointId: String) {
        PluginContainerServiceImpl.log.info("onHide reachPointId: \(reachPointId), reachPointType: \(T.reachPointType)")

        guard let reachPoint = id2ReachPoint[reachPointId] else {
            PluginContainerServiceImpl.log.error("reachPoint not exist for \(reachPointId), reachPointType: \(T.reachPointType)")
            return
        }
        if Thread.isMainThread {
            reachPoint.onHide()
        } else {
            DispatchQueue.main.async {
                reachPoint.onHide()
            }
        }
        reportEvent(eventName: .didHide, reachPointId)
    }

    public func onEnterForground() {}

    public func onEnterBackground() {}

    func decode(payload: Data) -> T.ReachPointModel? {
        return T.decode(payload: payload)
    }

    private func getReachPoint(reachPointId: String) -> T {
        return id2ReachPoint[reachPointId] ?? createReachPoint(reachPointId: reachPointId)
    }

    private func createReachPoint(reachPointId: String) -> T {
        let reachPoint = T()
        reachPoint.reachPointId = reachPointId
        reachPoint.containerSevice = containerSevice
        reachPoint.setNavigator(navigator: navigator)
        if var hideableReachPoint = reachPoint as? Hideable {
            hideableReachPoint.containerSeviceProvider = { [weak self] in
                self?.containerSevice
            }
        }

        reachPoint.onCreate()
        id2ReachPoint[reachPointId] = reachPoint
        reportEvent(eventName: .onCreate, reachPointId)
        return reachPoint
    }

    func reportEvent(eventName: ReachPointEvent.Key, _ reachPointId: String, _ extra: [String: String] = [:]) {
        containerSevice?.reportEvent(event: ReachPointEvent(eventName: eventName,
                                                            reachPointType: T.reachPointType,
                                                            reachPointId: reachPointId,
                                                            extra: extra))
    }
}
