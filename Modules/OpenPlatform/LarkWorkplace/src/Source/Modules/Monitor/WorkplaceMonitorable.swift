//
//  WorkplaceMonitorable.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/8.
//

import Foundation
import ECOInfra

/// 工作台技术埋点参数设置协议。
///
/// 符合 OPMonitor 使用习惯的通用语法封装在协议和 `WorkplaceMonitorable+Extension.switf`。
/// 业务自定义结构的语法封装在 `WorkplaceMonitorable+Biz.swift`。
protocol WorkplaceMonitorable {
    @discardableResult
    func setValue(_ value: Any?, for key: WorkplaceMonitorKey) -> WorkplaceMonitorable

    @discardableResult
    func setMap(_ map: [WorkplaceMonitorKey: Any?]) -> WorkplaceMonitorable

    @discardableResult
    func setError(_ error: Error) -> WorkplaceMonitorable

    @discardableResult
    func timing() -> WorkplaceMonitorable

    /// 内部封装使用，业务调用应当使用 `flush()` 方法。
    func _flush(file: String, function: String, line: Int)
}

extension WorkplaceMonitorable {
    /// 刷新上报埋点，调用 `flush()` 方法后 `WorkpalceMonitor` 不会再持有埋点，可以认为此次埋点已经结束，相关上下文会清理。
    func flush(file: String = #fileID, function: String = #function, line: Int = #line) {
        _flush(file: file, function: function, line: line)
    }
}
