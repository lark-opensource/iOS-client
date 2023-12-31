//
//  WorkplaceMonitorWrapper.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/8.
//

import Foundation
import ECOInfra

/// 对 OPMonitor 的封装，业务不应该直接使用此类型。
final class WorkplaceMonitorWrapper: WorkplaceMonitorable {
    private static let eventName = "op_workplace_event"

    let monitor: OPMonitor
    let flushHandler: (WorkplaceMonitorWrapper) -> Void

    init(code: OPMonitorCodeProtocol, flushHandler: @escaping (WorkplaceMonitorWrapper) -> Void) {
        self.monitor = OPMonitor(WorkplaceMonitorWrapper.eventName)
        self.flushHandler = flushHandler
        self.monitor.setMonitorCode(code)
    }

    @discardableResult
    func setValue(_ value: Any?, for key: WorkplaceMonitorKey) -> WorkplaceMonitorable {
        monitor.addCategoryValue(key.rawValue, value)
        return self
    }

    @discardableResult
    func setMap(_ map: [WorkplaceMonitorKey: Any?]) -> WorkplaceMonitorable {
        map.forEach { (key, value) in
            monitor.addCategoryValue(key.rawValue, value)
        }
        return self
    }

    @discardableResult
    func setValue(_ value: Any, for key: String) -> WorkplaceMonitorable {
        monitor.addCategoryValue(key, value)
        return self
    }

    @discardableResult
    func setMap(_ map: [String : Any]) -> WorkplaceMonitorable {
        monitor.addCategoryMap(map)
        return self
    }

    @discardableResult
    func setError(_ error: Error) -> WorkplaceMonitorable {
        monitor.setError(error)
        return self
    }

    @discardableResult
    func timing() -> WorkplaceMonitorable {
        monitor.timing()
        return self
    }

    func _flush(file: String, function: String, line: Int) {
        flushHandler(self)
        monitor.flush(fileName: file, functionName: function, line: line)
    }
}
