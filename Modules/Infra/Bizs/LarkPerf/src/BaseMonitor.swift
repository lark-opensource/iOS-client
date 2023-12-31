//
//  BaseMonitor.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/6/7.
//
import UIKit
import Foundation
import LKCommonsLogging
import LKCommonsTracker
import AppContainer

public class BaseMonitor: NSObject {
    static let logger = Logger.log(BaseMonitor.self, category: "BaseMonitor")

    private var queue: DispatchQueue = DispatchQueue(label: "BaseMonitor", qos: .utility)
    private var startTimeDict: [String: [String: CFTimeInterval]] = [:]
    private var metricDict: [String: [String: Any]] = [:]
    private var categoryDict: [String: [String: Any]] = [:]
    private var extraDict: [String: [String: Any]] = [:]

    override init() {
        super.init()
    }

    func serviceName() -> String {
        assertionFailure("must impl by subclass")
        return "default_service_name"
    }

    public func addCategoryInfo(monitor: String, info: [String: Any]) {
        queue.async {
            if self.categoryDict[monitor] == nil {
                self.categoryDict[monitor] = [:]
            }
            self.categoryDict[monitor]?.merge(info) { (_, new) in new }
        }
    }

    public func addMetricInfo(monitor: String, info: [String: Any]) {
        queue.async {
            if self.metricDict[monitor] == nil {
                self.metricDict[monitor] = [:]
            }
            self.metricDict[monitor]?.merge(info) { (_, new) in new }
        }
    }

    public func addExtraInfo(monitor: String, info: [String: Any]) {
        queue.async {
            if self.extraDict[monitor] == nil {
                self.extraDict[monitor] = [:]
            }
            self.extraDict[monitor]?.merge(info) { (_, new) in new }
        }
    }

    public func start(monitor: String, key: String) {
        let startTime = CACurrentMediaTime()
        start(monitor: monitor, key: key, startTime: startTime)
    }

    public func end(monitor: String, key: String) {
        let endTime = CACurrentMediaTime()
        end(monitor: monitor, key: key, endTime: endTime)
    }

    public func start(monitor: String, key: String, startTime: CFTimeInterval) {
        queue.async {
            if self.startTimeDict[monitor] == nil {
                self.startTimeDict[monitor] = [:]
            }
            if self.startTimeDict[monitor]?[key] != nil { return }
            self.startTimeDict[monitor]?[key] = startTime
        }
    }

    public func end(monitor: String, key: String, endTime: CFTimeInterval) {
        queue.async {
            if self.metricDict[monitor] == nil {
                self.metricDict[monitor] = [:]
            }
            if self.metricDict[monitor]?[key] != nil { return }
            if let startTime = self.startTimeDict[monitor]?[key] {
                let cost = (endTime - startTime) * 1_000
                self.metricDict[monitor]?[key] = cost
                self.metricDict[monitor]?[monitor] = cost
            }
        }
    }

    public func upload(monitor: String) {
        queue.async {
            guard let metricInfo = self.metricDict[monitor], !metricInfo.isEmpty else {
                return
            }
            Tracker.post(SlardarEvent(
                name: self.serviceName(),
                metric: self.metricDict[monitor] ?? [:],
                category: self.categoryDict[monitor] ?? [:],
                extra: self.extraDict[monitor] ?? [:])
            )
            Self.logger.info("finished sending metric: \(String(describing: self.metricDict[monitor]))"
                + "category:\(String(describing: self.categoryDict[monitor]))"
                + "extra: \(String(describing: self.extraDict[monitor]))")
            self.cleanData(monitor: monitor)
        }
    }

    public func cleanData(monitor: String) {
        startTimeDict[monitor] = [:]
        metricDict[monitor] = [:]
        categoryDict[monitor] = [:]
        extraDict[monitor] = [:]
    }
}
