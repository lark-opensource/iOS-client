//
//  WorkplaceTracker.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/9.
//

import Foundation
import ThreadSafeDataStructure

/// 工作台业务埋点封装。
///
/// LKCommonsTracker 已经完整提供了业务埋点基础能力，但目前工作台的使用较为随意，历史上还有多套封装，
/// WorkplaceTracker 主要是通过对 LKCommonsTracker 的封装，在基本符合原使用习惯的基础上规范工作台场景的使用，
/// 让各处业务不容易写出散乱的代码。
///
/// 1. 主要埋点场景的使用，API 封装上尽量贴合了 LKCommonsTracker 和 OPMonitor 的使用习惯。
/// ```
/// context.tracker
///     .start(.eventName)
///     .setValue(someValue, for: someKey)
///     // ...
///     .post()
/// ```
///
/// 2.` WorkplaceTracker` 封装 API 的说明。
///     * `WorkplaceTracker` 提供了一系列 API 来约束和规范埋点的使用，尽量在编译层面避免写出散乱的代码。
///     * userId 在用户态隔离后作为通用诉求，`WorkplaceTracker` 在埋点 post 时会默认带上，业务不需要专门设置。
///     * `WorkplaceTrackProcess` 协议: `WorkplaceTracker` 本身实现了 `WorkplaceTrackProcess` 协议，主要用于控制埋点进程及记录埋点状态。
///         * 开始埋点时使用 `start(_:)` 方法，所有的工作台 EventName 已经做了语法封装，可以直接用点语法找到自己需要埋点的 EventName。
///             如：`context.tracker.start(.appcenter_view)`
///     * `WorkplaceTrackable` 协议: `WorkplaceTrackProcess` 协议相关方法会返回 `WorkplaceTrackable`, 各个埋点参数通过调用协议方法完成。
///         * 协议默认提供了 `setValue(_:for:)`, `setMap(_:)` 等通用方法来添加埋点参数。
///         * 类似 `LKCommonsTracker` 提供了 `post()` 方法完成刷新。
///         * 注意：调用 `post()` 方法后 `WorkplaceTracker` 不会在持有埋点，可以认为此次埋点已经结束，相关上下文会清理。
///
/// 3. 关于 Tracker 埋点的最佳实践。
///     * userId默认已经在 post() 方法中添加，不需要重复埋点。
///     * 初始化或恢复埋点时，应当使用点语法传递相应的 eventName，尽量避免传递原始的 EventName 字符串。
///         * 如果工作台后续增加了新的 EventName，则应当在 `WorkplaceTrackEventName.swift` 中补充封装。
///     * 添加埋点参数时，除了使用相应的语法糖外:
///         * 单独的 KV 如果已经在 `WorkplaceTrackEventKey.swift` 中定义, 则应当使用点语法来获取 key，而不是手写字符串。
///         * 如果一个 key 已经有多处埋点使用，那应当将这个 key 收敛到 `WorkplaceTrackEventKey.swift` 中来。
///         * 如果业务想根据业务结构自定义参数封装，那么应当封装在 `WorkplaceTrackable+Biz.swift` 中来。
///     * Tracker 的 eventName 已经被 `WorkplaceTrackEventName` 封装，依赖此约束，强制后续业务必须使用新的规范，避免自行封装和散乱的代码出现。
///
final class WorkplaceTracker {
    private let userId: String

    init(userId: String) {
        self.userId = userId
    }
}

extension WorkplaceTracker: WorkplaceTrackProcess {
    /// 初始化埋点
    func start(_ name: WorkplaceTrackEventName) -> WorkplaceTrackable {
        let wrapper = WorkplaceTrackWrapper(name: name, userId: userId)
        return wrapper
    }
}
