//
//  WPBadgeServiceContainer.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/6/1.
//

import Foundation
import LarkContainer
import RxSwift
import RxRelay
import RunloopTools
import LKCommonsLogging
import LarkSetting
import LarkTab

/// BadgeService 加载类型
enum BadgeLoadType: CustomStringConvertible {
    enum LoadData: CustomStringConvertible {
        typealias BadgeScene = AppCenterMonitorEvent.TemplateBadgeScene

        /// 模版化数据
        case template(TemplateData)
        /// web 数据
        case web(WebData)

        struct TemplateData {
            let portalId: String
            let scene: BadgeScene
            let components: [GroupComponent]

            init(portalId: String, scene: BadgeScene, components: [GroupComponent]) {
                self.portalId = portalId
                self.scene = scene
                self.components = components
            }
        }

        struct WebData {
            let portalId: String
            let scene: BadgeScene
            let badgeNodes: [Rust.OpenAppBadgeNode]

            init(portalId: String, scene: BadgeScene, badgeNodes: [Rust.OpenAppBadgeNode]) {
                self.portalId = portalId
                self.scene = scene
                self.badgeNodes = badgeNodes
            }
        }

        var portalId: String {
            switch self {
            case .template(let templateData):
                return templateData.portalId
            case .web(let webData):
                return webData.portalId
            }
        }

        var scene: BadgeScene {
            switch self {
            case .template(let templateData):
                return templateData.scene
            case .web(let webData):
                return webData.scene
            }
        }

        var description: String {
            switch self {
            case .template: return "template"
            case .web: return "web"
            }
        }
    }

    /// 不加载 badge
    case none
    /// 加载老版工作台
    case appCenter
    /// 加载模版化工作台
    case workplace(LoadData?)

    var description: String {
        switch self {
        case .none: return "none"
        case .appCenter: return "appCenter"
        case .workplace(let data): return "workplace(\(data?.description ?? "nil"))"
        }
    }
}

/// 工作台 BadgeService 容器。
///
/// 由于运行时可能在各种门户类型之间切换，不同门户类型的 badge 服务不同，
/// 统一在此处管理不同服务的启用和停用，同时提供给统一的 tabBadge。
final class WPBadgeServiceContainer {

    static let logger = Logger.log(WPBadgeServiceContainer.self)

    /// badge 配置
    private let config: BadgeConfig
    /// 老版工作台 badge
    private let appCenterBadgeService: AppCenterBadgeService
    /// 模版化工作台 badge
    private let workplaceBadgeService: WorkplaceBadgeService
    private let configService: WPConfigService
    private let prefetchServiceProvider: () -> WorkplacePrefetchService?
    private var prefetchService: WorkplacePrefetchService? {
        return prefetchServiceProvider()
    }

    /// 提供给 tab 的 badge
    private let tabBadge = BehaviorRelay<Int>(value: 0)
    private let disposeBag = DisposeBag()
    private var templateTabSubscribeBag = DisposeBag()

    init(
        config: BadgeConfig,
        appCenterBadgeService: AppCenterBadgeService,
        workplaceBadgeService: WorkplaceBadgeService,
        configService: WPConfigService,
        prefetchServiceProvider: @escaping () -> WorkplacePrefetchService?
    ) {
        self.config = config
        self.appCenterBadgeService = appCenterBadgeService
        self.workplaceBadgeService = workplaceBadgeService
        self.configService = configService
        self.prefetchServiceProvider = prefetchServiceProvider
    }

    /// 启动 badge 服务
    func start() {
        Self.logger.info("start badge service", additionalData: [
            "enableBadge": "\(config.enableBadge)",
            "enableTemplateBadge": "\(config.enableTemplateBadge)"
        ])
        // badge 总开关
        guard config.enableBadge else {
            reload(to: .none)
            return
        }
    }

    /// 监听 tab badge
    func subscribeTab() {
        Self.logger.info("subscribe tab badge", additionalData: [
            "enableBadge": "\(config.enableBadge)",
            "enableTemplateBadge": "\(config.enableTemplateBadge)"
        ])

        return tabBadge
            .subscribeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { badgeNumber in
                let tab = TabRegistry.resolve(.appCenter) as? WorkplaceTab
                Self.logger.info("tab badge changed", additionalData: [
                    "badgeNumber": "\(badgeNumber)",
                    "hasTab": "\(tab != nil)"
                ])
                tab?.badge?.accept(.number(badgeNumber))
            }).disposed(by: disposeBag)
    }

    /// 重置 badge
    func reload(to type: BadgeLoadType) {
        Self.logger.info("reload badge type", additionalData: [
            "enableBadge": "\(config.enableBadge)",
            "enableTemplateBadge": "\(config.enableTemplateBadge)",
            "loadType": "\(type)"
        ])
        guard config.enableBadge else { return }

        // 需要保证顺序，subscribe 要晚于 reload
        reloadService(for: type)
        reloadTabSubscribe(for: type)
    }

    /// 重置 badge service
    private func reloadService(for type: BadgeLoadType) {
        Self.logger.info("reload service", additionalData: ["loadType": "\(type)"])
        /// 新版 FG 打开的情况下，启用三种门户类型 Badge 服务隔离
        /// 新版 FG 关闭的情况下，只启用老的 badge
        /// 新版 FG 全量后直接删除 else
        if config.enableTemplateBadge {
            switch type {
            case .none:
                appCenterBadgeService.reload(enable: false)
                workplaceBadgeService.reload(with: nil, enable: false)
            case .appCenter:
                appCenterBadgeService.reload(enable: config.enableBadge)
                workplaceBadgeService.reload(with: nil, enable: false)
            case .workplace(let loadData):
                appCenterBadgeService.reload(enable: false)
                workplaceBadgeService.reload(with: loadData, enable: config.enableTemplateBadge)
            }
        } else {
            appCenterBadgeService.reload(enable: true)
            workplaceBadgeService.reload(with: nil, enable: false)
        }
    }

    /// 重置 tab badge 监听
    private func reloadTabSubscribe(for type: BadgeLoadType) {
        Self.logger.info("reload subscribe", additionalData: ["loadType": "\(type)"])
        /// 新版 FG 打开的情况下，Tab 监听启用三种门户类型 Badge 服务隔离
        /// 新版 FG 关闭的情况下，只 Tab 监听老的 Badge
        /// 新版 FG 全量后直接删除 else
        if config.enableTemplateBadge {
            switch type {
            case .none:
                templateTabSubscribeBag = DisposeBag()
                appCenterBadgeService.tabBadgeUpdateCallback = nil
                tabBadge.accept(0)
            case .appCenter:
                templateTabSubscribeBag = DisposeBag()
                appCenterBadgeService.tabBadgeUpdateCallback = { [weak self] badgeNumber in
                    Self.logger.info("workplace tab badge changed", additionalData: [
                        "badgeNumber": "\(badgeNumber)"
                    ])
                    self?.tabBadge.accept(badgeNumber)
                }
            case .workplace:
                templateTabSubscribeBag = DisposeBag()
                appCenterBadgeService.tabBadgeUpdateCallback = nil
                workplaceBadgeService
                    .subscribeTab()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self]badgeNumber in
                        Self.logger.info("template tab badge changed", additionalData: [
                            "badgeNumber": "\(badgeNumber)"
                        ])
                        self?.tabBadge.accept(badgeNumber)
                    }).disposed(by: templateTabSubscribeBag)
            }
        } else {
            templateTabSubscribeBag = DisposeBag()
            appCenterBadgeService.tabBadgeUpdateCallback = { [weak self] badgeNumber in
                Self.logger.info("workplace tab badge changed", additionalData: [
                    "badgeNumber": "\(badgeNumber)"
                ])
                self?.tabBadge.accept(badgeNumber)
            }
        }
    }
}
