//
//  WorkplaceMonitor.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/6.
//

import Foundation
import ECOInfra
import ECOProbeMeta
import ThreadSafeDataStructure

/// 工作台技术埋点封装。
///
/// ECOInfra & ECOInfraMeta 已经完整提供了相应的 meta 和埋点基础能力，但基建的接口灵活度太高，且工作台的使用较为随意，历史上还有多套封装，
/// WorkplaceMonitor 主要是通过对 OPMonitor 的封装，在基本符合 OPMonitor 使用习惯的基础上规范工作台场景的使用，
/// 让各处业务不容易写出散乱的代码。
///
/// 1. 主要埋点场景的使用，API 封装上尽量贴合了 OPMonitor 的使用习惯。
/// ```
/// /// 普通埋点
/// context.monitor
///     .start(.monitorCodeName)
///     .setValue(someValue, for: someKey)
///     .setError(error)
///     // ...
///     .flush()
///
/// /// 需要记录 duration 的埋点。
/// let monitor = context.monitor
///     .start(.monitorCodeName)
///     .timing()
///
/// // do something
/// // ...
///
/// monitor
///     .setValue(someValue, for: someKey)
///     .setError(error)
///     .timing()
///     .flush()
/// ```
///
/// 2.` WorkplaceMonitor` 封装 API 的说明。
///     * `WorkplaceMonitor` 提供了一系列 API 来约束和规范埋点的使用，尽量在编译层面避免写出散乱的代码。
///     * `WorkplaceMonitor` 初始化时必须提供 trace，如果不清楚，默认应当提供工作台 root trace。
///     * 网络状态，trace 等作为通用诉求，`WorkplaceMonitor` 在埋点 flush 时会默认带上，业务不需要专门设置。
///     * `WorkplaceMonitorProcess` 协议: `WorkplaceMonitor` 本身实现了 `WorkplaceMonitorProccess` 协议，主要用于控制埋点进程及记录埋点状态。
///         * 开始埋点时使用 `start(_:)` 方法，所有的工作台 MonitorCode 已经做了语法封装，可以直接用点语法找到自己需要埋点的 MonitorCode。
///             如：`context.monitor.start(.workplace_home_render_success)`
///     * `WorkplaceMonitorable` 协议: `WorkplaceMonitorProcess` 协议相关方法会返回 `WorkplaceMonitorable`, 各个埋点内容通过调用协议方法完成。
///         * 协议默认提供了 `setValue(_:for:)`, `setMap(_:)` 等通用方法来添加埋点参数。
///         * 同时提供了类似 `OPMonitor` 的 `setError(_:)`, `timing()`, `setResultType(_:)` 等便利方法作为语法糖使用。
///         * 类似 `OPMonitor` 提供了 `flush()` 方法完成刷新。
///         * 注意：调用 `flush()` 方法后 `WorkpalceMonitor` 不会再持有埋点，可以认为此次埋点已经结束，相关上下文会清理。
///
/// 3. 关于 Monitor 埋点的最佳实践。
///     * 工作台埋点都应当含有 trace，一般从 context 中带过来，如果单独使用需要初始化时传递，如果不清楚应该传递什么，默认应该给 root trace。
///     * 网络状态，trace 等默认已经在 flush() 方法中添加，不需要重复埋点。
///     * 初始化或恢复埋点时，应当使用点语法传递相应的 monitor code，尽量避免传递原始的 ECOProbeMeta 中定义的 code。
///         * 如果工作台后续增加了新的 Domain Code，则应当在 `WorkplaceMonitorProcess.swift` 中补充封装。
///     * 添加埋点参数时，除了使用相应的语法糖外:
///         * 单独的 KV 如果已经在 `WorkplaceMonitorKey.swift` 中定义, 则应当使用点语法来获取 key，而不是手写字符串。
///         * 如果一个 key 已经有多处埋点使用，那应当将这个 key 收敛到 `WorkplaceMonitorKey.swift` 中来。
///         * 如果业务想根据业务结构自定义参数封装，那么应当封装在 `WorkplaceMonitorable+Biz.swift` 中来。 比如：
///         ```
///         extension WorkplaceMonitorable {
///             func setInitData(_ initData: WPHomeVCInitData) -> WorkplaceMonitorable {
///                 return setValue(initData.id, for: .id)
///                     .setValue(initDat.portalType, for: "portal_type")
///                     // ...
///             }
///         }
///         ```
///     * Monitor 的 eventName 已经被 `WorkplaceMonitor` 在内部封装并隐藏起来，依赖此约束，强制后续业务必须使用新的规范，避免自行封装和散乱的代码出现。
///
final class WorkplaceMonitor {
    private let trace: OPTraceProtocol

    init(trace: OPTraceProtocol) {
        self.trace = trace
    }
}

extension WorkplaceMonitor: WorkplaceMonitorProcess {
    /// 内部封装使用，业务调用应当使用 `start(_:)` 方法。
    func _start(_ code: OPMonitorCodeProtocol) -> WorkplaceMonitorable {
        let wrapper = WorkplaceMonitorWrapper(code: code) { [weak self] monitor in
            guard let self = self else { return }
            monitor.setValue(PushNetStatus.netStatus.monitorValue, for: .net_status)
            monitor.monitor.tracing(self.trace)
        }
        return wrapper
    }
}
