//
//  MigrationMonitor.swift
//  LarkPerf
//
//  Created by tangyunfei.tyf on 2020/7/3.
//

import Foundation
import LKCommonsLogging
import LKCommonsTracker
import AppContainer

public final class MigrationMonitor: BaseMonitor {
    public static let shared = MigrationMonitor()
    private let logger = Logger.log(MigrationMonitor.self, category: "MigrationMonitor")

    public enum Scene: String {
        case migration = "qm_migrate"
    }

    public enum MetricKey: String {
        case migrationTime = "migration_time"
        case totalTime = "total_time"
        case timespend = "timespend"
    }

    override func serviceName() -> String {
        return "qm_migrate"
    }

    public func start(scene: Scene) {
        self.logger.debug("start: scene \(scene.rawValue)")
        self.start(monitor: scene.rawValue, key: MetricKey.migrationTime.rawValue)
        self.start(monitor: scene.rawValue, key: MetricKey.totalTime.rawValue)
    }

    public func end(scene: Scene) {
        self.logger.debug("start: scene \(scene.rawValue)")
        self.end(monitor: scene.rawValue, key: MetricKey.totalTime.rawValue)
        self.upload(monitor: scene.rawValue)
    }

    public func update(scene: Scene, metricKey: MetricKey) {
        self.logger.debug("start: scene \(scene.rawValue)")
        self.end(monitor: scene.rawValue, key: metricKey.rawValue)
    }

    public func addExtraInfo(scene: Scene, info: [String: Any]) {
        self.logger.debug("scene \(scene.rawValue), add extra info: \(info)")
        self.addExtraInfo(monitor: scene.rawValue, info: info)
    }

    public func addCategoryInfo(scene: Scene, info: [String: Any]) {
        self.logger.debug("scene \(scene.rawValue) , add category info: \(info)")
        self.addCategoryInfo(monitor: scene.rawValue, info: info)
    }
}
