//
//  WorkplaceContext.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/6.
//

import Foundation
import ECOInfra
import LarkNavigator
import LarkContainer

/// 工作台 Context 上下文。
///
/// 定位和作用:
/// 作为通用场景的基建，流转在各处业务中，带有各种基建工具和上下文信息。
/// 业务可以利用 `Context` 获取 `userId`, `navigator`, `userResolver`, `trace`, 埋点, 通用状态存储等。
///
/// 规范讨论:
/// Context 作为非常通用的命名和概念，如果不做约束，天然容易膨胀腐化。
/// 引入一个能力到 Context 很容易，但引入的判断需要更谨慎，下面也讨论了一些例子（大部分是反例）。
/// 整体上我们需要遵守如下的规范来维护和使用 Context。
///
/// 1. 如何判断一个字段是否可以被加进来？
///     * 这个字段是否可以被任意业务模块使用，是否具有足够的通用性（弱业务或零业务特征）。
///     * 这个字段的初始化是否足够轻量（初始化依赖少，耗时，内存等性能考量）。
///     * 是否符合字段本身的业务使用最佳实践。
///     * 在工作台团队内达成共识（实际实践中，维护团队的约定和共识更加重要，避免信息不对齐导致的理解偏差）。
///
///     * 举例:
///         * 是否应该放一个通用的 Logger 在 Context？
///         否，因为 Lark 内 Logger 的最佳实践是通过 static 成员声明到类型中使用的。
///         同时如果有特殊的日志串联诉求，也应当通过 trace log 的串联能力来实现。
///         ```
///         context.info("log something")
///         ```
///
///         * 是否可以将 Badge 能力放入 Context？
///         否，Badge 能力在工作台虽然在几乎所有业务场景下都有使用，但是属于一个特定的业务能力，没有弱业务和零业务特征。
///         业务应当通过依赖注入显式声明其依赖，而不是放入 Context 中间接隐藏了依赖。
///
///         * ConfigService 是否应当被放入 Context?
///         是，Config（FG，Settings）能力是一个业务无关的通用能力，虽然本身有一定的初始化成本（需要通过依赖注入 resolve），
///         但本身的生成成本可接受，且实际中每次迭代理论上都需要 FG/Settings 控制包裹，是一个比较强的团队共识和零业务能力。
///
///         * 很多地方依赖 Account, 是否可以将 AccountService 放入 Context？
///         否，AccountService 虽然可能有很多业务需要使用，但它做外工作台外部业务能力，虽然是业务基建，但初始化成本并不透明。
///         同时 Account 作为基础业务，需要使用时需要明确做为外部声明依赖，而不是作为 context 成员隐式依赖。
///
/// 2. Context 的生成和使用。
///     * Context 默认被注册在 userGraph scope 中，每次 resolve 会产生新的实例。
///     * Context 的生成唯一依赖入参 trace，业务实际使用中不应该关心 trace 的生成，只用关心当前上下文的获取和使用。
///     * 如果一个业务需要使用 Context，那么它的初始化应当显示传入 Context 参数。
///     * 哪些内容依赖 Context 提供的能力？
///         * 需要获取 user 相关的信息和基础能力。
///         * 需要使用 trace 能力。
///         * 需要获取配置（FG，Settings）。
///         * 技术埋点(详细使用见 WorkplaceMotnitor 注释）。
///         * 业务埋点(详细使用见 WorkplaceTracker 注释）。
///         * KV 状态存取。
///
/// 3. Context 的传递。
///     * 一个 Context 和一个 trace 强绑定，传递 Context 时需要注意使用业务的所在的层级场景。
///     * 大部分业务场景，应当通过 resolve 方式在业务容器初始化时初始化好 Context 并使用。
///     ```
///     /// root trace
///     user.regiser(SomeService.self) { r in
///         let rootTrace = try r.resolve(assert: WPTraceService.self).root
///         let context = try r.resolve(assert: WorkplaceContext.self, argument: rootTrace)
///         return SomeServiceImpl(context: context)
///     }
///     /// some subTrace
///     func handle(_ body: WorkplaceTemplateBody, req: EENavigator.Request, res: EENavigator.Response) throws {
///         let traceService = try userResolver.resolve(assert: WPTraceService.self)
///         let trace = traceService.lazyGetTrace(for .lowCode, with: body.initData.portalId)
///         let context = try userResolver.resolve(assert: WorkplaceContext.self, argument: trace)
///         let vc = TemplateViewController(context: context, ...)
///         res.end(resource: vc)
///     }
///     ```
///
/// 4. 其他
///     * 我当前业务场景比较难处理，很难具备获取/生成 Context 的条件，应当如何处理？
///     当前暂时不具备获取/生成 Context 的业务，也可以通过自行生成/传递单独的基建能力来完成，不强制要求一定使用 Context。
///
///     * 应当使用 `context.userResolver` 生成需要的 service，还是通过外部依赖注入 init 时传入？
///     应当通过外部依赖注入传入，原因如下：
///         * 外部依赖应当显示且明确声明，而不是隐藏在内部。
///         * 外部生成，大部分在 Swinject / Router 场景下，通过 `try userResolver.resolve(assert: SomeService.self)`
///           的方式可以交由框架处理失败，如果自行 resolve，则需要自行捕获 throw error 并处理异常。
///         * `context.userResolver` 更多的是用于一些特殊场景或者需要传递给子系统时使用的。
///
final class WorkplaceContext {
    /// 用户态 resolver，需要自行处理 resolve 失败情况。
    ///
    /// 传递给子系统的 userResolver 或者需要特殊 resolve 的对象。
    /// ```
    /// let userResolver = context.userResolver
    /// let someService = try? context.userResolver.resolve(assert: SomeService.self)
    /// ```
    let userResolver: UserResolver

    /// 用户态 pushCenter
    let userPushCenter: PushNotificationCenter

    /// 当前 context 场景所使用的 trace。
    ///
    /// ```
    /// context.trace.log("log something")
    /// ```
    ///
    /// **关于 trace 的最佳实践:**
    /// 现有工作台代码中，我们已经实现了 WPTraceService 来管理各级 trace，但业务实际使用时并不顺手，
    /// 主要原因是具体的容器内部业务逻辑很难理解 trace 的层级和获取，而且业务也不应当关心这些逻辑，后续 WPTraceService 还需要单独做一些优化。
    /// 使用视角看，业务逻辑直接通过 `context.trace` 取得相应的 trace 使用即可。
    /// trace 的生成最佳实践：
    /// * trace 的获取和组装，理论上跟随 context 的生成，放在各个容器入口处即可。
    /// * 容器入口天然应当关心 trace 的层级可取用。
    /// * 常见的容器入口。
    ///     * 依赖注入 register 的 service 初始化。
    ///     * RouterHandler 中 VC 的初始化。
    ///     * 业务内部派生子业务的入口。
    /// * 一个简单的判断条件: 能够获取到 Resolver 的容器初始化入口，即是生成 Context/Trace 最合适的地方。
    /// * 统一获取还是从父级传递派生?
    ///     * 理论上最好是通过传递 trace，然后业务在需要的场景派生。
    ///     * 目前工作台实际是在 WPTraceService 统一管理的，原因是因为我们的二级 trace 是门户生命周期的概念，为了适应取用场景。
    ///     * 当前场景，上述两种方式都能接受。最终态我们希望通过传递 Context & Trace 的方式来处理，WPTraceService 的管理被隐藏起来不被业务直接感知。
    let trace: OPTrace

    /// 配置服务，可获取 FG，Settings 相关配置。
    ///
    /// ```
    /// let enable = context.configService.fgValue(for: .someKey)
    /// let config = context.configService.settingValue(SomeConfig.self)
    /// ```
    let configService: WPConfigService

    /// 技术埋点入口(详细使用见 WorkplaceMotnitor 注释）。
    ///
    /// ```
    /// context.monitor
    ///     .start(.someMonitorCode)
    ///     .setValue(someValue, for: .someKey)
    ///     .setError(error)
    ///     .flush()
    /// ```
    let monitor: WorkplaceMonitor

    /// 业务埋点入口(详细使用见 WorkplaceTracker 注释）。
    ///
    /// ```
    /// context.tracker
    ///     .start(.someEventName)
    ///     .setValue(someValue, for: .someKey)
    ///     .post()
    /// ```
    let tracker: WorkplaceTracker

    /// 内存态 KV 存储
    ///
    /// ```
    /// context.store.setValue(someValue, for: someKey)
    /// let someValue = context.store.getValue(for: someKey)
    /// ```
    ///
    /// 关于 Context 内存态 KV 存储的最佳实践:
    /// 作为 Context 提供的基础能力，业务可以将自己的内存态状态存储在 store 中。
    /// 使用 store 可以方便的进行存取，但也有可能带来一些副作用，因此需要明确一些最佳实践：
    /// * store 的优点比较明显，不需要业务单独声明，即可自由方便的存取一些状态。
    /// * 存储在 store 中的实体，天然缺失了声明，很难从外部看到当前有哪些内容被存储，只能基于代码上下文和约定做判断。
    ///     * 如果业务场景所需要的状态和属性，应当尽量做显式声明而不是存储在 store 中。
    ///     * 如果是业务弱依赖，性能，或者其他非主链路场景的属性，则可以存储在 store 以简化逻辑。如某些埋点状态，性能信息等。
    ///     * Context 是引用类型，在跨业务容器场景中，应当重新生成 Context 而不是传递引用。
    ///         * 不同的 context.store 应当内聚在业务容器中，避免被其他业务访问到。
    ///         * 如果满足上述场景的属性，同时有需要跨业务传递的，则应当在业务初始化是在新创建的 Context 填充初始信息。
    let store: WorkplaceStore

    /// 当前用户 userId
    var userId: String {
        return userResolver.userID
    }

    /// 当前用户态 navigator
    var navigator: UserNavigator {
        return userResolver.navigator
    }

    init(
        userResolver: UserResolver,
        userPushCenter: PushNotificationCenter,
        trace: OPTrace,
        configService: WPConfigService
    ) {
        self.userResolver = userResolver
        self.userPushCenter = userPushCenter
        self.trace = trace
        self.configService = configService
        self.monitor = WorkplaceMonitor(trace: trace)
        self.tracker = WorkplaceTracker(userId: userResolver.userID)
        self.store = WorkplaceStore()
    }
}
