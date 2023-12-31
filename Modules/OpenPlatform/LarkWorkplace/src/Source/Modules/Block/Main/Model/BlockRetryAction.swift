//
//  BlockRetryState.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/4/13.
//

import Foundation
import LarkSetting
import OPBlockInterface
import LarkOPInterface
import OPFoundation
import LarkContainer
import RxSwift
import LarkNavigation
import AnimatedTabBar
import LarkTab
import ECOProbe
import LKCommonsLogging

/// Block 重试逻辑
final class BlockRetryAction {
    static let logger = Logger.log(BlockRetryAction.self)

    /// 重试配置
    var retryConfig: BlockRetryConfig {
        return configService?.settingValue(BlockRetryConfig.self) ?? BlockRetryConfig.defaultValue
    }

    // TODO: 网络状态后续统一迁移，不再依赖 OPNetStatusHelper
    /// 网络状态
    private var netStatus: OPNetStatusHelper {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: WorkplaceScope.userScopeCompatibleMode)
        let status = try? userResolver.resolve(assert: OPNetStatusHelper.self)
        return status ?? OPNetStatusHelper()
    }

    /// 主导航状态
    private let navigationService: NavigationService?
    private let configService: WPConfigService?

    /// 重试原因，触发时机
    enum RetryReason {
        /// Block 获取 entity 网络失败
        case fetchEntityNetworkError
        /// Block 获取 guideInfo 网络失败
        case fetchGuideInfoNetworkError
        /// 加载 meta 失败
        case loadMetaError
        /// 加载 package 失败
        case loadPackageError
        /// 整体超时
        case loadingTimeout
        /// 网络状态变化
        /// 1. 离线状态切换为非离线状态
        /// 2. 弱网切换为正常状态
        case netStateChange
        /// 滚动至小组件可见
        case scrollToVisible
        /// 从其他 Tab 切换至工作台
        case switchToWorkspaceTab
        /// 工作台页面切换至前台
        case pageBecomeActive
        /// 用户主动点击重试
        case userClick
    }

    /// 当前 Block 的 appId，主要用于配置过滤
    let appId: String
    let blockId: String
    let blockTypId: String

    /// 重试行为的 action
    var action: (() -> Void)?

    /// 当前 Block 的加载状态
    ///
    /// 目前由 stateView 提供，同时任何 retry 逻辑触发器前，需要保证 stateView 已经更新到最新，因为需要结合 stateView 的状态判断重试条件。
    var stateProvider: (() -> WPCardStateView.State?)?

    /// 当前重试次数
    private var currentSilentRetryCount: Int = 0

    /// 是否可以进行静默重试
    ///
    /// 业务约定，如果进行过主动重试或者用户点击重试，则不再进行静默重试逻辑
    private var canSilentRetry: Bool = true

    /// 当前等待执行的重试逻辑
    private var retryWorkItem: DispatchWorkItem?

    /// 记录上次的网络状态
    private var lastNetworkStatus: OPNetStatusHelper.OPNetStatus?

    /// 上次重试原因
    private var lastRetryReason: RetryReason?

    private let disposeBag = DisposeBag()

    /// logger 的附加信息，复用一下，需要实时计算，不要改成存储属性
    private var debugInfo: [String: String] {
        return [
            "appId": appId,
            "blockId": blockId,
            "blockTypeId": blockTypId,
            "netStatus": "\(netStatus.status)",
            "currentState": stateProvider?()?.retryDebugString ?? ""
        ]
    }

    /// 埋点信息
    var monitorInfo: [String: Any] {
        var result: [String: Any] = [
            "net_status": "\(netStatus.status)",
            "retry_type": lastRetryReason?.monitorRetryType ?? 0, /* no_retry */
            "silent_retry_times": retryConfig.silentRetryTimes,
            "delay_time_step": retryConfig.delayTimeStep,
            "loading_timeout": retryConfig.loadingTimeout
        ]

        if let monitorSilentRetryFrom = lastRetryReason?.monitorSilentRetryFrom {
            result["silent_retry_from"] = monitorSilentRetryFrom
        }

        if let monitorActiveRetryFrom = lastRetryReason?.monitorActiveRetryFrom {
            result["active_retry_from"] = monitorActiveRetryFrom
        }

        return result
    }

    init(
        appId: String,
        blockId: String,
        blockTypeId: String,
        navigationService: NavigationService?,
        configService: WPConfigService?
    ) {
        self.appId = appId
        self.blockId = blockId
        self.blockTypId = blockTypeId
        self.navigationService = navigationService
        self.configService = configService

        Self.logger.info("[RetryAction] init block retry action", additionalData: [
            "config.silentRetryTimes": "\(retryConfig.silentRetryTimes)",
            "config.delayTimeStep": "\(retryConfig.delayTimeStep)",
            "config.loadingTimeout": "\(retryConfig.loadingTimeout)",
            "config.applyAll": "\(retryConfig.applyAll)",
            "config.available": "\(retryConfig.availableApps.contains(appId))",
            "config.activeRetryEnable": "\(retryConfig.activeRetryEnable)"
        ].merging(debugInfo, uniquingKeysWith: { $1 }))
        subscribeStatus()
    }

    deinit {
        retryWorkItem?.cancel()
        retryWorkItem = nil
        Self.logger.info("[RetryAction]: deinit", additionalData: debugInfo)
    }

    /// 注册监听重试触发时机
    private func subscribeStatus() {
        Self.logger.info("[RetryAction] subscribe status", additionalData: debugInfo)
        /// 注册监听时主动记录首次网络状态，用于后续比较
        lastNetworkStatus = netStatus.status

        /// 网络状态变化监听，触发主动重试逻辑
        /// 1. 离线状态切换为非离线状态
        /// 2. 弱网切换为正常状态
        NotificationCenter.default.rx.notification(.UpdateNetStatus)
            // 主线程监听，访问 debugInfo 会调用 stateProvider UI，网络状态通知是在异步线程通知的。
            // BlockView 初始化后极端情况下，网络状态变更可能触发 BlockView.statView 的 lazy init。
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self, let lastStatus = self.lastNetworkStatus else { return }
                Self.logger.info("[RetryAction] receive netStatus change", additionalData: [
                    "lastNetStatus": "\(lastStatus)"
                ].merging(self.debugInfo, uniquingKeysWith: { $1 }))

                let currentStatus = self.netStatus.status
                /// 离线状态切换为非离线状态
                if lastStatus.isOffline && !currentStatus.isOffline {
                    self.tryTriggerRetry(with: .netStateChange)
                }

                /// 弱网切换为正常状态
                if lastStatus.isWeak && currentStatus.isNormal {
                    self.tryTriggerRetry(with: .netStateChange)
                }

                /// 更新网络状态
                self.lastNetworkStatus = currentStatus
            })
            .disposed(by: disposeBag)

        /// tab 切换监听，从其他 tab 切换至工作台时触发主动重试逻辑
        navigationService?.tabDriver.drive { [weak self](oldTab, newTab) in
            Self.logger.info("[RetryAction] receive tab change", additionalData: [
                "oldTab": "\(oldTab)",
                "newTab": "\(newTab)"
            ].merging(self?.debugInfo ?? [:], uniquingKeysWith: { $1 }))
            guard let old = oldTab, let new = newTab else {
                return
            }
            // 其他 tab 切换至工作台
            if old != .appCenter, new == .appCenter {
                self?.tryTriggerRetry(with: .switchToWorkspaceTab)
            }
        }.disposed(by: disposeBag)

        /// 工作台页面切换至前台监听，触发主动重试逻辑
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                let animatedTabBar = RootNavigationController.shared.viewControllers.first as? AnimatedTabBarController

                Self.logger.info("[RetryAction] become active change", additionalData: [
                    "currentTab": "\(animatedTabBar?.currentTab)"
                ].merging(self?.debugInfo ?? [:], uniquingKeysWith: { $1 }))

                guard let currentTab = animatedTabBar?.currentTab,
                      currentTab == .appCenter else {
                    return
                }
                self?.tryTriggerRetry(with: .pageBecomeActive)
            })
            .disposed(by: disposeBag)
    }

    /// 根据场景触发重试
    func tryTriggerRetry(with reason: RetryReason) {
        Self.logger.info("[RetryAction]: try trigger retry", additionalData: [
            "reason": "\(reason)",
            "isAvailable": "\(retryConfig.availableApps.contains(appId))"
        ].merging(debugInfo, uniquingKeysWith: { $1 }))
        /// 重试的前提必须是失败状态
        guard let state = stateProvider?(), state.isLoadFailed else {
            return
        }

        /// 用户点击，直接重试
        if reason == .userClick {
            _initiativeRetry(reason)
            return
        }

        /// 总开关 & 配置项过滤
        guard retryConfig.applyAll || retryConfig.availableApps.contains(appId) else {
            return
        }

        if reason.isSilentRetry {
            trySilentRetry(reason)
        } else {
            tryInitiativeRetry(reason)
        }
    }

    /// 静默重试
    private func trySilentRetry(_ reason: RetryReason) {
        Self.logger.info("[RetryAction]: try silent retry", additionalData: [
            "canSilentRetry": "\(canSilentRetry)",
            "currentSilentRetryCount": "\(currentSilentRetryCount)",
            "silentRetryTimes": "\(retryConfig.silentRetryTimes)"
        ].merging(debugInfo, uniquingKeysWith: { $1 }))
        /// 触发条件判断
        guard canSilentRetry,                                                /* 是否进行过主动重试， */
              currentSilentRetryCount < retryConfig.silentRetryTimes,        /* 是否超过最大重试次数 */
              netStatus.status != .unavailable else {                        /* 当前网络非离线状态 */
            return
        }

        /// 如果上次有等着的重试逻辑，先取消掉
        if let lastItem = retryWorkItem {
            Self.logger.info("[RetryAction]: cancel last retry action", additionalData: debugInfo)
            lastItem.cancel()
            retryWorkItem = nil
        }

        // 延时时间，转换为 seconds
        let delayTime = TimeInterval(retryConfig.delayTimeStep)
            * TimeInterval(currentSilentRetryCount + 1) / 1_000.0
        let workItem = DispatchWorkItem { [weak self] in
            Self.logger.info("[RetryAction]: do slient retryAction", additionalData: [
                "currentSilentRetryCount": "\(self?.currentSilentRetryCount)"
            ].merging(self?.debugInfo ?? [:], uniquingKeysWith: { $1 }))
            self?.lastRetryReason = reason
            self?.currentSilentRetryCount += 1
            self?.action?()
            self?.retryWorkItem = nil
        }
        self.retryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delayTime, execute: workItem)
    }

    /// 主动重试
    private func tryInitiativeRetry(_ reason: RetryReason) {
        Self.logger.info("[RetryAction]: try initiative retry", additionalData: debugInfo)
        guard retryConfig.activeRetryEnable,                /* 是否开启主动重试 */
              netStatus.status != .unavailable else {       /* 当前网络非离线状态 */
            return
        }
        _initiativeRetry(reason)
    }

    private func _initiativeRetry(_ reason: RetryReason) {
        /// 执行主动重试，不再触发静默重试，取消正在等待的重试
        canSilentRetry = false
        if let lastItem = retryWorkItem {
            Self.logger.info("[RetryAction]: cancel last retry action", additionalData: debugInfo)
            lastItem.cancel()
            retryWorkItem = nil
        }

        let workItem = DispatchWorkItem { [weak self] in
            Self.logger.info("[RetryAction]: do initiative retry", additionalData: self?.debugInfo ?? [:])
            self?.lastRetryReason = reason
            self?.action?()
            self?.retryWorkItem = nil
        }
        self.retryWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }
}

extension BlockRetryAction.RetryReason {
    /// 是否属于静默重试场景
    var isSilentRetry: Bool {
        switch self {
        case .fetchEntityNetworkError, .fetchGuideInfoNetworkError, .loadMetaError, .loadPackageError, .loadingTimeout:
            return true
        case .netStateChange, .scrollToVisible, .switchToWorkspaceTab, .pageBecomeActive, .userClick:
            return false
        }
    }

    /// 用于埋点的 retry type
    var monitorRetryType: Int {
        if self == .userClick {
            return 3 /* user_retry */
        }
        if isSilentRetry {
            return 1 /* silent_retry */
        } else {
            return 2 /* active_retry */
        }
    }

    /// 埋点用
    var monitorSilentRetryFrom: Int? {
        switch self {
        case .fetchEntityNetworkError:
            return 1
        case .fetchGuideInfoNetworkError:
            return 2
        case .loadMetaError:
            return 3
        case .loadPackageError:
            return 4
        case .loadingTimeout:
            return 5
        default:
            return nil
        }
    }

    /// 埋点用
    var monitorActiveRetryFrom: Int? {
        switch self {
        case .netStateChange:
            return 1
        case .scrollToVisible:
            return 2
        case .switchToWorkspaceTab, .pageBecomeActive:
            return 3
        default:
            return nil
        }
    }
}

extension WPCardStateView.State {
    fileprivate var isLoadFailed: Bool {
        switch self {
        case .loadFail:
            return true
        default:
            return false
        }
    }

    fileprivate var retryDebugString: String {
        switch self {
        case .running:
            return "running"
        case .loading:
            return "loading"
        case .updateTip:
            return "updateTip"
        case .loadFail(let param):
            return "loadFail(\(param.name))"
        }
    }
}

extension OPError {
    /// 将部分 Block 错误转换为重试的触发条件
    func convertToBlockRetryReason() -> BlockRetryAction.RetryReason? {
        if monitorCode == OPBlockitMonitorCodeMountEntity.fetch_block_entity_network_error {
            return .fetchEntityNetworkError
        }

        if monitorCode == OPBlockitMonitorCodeMountLaunchGuideInfo.fetch_guide_info_network_error {
            return .fetchGuideInfoNetworkError
        }

        if monitorCode == OPBlockitMonitorCodeMountLaunchMeta.load_meta_fail {
            return .loadMetaError
        }

        if monitorCode == OPBlockitMonitorCodeMountLaunchPackage.load_package_fail {
            return .loadPackageError
        }

        return nil
    }
}

extension OPNetStatusHelper.OPNetStatus {
    /// 是否是离线状态
    fileprivate var isOffline: Bool {
        switch self {
        case .unknown, .unavailable:
            return true
        default:
            return false
        }
    }

    /// 是否是弱网
    fileprivate var isWeak: Bool {
        switch self {
        case .weak:
            return true
        default:
            return false
        }
    }

    /// 是否是普通网络
    fileprivate var isNormal: Bool {
        switch self {
        case .moderate, .excellent:
            return true
        default:
            return false
        }
    }
}
