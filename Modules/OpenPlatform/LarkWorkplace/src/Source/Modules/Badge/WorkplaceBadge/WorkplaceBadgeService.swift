//
//  WorkplaceBadgeService.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/5/30.
//

import Foundation
import RxSwift
import LarkContainer
import LarkRustClient
import RustPB
import AppContainer
import LarkOPInterface
import RxRelay
import LKCommonsLogging
import ECOProbe
import LarkWorkplaceModel

/// 工作台 Badge 服务。
///
/// 工作台全量的 Badge 在此处管理，业务需要的 badge 展示可以在此处获取监听。
/// 支持 hot reload，所有对外接口受 enable 管控。
protocol WorkplaceBadgeService: AnyObject {

    /// 重置 Badge service。
    ///
    /// 根据 enable 决定是否开启 badge 能力，并刷新 homeData 到缓存。
    /// 已经监听的业务不需要重新 subscribe。
    ///
    /// - Parameters:
    ///   - loadData: 初始化数据
    ///   - enable: 是否开启 badge 能力
    func reload(with loadData: BadgeLoadType.LoadData?, enable: Bool)

    /// 全量刷新 Badge 信息。
    ///
    /// 调用此方法会全量重新计算加载 badge 信息，同时会更新 Rust push。
    /// 业务不需要重新监听，重新加载完成后会对已监听业务发出一次通知。
    ///
    /// - Parameter loadData: 全量刷新数据
    func refresh(with loadData: BadgeLoadType.LoadData)

    /// 监听主 Tab badge 更新。
    ///
    /// 监听后会默认有一次当前的 badge 事件，与 BehaviorRelay 行为一样，相同 badge 数量会过滤，减少刷新。
    ///
    /// - Returns: Observable<Int>
    func subscribeTab() -> Observable<Int>

    /// 监听应用（appId + appAbility）badge 更新。
    ///
    /// 监听后会默认有一次当前的 badge 事件，与 BehaviorRelay 行为一样，相同 badge 数量会过滤，减少刷新。
    ///
    /// - Parameters:
    ///   - appId: 应用 appId。
    ///   - appAbility: 应用 ability
    /// - Returns: Observable<Int>
    func subscribeApp(for appId: String, appAbility: WPBadge.AppType) -> Observable<Int>

    /// 获取应用（appId + appAbility）badge 数字
    ///
    /// - Parameters:
    ///   - appId: 应用 appId。
    ///   - appAbility: 应用 ability
    /// - Returns: Int
    func getAppBadgeNumber(for appId: String, appAbility: WPBadge.AppType) -> Int
}

final class WorkplaceBadgeServiceImpl: WorkplaceBadgeService {
    static let logger = Logger.log(WorkplaceBadgeService.self)

    private typealias MonitorKey = AppCenterMonitorEvent.BadgeKey
    private typealias BadgeScene = AppCenterMonitorEvent.TemplateBadgeScene

    private let traceService: WPTraceService
    private let rustService: RustService
    private let pushCenter: PushNotificationCenter
    private let configService: WPConfigService

    private let badgeContainer = WorkplaceBadgeContainer()
    private let badgeRelay = BehaviorRelay(value: ())

    private let disposeBag = DisposeBag()
    private var subscribeBag = DisposeBag()

    private var enable: Bool = false

    init(
        traceService: WPTraceService,
        rustService: RustService,
        pushCenter: PushNotificationCenter,
        configService: WPConfigService
    ) {
        self.traceService = traceService
        self.rustService = rustService
        self.pushCenter = pushCenter
        self.configService = configService
    }

    /// 重置 Badge service。
    ///
    /// 根据 enable 决定是否开启 badge 能力，并刷新 loadData 到缓存。
    /// 已经监听的业务不需要重新 subscribe。
    ///
    /// - Parameters:
    ///   - loadData: 初始数据
    ///   - enable: 是否开启 badge 能力
    func reload(with loadData: BadgeLoadType.LoadData?, enable: Bool) {
        Self.logger.info("reload badge service", additionalData: [
            "enable": "\(enable)"
        ])
        self.enable = enable

        if enable {
            reloadEnable(with: loadData)
        } else {
            reloadDisable()
        }
    }

    /// 全量刷新 Badge 信息。
    ///
    /// 调用此方法会全量重新计算加载 badge 信息，同时会更新 Rust push。
    /// 业务不需要重新监听，重新加载完成后会对已监听业务发出一次通知。
    ///
    /// - Parameter loadData: 初始数据
    func refresh(with loadData: BadgeLoadType.LoadData) {
        Self.logger.info("refresh badge service", additionalData: [
            "enable": "\(enable)"
        ])
        guard enable else { return }
        refreshInternal(with: loadData)
    }

    /// 监听主 Tab badge 更新。
    ///
    /// 将事件映射成计算后的 tab badge。
    func subscribeTab() -> Observable<Int> {
        Self.logger.info("subscribe tab badgeNumber", additionalData: [
            "enable": "\(enable)"
        ])
        guard enable else { return .just(0) }

        return badgeRelay
            .map({ [weak self] in
                return self?.badgeContainer.tabBadgeNumber ?? 0
            })
            .distinctUntilChanged()
            .do(onNext: {
                Self.logger.info("tab badgeNumber did update", additionalData: ["tabBadgeNumber": "\($0)"])
            })
            .observeOn(MainScheduler.instance)
    }

    /// 监听应用（appId + appAbility）badge 更新。
    ///
    /// 将事件映射成计算后的应用 badge。
    func subscribeApp(for appId: String, appAbility: WPBadge.AppType) -> Observable<Int> {
        Self.logger.info("subscribe app badge number", additionalData: [
            "enable": "\(enable)",
            "appId": "\(appId)",
            "appAbility": "\(appAbility)"
        ])
        guard enable else { return .just(0) }

        return badgeRelay
            .map({ [weak self] in
                return self?.badgeContainer.badgeNumber(for: appId, appAbility: appAbility) ?? 0
            })
            .distinctUntilChanged()
            .do(onNext: {
                Self.logger.info("app badgeNumber did update", additionalData: [
                    "appBadgeNumber": "\($0)",
                    "appId": appId,
                    "appAbility": "\(appAbility)"
                ])
            })
            .observeOn(MainScheduler.instance)
    }

    /// 获取应用（appId + appAbility）badge 数字
    func getAppBadgeNumber(for appId: String, appAbility: WPBadge.AppType) -> Int {
        guard enable else { return 0 }
        return self.badgeContainer.badgeNumber(for: appId, appAbility: appAbility)
    }
}

extension WorkplaceBadgeServiceImpl {
    /// 重置 service，停止所有 badge 服务。
    private func reloadDisable() {
        let newOpenAppTabBadge = configService.fgValue(for: .newOpenAppTabBadge)
        Self.logger.info("reload disable", additionalData: [
            "newOpenAppTabBadge": "\(newOpenAppTabBadge)"
        ])
        // 取消所有监听
        subscribeBag = DisposeBag()
        // 清理所有 badge 缓存
        badgeContainer.reload(with: nil)
        // 通知一次刷新
        notifyBadgeUpdate()
        if !newOpenAppTabBadge {
            externalNotifyTabs(badgeNodes: [])
        }
    }

    /// 重置 service，恢复所有 badge 服务。
    private func reloadEnable(with loadData: BadgeLoadType.LoadData?) {
        // re subscribe event
        subscribeBag = DisposeBag()
        subscribeRustPush()
        refreshInternal(with: loadData)
    }

    /// 刷新 service
    private func refreshInternal(with loadData: BadgeLoadType.LoadData?) {
        let newOpenAppTabBadge = configService.fgValue(for: .newOpenAppTabBadge)
        let logData = [
            "newOpenAppTabBadge": "\(newOpenAppTabBadge)"
        ].merging(loadData?.wp.logInfo ?? [:]) { first, _ in
            return first
        }
        Self.logger.info("reload badge", additionalData: logData ?? [:])
        
        // 1. reload badge container
        badgeContainer.reload(with: loadData)

        guard let loadData = loadData else {
            Self.logger.info("reload badge for nil loadData")
            return
        }

        let trace = traceService.getTrace(for: .lowCode, with: loadData.portalId)

        // 2. flush badge to rust
        flushBadgeToRust(scene: loadData.scene, trace: trace)
        // 3. notify badge update
        notifyBadgeUpdate()
        // 4. noti other tabs
        let badgeNodes = badgeContainer.badges.values.getImmutableCopy()      /* [WPBadge] */
        let openBadgeNodes = badgeNodes.map({ $0.toOpenAppBadgeNode() })      /* [OpenAppBadgeNode] */
        if !newOpenAppTabBadge {
            externalNotifyTabs(badgeNodes: openBadgeNodes)
        }

        // 5. report monitor
        OPMonitor(AppCenterMonitorEvent.op_app_badge_pull_node)
            .tracing(trace)
            .addCategoryValue(MonitorKey.badge_brief.rawValue, badgeNodes.wp.badgeBrief)
            .addCategoryValue(MonitorKey.scene.rawValue, loadData.scene.rawValue)
            .setResultTypeSuccess()
            .flush()
    }

    private func subscribeRustPush() {
        pushCenter
            .observable(for: BadgeUpdateMessage.self, replay: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](message) in
                self?.onPushBadges(message)
            }).disposed(by: subscribeBag)
    }

    /// 通知 badge 更新
    private func notifyBadgeUpdate() {
        Self.logger.info("notify badge update")
        badgeRelay.accept(())
    }

    /// 将全量 badge 刷新到 rust，用于后续变更的监听。
    private func flushBadgeToRust(scene: BadgeScene, trace: OPTrace?) {
        let badgeNodes = badgeContainer.badges.values.getImmutableCopy()      /* [WPBadge] */
        let openBadgeNodes = badgeNodes.map({ $0.toOpenAppBadgeNode() })      /* [OpenAppBadgeNode] */

        Self.logger.info("flush badge to rust", additionalData: [
            "badgeNodes.count": "\(badgeNodes.count)",
            "badgeNodes": "\(badgeNodes.map({ ($0.appId, $0.appAbility) }))"
        ])

        let monitor = OPMonitor(AppCenterMonitorEvent.op_app_badge_save_node)
            .tracing(trace)
            .addCategoryValue(MonitorKey.badge_brief.rawValue, badgeNodes.wp.badgeBrief)
            .addCategoryValue(MonitorKey.scene.rawValue, scene.rawValue)

        var request = Openplatform_V1_SaveOpenAppBadgeNodesRequest()
        request.badgeNodes = openBadgeNodes
        request.needTriggerPush = true
        rustService
            .sendAsyncRequest(request)
            .subscribe(onNext: {
                monitor.setResultTypeSuccess().flush()
            }, onError: { error in
                monitor.setResultTypeFail().setError(error).flush()
            })
            .disposed(by: disposeBag)
    }

    /// badge push 处理。merge 推送的 badge 并触发通知。
    private func onPushBadges(_ message: BadgeUpdateMessage) {
        let noticeNodes = message.pushRequest.noticeNodes
        let newOpenAppTabBadge = configService.fgValue(for: .newOpenAppTabBadge)
        Self.logger.info("received badge push", additionalData: [
            "noticeNodes.count": "\(noticeNodes.count)",
            "noticeNodes": "\(noticeNodes.map({ $0.wp.logInfo }))",
            "newOpenAppTabBadge": "\(newOpenAppTabBadge)"
        ])

        let appBadgeNodes = noticeNodes.map({ $0.toAppBadgeNode() })
        OPMonitor(AppCenterMonitorEvent.op_app_badge_node_push)
            .tracing(traceService.root)
            .addCategoryValue(MonitorKey.badge_brief.rawValue, appBadgeNodes.wp.badgeBrief)
            .addCategoryValue(MonitorKey.sequence_id.rawValue, message.pushRequest.sid)
            .setResultTypeSuccess()
            .flush()

        // 1. merge badge
        badgeContainer.updateBadge(with: noticeNodes.map({ $0.toAppBadgeNode() }))
        // 2. notify badge update
        notifyBadgeUpdate()
        // 3. notify tabs update
        if !newOpenAppTabBadge {
            externalNotifyTabs(badgeNodes: noticeNodes)
        }
    }

    /// 通知其他主导航 Tab badge 更新（小程序/Web）。
    ///
    /// 来源:
    /// * rust push
    /// * reload
    private func externalNotifyTabs(badgeNodes: [Rust.OpenAppBadgeNode]) {
        let tabNodes = badgeNodes.map { $0.toTabAppBadge() }
        guard !tabNodes.isEmpty else { return }
        let userInfo = [OPBadge.Noti.BadgeDataKey(): tabNodes]
        NotificationCenter.default.post(name: OPBadge.Noti.BadgePush.notification, object: nil, userInfo: userInfo)
    }
}
