//
//  AppCenterBadgeService.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2020/12/21.
//

import Foundation
import LKCommonsLogging
import RustPB
import LarkRustClient
import RxRelay
import RxSwift
import LarkOPInterface
import LarkContainer
import AppContainer
import LarkWorkplaceModel

/// Badge 数据源
enum WorkplaceBadgeSource: Int {
    case localCache = 1
    case remoteByService = 2
    case workplaceHomeCache = 3
    case workplaceHomeRemote = 4
}

/// 老版 BadgeService
protocol AppCenterBadgeService: AnyObject {

    /// tab 更新回调
    var tabBadgeUpdateCallback: ((_ workplaceBadgeNum: Int) -> Void)? { get set }

    /// 重置老版 badge，如果 enable 为 false 则关闭老版 badge 所有功能
    func reload(enable: Bool)

    /// 更新 badge 数据，相当于 WorkplaceBadgeService 的 refresh 操作
    func updateBadgeInfo(badgeMap: WorkPlaceBadgeInfo, source: WorkplaceBadgeSource)

    /// 获取 badge
    func getBadge(badgeKey: WorkPlaceBadgeKey) -> Int?

    /// 获取 badge node
    func getBadgeNode(badgeKey: WorkPlaceBadgeKey) -> (Bool, WPBadge?)?
}

/// 老版工作台 badge service
///
/// 支持 hot reload，所有对外接口受 enable 管控。
final class AppCenterBadgeServiceImpl: AppCenterBadgeService {
    static let logger = Logger.log(AppCenterBadgeService.self)

    /// 所有的Badge信息
    private var allBadgeInfo: WorkPlaceBadgeInfo = WorkPlaceBadgeInfo()

    /// badge更新的lock
    private var badgeUpdateLock: NSRecursiveLock = NSRecursiveLock()

    /// 是否从工作台刷新过数据标记
    private var didRecivedWorkPlaceBadge = false

    /// tabBadge update callback
    var tabBadgeUpdateCallback: ((_ workplaceBadgeNum: Int) -> Void)?

    private var disposeBag = DisposeBag()

    /// 相关监听的生命周期，reload 时会重置。
    private var subscribeBag = DisposeBag()
    /// 是否开启老版工作台 badge，由外部传入。
    private var enable: Bool = false

    let rustService: RustService
    let dataManager: AppCenterDataManager
    let pushCenter: PushNotificationCenter

    init(rustService: RustService, dataManager: AppCenterDataManager, pushCenter: PushNotificationCenter) {
        self.rustService = rustService
        self.dataManager = dataManager
        self.pushCenter = pushCenter
    }

// MARK: - public

    /// 重新加载 badge service
    /// - Parameter enable: 是否开启，设置后 service 整体生效。
    func reload(enable: Bool) {
        Self.logger.info("reload workplace badge service", additionalData: [
            "enable": "\(enable)"
        ])
        self.enable = enable
        if enable {
            reloadEnable()
        } else {
            reloadDisable()
        }
    }

    /// update 数据
    func updateBadgeInfo(badgeMap: WorkPlaceBadgeInfo, source: WorkplaceBadgeSource) {
        Self.logger.info("update badge info", additionalData: [
            "enable": "\(enable)",
            "badgeMap": "\(badgeMap.debugDescription)",
            "source": "\(source)"
        ])

        guard enable else { return }

        var isBadgeNew = false
        actionWithLock {
            isBadgeNew = allBadgeInfo.isOldThan(otherBadgeInfo: badgeMap)
        }
        guard isBadgeNew else {
            Self.logger.info("update badge info \(badgeMap.debugDescription) from \(source) is not new \(isBadgeNew)")
            return
        }
        didRecivedWorkPlaceBadge = (source == .workplaceHomeCache || source == .workplaceHomeRemote)
        actionWithLock {
            allBadgeInfo = badgeMap
        }
        flushBadgeToRust(needPush: true)
        notifyBadgeUpdate()
        reportBadgePullAndSave(badgeMap: badgeMap, source: source)
        notifyBadgeUpdateForTabs()
    }

    /// get badge num
    func getBadge(badgeKey: WorkPlaceBadgeKey) -> Int? {
        Self.logger.info("get badge", additionalData: [
            "enable": "\(enable)",
            "badgeKey": "\(badgeKey.map({ $0.key() }))"
        ])

        guard enable else { return nil }

        var badgeCount: Int?
        actionWithLock {
            for key in badgeKey {
                if let badgeInfo = allBadgeInfo.badgeForApp(appID: key.appId) {
                    for badge in badgeInfo.badgeList where badge.appAbility == key.ability && badge.needShow {
                        badgeCount = (badgeCount ?? 0) + Int(badge.badgeNum)
                    }
                }
            }
        }
        if let tempBadgeCount = badgeCount {
            Self.logger.info("getBadge by key \(badgeKey) result badgeCount \(tempBadgeCount)")
        }
        return badgeCount
    }

    /// 查询BadgeNode，用于数据上报
    func getBadgeNode(badgeKey: WorkPlaceBadgeKey) -> (Bool, WPBadge?)? {
        Self.logger.info("get badge", additionalData: [
            "enable": "\(enable)",
            "badgeKey": "\(badgeKey.map({ $0.key() }))"
        ])

        guard enable else { return nil }

        var node: WPBadge?
        actionWithLock {
            for key in badgeKey {
                if let badgeInfo = allBadgeInfo.badgeForApp(appID: key.appId) {
                    for badge in badgeInfo.badgeList where badge.appAbility == key.ability && badge.needShow {
                        node = badge
                        break
                    }
                }
            }
        }
        return (enable, node)
    }
}

// MARK: - reload
extension AppCenterBadgeServiceImpl {
    private func reloadEnable() {
        subscribeBag = DisposeBag()
        subscribeEvent()
        loadRemoteData()
    }

    private func reloadDisable() {
        subscribeBag = DisposeBag()
        actionWithLock { allBadgeInfo = WorkPlaceBadgeInfo(badgeMap: [:], workplaceAppMap: [:]) }
    }

    /// 加载网络数据
    private func loadRemoteData() {
        dataManager.fetchItemInfoWith(needCache: false) { (_, _) in
            Self.logger.info("load badge from remote success")
        } failure: { (error) in
            Self.logger.error("load badge from remote error", error: error)
        }
    }

    /// Action with Lock
    private func actionWithLock(action: (() -> Void)) {
        defer {
            badgeUpdateLock.unlock()
        }
        badgeUpdateLock.lock()
        action()
    }

    /// merge 单条数据
    private func mergeBadgeItem(badgeItem: AppBadgeItemInfo) {
        Self.logger.info("merge badge item \(badgeItem.debugDescription)")
        actionWithLock {
            if let oldBadgeItem = allBadgeInfo.badgeForApp(appID: badgeItem.appID) {
                var tempBadgeNodes: [WPBadge] = []
                for badgeNode in badgeItem.badgeList {
                    if let oldNodeIndex = oldBadgeItem.badgeList.firstIndex(of: badgeNode) {
                        let oldNode = oldBadgeItem.badgeList[oldNodeIndex]
                        tempBadgeNodes.append(oldNode.version > badgeNode.version ? oldNode : badgeNode)
                    } else {
                        /// merge 一个新的应用类型的信息
                        tempBadgeNodes.append(badgeNode)
                        Self.logger.info("merge badge item \(badgeItem.debugDescription) item type not in old badge list")
                    }
                }
                let oldExtraNodes = oldBadgeItem.badgeList.filter { (node) -> Bool in
                    return !tempBadgeNodes.contains(node)
                }
                tempBadgeNodes += oldExtraNodes
                let itemInfo = AppBadgeItemInfo(
                    appID: badgeItem.appID,
                    badgeList: tempBadgeNodes,
                    workplaceDisplayAbility: oldBadgeItem.workplaceDisplayAbility
                )
                /// 更新合并之后的数据
                allBadgeInfo.updateBadge(appID: badgeItem.appID, badge: itemInfo)
            } else {
                allBadgeInfo.updateBadge(appID: badgeItem.appID, badge: badgeItem)
                Self.logger.info("merge badge item \(badgeItem.debugDescription) appid not in old badge list")
            }
        }
        notifyBadgeUpdate()
    }

    /// flush To Rust Badge System
    private func flushBadgeToRust(needPush: Bool) {
        Self.logger.info("start flush badge to rust", additionalData: ["needPush": "\(needPush)"])

        var badgeList: [WPBadge] = []
        actionWithLock {
            Self.logger.info("fflush all badge map info \(allBadgeInfo.debugDescription)")
            for badgeItem in allBadgeInfo.badgeMap.values {
                for badgeNode in badgeItem.badgeList {
                    badgeList.append(badgeNode)
                }
            }
        }
        let openAppBadgeList = badgeList.map { (node) -> Openplatform_V1_OpenAppBadgeNode in
            return node.toOpenAppBadgeNode()
        }
        var request = Openplatform_V1_SaveOpenAppBadgeNodesRequest()
        request.badgeNodes = openAppBadgeList
        request.needTriggerPush = needPush
        rustService
            .sendAsyncRequest(request)
            .subscribe()
            .disposed(by: disposeBag)
    }

    /// Notify Badge Update
    private func notifyBadgeUpdate() {
        Self.logger.info("notify badge update start ")
        var badgeNum: Int?
        /// 只有badge fg打开的时候才计算badge数量
        actionWithLock {
            /// 计算工作台上面在展示的应用对应的badge数
            Self.logger.info("sumOfWorkplaceBadges start ")
            for badge in allBadgeInfo.badgeMap.values {
                for badgeNode in badge.badgeList
                where badgeNode.countAble() &&
                      /// 判断应用是否在badge列表中
                      (allBadgeInfo.workplaceAppMap[badgeNode.workplaceBadgeKey()] != nil) {
                    badgeNum = (badgeNum ?? 0) + Int(badgeNode.badgeNum)
                }
            }
        }
        Self.logger.info("notify badge update result badgeNum \(String(describing: badgeNum))")
        tabBadgeUpdateCallback?(badgeNum ?? 0)

        /// 通知整个界面刷新
        NotificationCenter.default.post(name: WorkPlaceBadge.Noti.badgeUpdate.name, object: nil)
    }

    /// 通知其他Tab中的主导航小程序和H5刷新
    private func notifyBadgeUpdateForTabs() {
        var tabNodes: [OPBadge.GadgetBadgeNode]?
        actionWithLock {
            tabNodes = allBadgeInfo.toReportBadgeList()
        }
        if let tabNodeList = tabNodes, !tabNodeList.isEmpty {
            var resultNodes: [OPBadge.GadgetBadgeNode] = []
            for tabNode in tabNodeList {
                resultNodes.append(tabNode)
            }
            var output: [String] = []
            for tabNode in resultNodes {
                output.append("[Node] appId:\(tabNode.appId) \(tabNode.num) \(tabNode.show) \(tabNode.type)")
            }
            Self.logger.info("notify badge node for tabs:\n \(output.joined(separator: "\n"))")
            let userInfo = [OPBadge.Noti.BadgeDataKey(): resultNodes]
            NotificationCenter.default.post(
                name: OPBadge.Noti.BadgePush.notification, object: nil, userInfo: userInfo
            )
        }
    }
}

// MARK: - subscribe
extension AppCenterBadgeServiceImpl {
    private func subscribeEvent() {
        subscribeRustBadgePush()
        observeWorkplaceUpdateNotification()
        subscribeForegroundNotification()
    }

    private func subscribeRustBadgePush() {
        pushCenter
            .observable(for: BadgeUpdateMessage.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](message) in
                guard let `self` = self else { return }
                self.onRustBadgePush(message: message)
            }).disposed(by: subscribeBag)
    }

    /// observe Workplace Update Notification
    private func observeWorkplaceUpdateNotification() {
        pushCenter.observable(for: WorkplacePushMessage.self)
            /// 让工作台这边的请求先执行，如果已经刷新了数据，考虑下不要再次刷新
            .delay(.seconds(30), scheduler: MainScheduler.instance)
            .subscribe( onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                /// 如果工作台这边刷新过数据，这里就不要重复请求了
                if !self.didRecivedWorkPlaceBadge {
                    self.loadRemoteData()
                }
            }).disposed(by: subscribeBag)
    }

    /// 应用进入前台监听
    private func subscribeForegroundNotification() {
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self]_ in
                self?.loadRemoteData()
            }).disposed(by: subscribeBag)
    }

    private func onRustBadgePush(message: BadgeUpdateMessage) {
        for pushNode in message.pushRequest.noticeNodes {
            let appNode = pushNode.toAppBadgeNode()
            Self.logger.info("received badge push node \(appNode.debugDescription)")
            let itemInfo = AppBadgeItemInfo(
                appID: appNode.appId, badgeList: [appNode], workplaceDisplayAbility: appNode.appAbility
            )
            mergeBadgeItem(badgeItem: itemInfo)
        }
        reportBadgePush(nodes: message.pushRequest.noticeNodes, sid: message.pushRequest.sid)
        // 其他Tab的监听
        repostNotiToOtherTabs(message: message.pushRequest)
    }
}

// MARK: - external notify
extension AppCenterBadgeServiceImpl {
    private func repostNotiToOtherTabs(message: Rust.PushOpenAppBadgeNodesRequest) {
        let tabNodes = message.noticeNodes.map { $0.toTabAppBadge() }
        guard !tabNodes.isEmpty else { return }
        let userInfo = [OPBadge.Noti.BadgeDataKey(): tabNodes]
        NotificationCenter.default.post(
            name: OPBadge.Noti.BadgePush.notification, object: nil, userInfo: userInfo
        )
    }
}

// MARK: - report monitor
extension AppCenterBadgeServiceImpl {
    private func reportBadgePush(nodes: [Openplatform_V1_OpenAppBadgeNode], sid: String) {
        Self.logger.info("report badge received push")
        let scene = AppCenterMonitorEvent.TemplateBadgeScene.fromRustLocal
        do {

            let jsonData = try JSONEncoder().encode(nodes.map({ TemplateBadgeNodeBrief(from: $0) }))
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                OPMonitor(AppCenterMonitorEvent.op_app_badge_node_push)
                    .addCategoryValue(AppCenterMonitorEvent.BadgeKey.badge_brief.rawValue, jsonString)
                    .addCategoryValue(AppCenterMonitorEvent.BadgeKey.scene.rawValue, scene.rawValue)
                    .addCategoryValue(AppCenterMonitorEvent.BadgeKey.sequence_id.rawValue, sid)
                    .setResultTypeSuccess()
                    .flush()
            }
        } catch {
            Self.logger.error("reportBadgePull error \(error.localizedDescription)")
            OPMonitor(AppCenterMonitorEvent.op_app_badge_node_push)
                .addCategoryValue(AppCenterMonitorEvent.BadgeKey.scene.rawValue, scene)
                .addCategoryValue(AppCenterMonitorEvent.BadgeKey.sequence_id.rawValue, sid)
                .setResultTypeFail()
                .flush()
        }
    }

    /// report
    private func reportBadgePullAndSave(badgeMap: WorkPlaceBadgeInfo, source: WorkplaceBadgeSource) {
        Self.logger.info("report badge map did save ")
        var scene = 0
        switch source {
        case .remoteByService, .workplaceHomeRemote:
            scene = 4
        case .workplaceHomeCache:
            scene = 3
        default:
            scene = source.rawValue
        }
        let fromWorkplace = 1
        do {
            let jsonData = try JSONEncoder().encode(badgeMap.toBadgeNodeBrief())
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                OPMonitor(AppCenterMonitorEvent.op_app_badge_pull_node)
                    .addCategoryValue(AppCenterMonitorEvent.BadgeKey.badge_brief.rawValue, jsonString)
                    .addCategoryValue(AppCenterMonitorEvent.BadgeKey.scene.rawValue, scene)
                    .setResultTypeSuccess()
                    .flush()
                OPMonitor(AppCenterMonitorEvent.op_app_badge_save_node)
                    .addCategoryValue(AppCenterMonitorEvent.BadgeKey.badge_brief.rawValue, jsonString)
                    .addCategoryValue(AppCenterMonitorEvent.BadgeKey.scene.rawValue, fromWorkplace)
                    .setResultTypeSuccess()
                    .flush()
            }
        } catch {
            Self.logger.error("reportBadgePull error \(error.localizedDescription)")
            OPMonitor(AppCenterMonitorEvent.op_app_badge_pull_node)
                .addCategoryValue(AppCenterMonitorEvent.BadgeKey.scene.rawValue, scene)
                .setResultTypeFail()
                .flush()
            OPMonitor(AppCenterMonitorEvent.op_app_badge_save_node)
                .addCategoryValue(AppCenterMonitorEvent.BadgeKey.scene.rawValue, fromWorkplace)
                .setResultTypeFail()
                .flush()
        }
    }
}
