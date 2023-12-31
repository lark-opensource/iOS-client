//
//  TemporaryTabManager.swift
//  LarkNavigation
//
//  Created by yaoqihao on 2023/6/7.
//

import Foundation
import LarkContainer
import LarkLocalizations
import LarkTab
import LarkExtensions
import EENavigator
import ThreadSafeDataStructure
import AnimatedTabBar
import RxSwift
import RxCocoa
import RustPB
import LarkQuickLaunchInterface
import LarkUIKit
import LarkSetting
import SuiteAppConfig
import LKCommonsLogging

public class TemporaryTabManager: UserResolverWrapper {
    static let maxCount = 200
    static let maxCache = 5

    static let logger = Logger.log(TemporaryTabManager.self, category: "Temporary.TemporaryTabManager")

    public weak var delegate: TemporaryTabDelegate?

    private var publishSubject = PublishSubject<[TabCandidate]>()
    private var observable: Observable<[TabCandidate]> { publishSubject.asObservable() }

    @ScopedInjectedLazy private var navigationAPI: NavigationAPI?

    public var isTemporaryEnabled: Bool {
        return !AppConfigManager.shared.leanModeIsOn && Display.pad
    }

    public var tabs: [TabCandidate] {
        let tabs = tabArray.getImmutableCopy()
        return tabs
    }

    public var tabContainables: [TabContainable] {
        let tabContainables = tabContainableArray.getImmutableCopy()
        return tabContainables
    }

    private var tabCache: SafeLRUDictionary<String, TabContainable> = SafeLRUDictionary<String, TabContainable>(capacity: TemporaryTabManager.maxCache,
                                                                                                                synchronization: .readWriteLock)

    private var screenshotMap: SafeDictionary<String, UIImage> = [:] + .readWriteLock

    private var tabArray: SafeArray<TabCandidate> = [] + .readWriteLock
    private var tabContainableArray: SafeArray<TabContainable> = [] + .readWriteLock

    private var disposeBag = DisposeBag()

    public let userResolver: UserResolver

    public init(resolver: UserResolver) {
        self.userResolver = resolver

        guard isTemporaryEnabled else {
            Self.logger.info("isTemporaryEnabled false")
            return
        }
        self.getTemporaryRecords(startIndex: 0, pageSize: TemporaryTabManager.maxCount)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (infos, _) in
                Self.logger.info("tabs count: \(infos.count)")
                self?.tabArray.append(contentsOf: infos)
                self?.delegate?.updateTabs()
            }).disposed(by: self.disposeBag)
    }

    private func add(vc: TabContainable, isShow: Bool) {
        Self.logger.info("Add vc info tabID: \(vc.tabID) tabType: \(vc.tabBizType.rawValue)")

        self.addTemporaryRecord(vc: vc)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak vc] id in
                guard let `self` = self, let vc = vc else { return }
                Self.logger.info("Add vc info id: \(id), success")

                let oldID = vc.tabContainableIdentifier
                vc.tabContainableIdentifier = id
                self.updateData(vc: vc, oldID: oldID, isShow: isShow)
            }, onError: { [weak self] _ in
                Self.logger.info("Add vc info tabID: \(vc.tabID), error")
                self?.delegate?.updateTabs()
            }).disposed(by: self.disposeBag)
    }

    private func update(vc: TabContainable, isShow: Bool = false) {
        let shouldUpdateTemporary = self.delegate?.shouldUpdateTemporary(vc.transferToTabCandidate(),
                                                                         oldID: vc.tabContainableIdentifier) ?? true

        Self.logger.info("Update vc info tabID: \(vc.tabID) tabType: \(vc.tabBizType.rawValue), shouldUpdateTemporary: \(shouldUpdateTemporary)")

        guard tabs.contains(where: {
            $0.uniqueId == vc.tabContainableIdentifier
        }) || !shouldUpdateTemporary else {
            Self.logger.info("Should not update vc info tabID: \(vc.tabID)")
            add(vc: vc, isShow: isShow)
            return
        }

        Self.logger.info("Should update vc info, id: \(vc.tabContainableIdentifier) tabID: \(vc.tabID)")

        self.updateNavigationInfo(vc: vc)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak vc] in
                guard let `self` = self, let vc = vc else { return }
                Self.logger.info("Update vc info, id: \(vc.tabContainableIdentifier) tabID: \(vc.tabID), success")

                self.updateData(vc: vc, oldID: vc.tabContainableIdentifier, isShow: isShow)
            }, onError: { [weak self] _ in
                Self.logger.info("Update vc info, id: \(vc.tabContainableIdentifier) tabID: \(vc.tabID), error")
                if isShow {
                    Self.logger.info("Show Tab id: \(vc.tabContainableIdentifier)")
                    self?.delegate?.showTab(vc)
                } else {
                    Self.logger.info("Update Tab id: \(vc.tabContainableIdentifier)")
                    self?.delegate?.updateTabs()
                }
            }).disposed(by: self.disposeBag)
    }

    private func updateData(vc: TabContainable, oldID: String, isShow: Bool) {
        let candidate = vc.transferToTabCandidate()
        let shouldUpdateTemporary = self.delegate?.shouldUpdateTemporary(candidate,
                                                                         oldID: oldID) ?? true

        Self.logger.info("Update Data info tabID: \(vc.tabID) tabType: \(vc.tabBizType.rawValue), oldID: \(oldID)")
        Self.logger.info("shouldUpdateTemporary: \(shouldUpdateTemporary)")

        guard shouldUpdateTemporary else {
            self.navigationAPI?.deleteTemporaryRecord(uniqueIds: [vc.tabContainableIdentifier])
                .subscribe().disposed(by: self.disposeBag)
            if isShow {
                Self.logger.info("Show Tab id: \(vc.tabContainableIdentifier)")
                self.delegate?.showTab(vc)
            } else {
                Self.logger.info("Update Tab id: \(vc.tabContainableIdentifier)")
                self.delegate?.updateTabs()
            }
            return
        }

        if !vc.forceRefresh {
            Self.logger.info("Cache Tab id: \(vc.tabContainableIdentifier)")
            self.tabCache.setValue(vc, for: candidate.uniqueId)
        }

        if let index = self.tabs.firstIndex(where: {
            $0.uniqueId == candidate.uniqueId || $0.uniqueId == oldID
        }) {
            Self.logger.info("Update Tab Array id: \(candidate.uniqueId), index: \(index)")
            self.tabArray[index] = candidate
        } else {
            Self.logger.info("Insert Tab Array id: \(candidate.uniqueId)")
            self.tabArray.insert(candidate, at: 0)
            if self.tabs.count > Self.maxCount {
                Self.logger.info("Array exceeds limit")
                let tabArray = self.tabs[0...(Self.maxCount - 1)]
                self.tabArray.removeAll()
                self.tabArray.append(contentsOf: tabArray)
            }
        }
        if let index = self.tabContainables.firstIndex(where: {
            let tabCandidate = $0.transferToTabCandidate()
            return tabCandidate.uniqueId == candidate.uniqueId || tabCandidate.uniqueId == oldID
        }) {
            Self.logger.info("TabContainables Update Tab Array id: \(candidate.uniqueId), index: \(index)")
            self.tabContainableArray[index] = vc
        } else {
            Self.logger.info("TabContainables Insert Tab Array id: \(candidate.uniqueId)")
            self.tabContainableArray.insert(vc, at: 0)
            if self.tabContainables.count > Self.maxCount {
                Self.logger.info("TabContainables Array exceeds limit")
                let tabContainableArray = self.tabContainables[0...(Self.maxCount - 1)]
                self.tabContainableArray.removeAll()
                self.tabContainableArray.append(contentsOf: tabContainableArray)
            }
        }
        if isShow {
            Self.logger.info("Show Tab id: \(vc.tabContainableIdentifier)")
            self.delegate?.showTab(vc)
        } else {
            Self.logger.info("Update Tab id: \(vc.tabContainableIdentifier)")
            self.delegate?.updateTabs()
        }

    }

    private func screenshotTab(_ tab: TabContainable) {
        let image = tab.view.lu.screenshot()
        screenshotMap[tab.tabContainableIdentifier] = image
    }
}

// MARK: - Record Recent Pages

extension TemporaryTabManager {

    private func addTemporaryRecord(vc: TabContainable) -> Observable<String> {
        guard let navigationAPI = navigationAPI else { return .just("") }
        let appInfo = vc.transferToNavigationAppInfo()

        return navigationAPI.createTemporaryRecord(appInfo: appInfo)
    }

    private func deleteTemporaryRecord(ids: [String]) -> Observable<Void> {
        guard let navigationAPI = navigationAPI else { return .just(()) }

        Self.logger.info("Delete Temporary Record id：\(ids)")
        return navigationAPI.deleteTemporaryRecord(uniqueIds: ids)
    }

    /// 获取全部 “最近打开” 记录
    private func getTemporaryRecords(startIndex: Int, pageSize: Int) -> Observable<([TabCandidate], Bool)> {
        guard let navigationAPI = navigationAPI else { return .just(([], false)) }

        Self.logger.info("Get Temporary Record startIndex：\(startIndex) pageSize：\(pageSize)")

        return navigationAPI.getTemporaryRecord(cursor: startIndex, count: pageSize).map({ (resp: Settings_V1_GetTemporaryRecordResponse) -> ([TabCandidate], Bool) in
            let tabCandidates: [TabCandidate] = resp.appInfos.map({
                return $0.transferToTabContainable()
            })
            return (tabCandidates, resp.hasMore_p)
        })
    }

    private func updateNavigationInfo(vc: TabContainable) -> Observable<Void> {
        guard let navigationAPI = navigationAPI else { return .just(()) }

        Self.logger.info("Update Temporary Record id：\(vc.tabContainableIdentifier)")

        let info = vc.transferToNavigationAppInfo()
        return navigationAPI.updateNavigationInfos(appInfos: [info])
    }

    /// 移除 “最近打开” 记录
    private func removeTemporaryRecords(byID ids: [String]) {
        guard let navigationAPI = navigationAPI else { return }

        Self.logger.info("Remove Temporary Record id：\(ids)")

        navigationAPI.deleteTemporaryRecord(uniqueIds: ids)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                var removeTabs: [TabCandidate] = []
                for id in ids {
                    self?.screenshotMap.removeValue(forKey: id)
                    _ = self?.tabCache.removeValue(forKey: id)

                    if let value = self?.tabArray.getImmutableCopy().enumerated().first(where: { (_, tab) in
                        tab.uniqueId == id
                    }) {
                        self?.tabArray.remove(at: value.offset)
                        removeTabs.append(value.element)
                    }
                    Self.logger.info("Remove Temporary Record id：\(id), success")
                }

                self?.publishSubject.onNext(removeTabs)

                /// TODO: 等接口
                self?.delegate?.removeTab(ids)
                self?.delegate?.updateTabs()
            }, onError: { [weak self] (_) in
                Self.logger.info("Remove Temporary Record id：\(ids), error")
                self?.delegate?.updateTabs()
            })
            .disposed(by: self.disposeBag)
    }
}

extension TemporaryTabManager: TemporaryTabService {

    /// 设置代理方法
    /// - Parameter delegate:
    public func set(delegate: TemporaryTabDelegate) {
        guard isTemporaryEnabled else { return }
        self.delegate = delegate
        Self.logger.info("Set Temporary Delegate")
    }


    /// 在导航区展示Tab，不论是在Main和Quick还是 Temporary
    ///
    /// - Parameter vc: TabContainable
    /// 主导航会持有传入vc，并且将其从原先的parent移除
    public func showTab(_ vc: TabContainable) {
        guard isTemporaryEnabled else { return }
        let oldID = vc.tabContainableIdentifier
        let candidate = vc.transferToTabCandidate()
        Self.logger.info("ShowTab Temporary VC id: \(oldID)")

        guard self.delegate?.shouldUpdateTemporary(candidate, oldID: oldID) ?? true else {
            Self.logger.info("Not update, ShowTab Temporary VC id: \(oldID)")
            self.delegate?.showTab(vc)
            return 
        }
        update(vc: vc, isShow: true)
    }

    public func showTab(url: String, context: [String: Any]) {
        guard isTemporaryEnabled, let url = URL(string: url) else { return }

        var newContext = context
        let launcherFrom = context[NavigationKeys.launcherFrom]
        newContext[NavigationKeys.launcherFrom] = launcherFrom ?? NavigationKeys.LauncherFrom.temporary
        self.userResolver.navigator.getResource(url, context: newContext) { [weak self] res in
            if let vc = res as? TabContainable {
                self?.showTab(vc)
            }
        }
    }

    /// 更新导航区Tab
    ///
    /// - Parameter vc:TabContainable
    /// 主导航会持有传入vc，使用时会将其从原先的parent移除
    public func updateTab(_ vc: TabContainable) {
        guard isTemporaryEnabled else { return }
        Self.logger.info("Update Temporary VC id: \(vc.tabContainableIdentifier)")
        update(vc: vc)
    }

    /// 通过id和Context获取vc
    ///
    /// - Parameters:
    ///   - id: TabContainable id
    ///   - context:
    /// - Returns: TabContainable
    public func getTab(id: String, context: [String: Any]) -> TabContainable? {
        guard isTemporaryEnabled else { return nil }
        Self.logger.info("Get Temporary VC id: \(id), context: \(context)")

        if let tab = tabCache.getValue(for: id), !tab.forceRefresh {
            Self.logger.info("Return Temporary VC Cache id: \(id)")
            return tab
        } else if let item = self.tabArray.first(where: {
            $0.uniqueId == id
        }), let url = URL(string: item.url) {
            var temporaryTab: TabContainable?
            var newContext = context
            newContext[NavigationKeys.uniqueid] = id
            let launcherFrom = context[NavigationKeys.launcherFrom]
            newContext[NavigationKeys.launcherFrom] = launcherFrom ?? NavigationKeys.LauncherFrom.temporary
            Self.logger.info("Return Temporary VC Cache id: \(id), new context: \(newContext)")

            self.userResolver.navigator.getResource(url, context: newContext) { [weak self] res in
                if let vc = res as? TabContainable {
                    Self.logger.info("Navigator Get Resource id: \(id)")

                    vc.tabContainableIdentifier = id
                    self?.updateTab(vc)
                    temporaryTab = vc
                }
            }
            return temporaryTab
        }
        return nil
    }

    /// 根据tabCandidate异步获取 vc
    ///
    /// - Parameters:
    ///   - tabCandidate:
    ///   - completion:
    public func getTab(_ tabCandidate: TabCandidate, context: [String: Any], with completion: ((TabContainable?) -> Void)?) {
        Self.logger.info("Get Temporary VC By TabCandidate id: \(tabCandidate.uniqueId)")

        guard isTemporaryEnabled else {
            completion?(nil)
            return
        }

        if let tab = tabCache.getValue(for: tabCandidate.uniqueId) {
            Self.logger.info("Get Temporary VC Cache By TabCandidate id: \(tabCandidate.uniqueId)")
            completion?(tab)
        } else if let url = URL(string: tabCandidate.url) {
            var newContext = context
            let launcherFrom = context[NavigationKeys.launcherFrom]
            newContext[NavigationKeys.launcherFrom] = launcherFrom ?? NavigationKeys.LauncherFrom.temporary
            newContext[NavigationKeys.uniqueid] = tabCandidate.uniqueId
            self.userResolver.navigator.getResource(url, context: newContext) { res in
                if let vc = res as? TabContainable {
                    Self.logger.info("Navigator Get Resource id: \(tabCandidate.uniqueId)")
                    vc.tabContainableIdentifier = tabCandidate.uniqueId
                    completion?(vc)
                }
            }
        }
    }

    /// 移除对应Tab
    ///
    /// - Parameter id:
    public func removeTab(ids: [String]) {
        Self.logger.info("Remove Temporary VC ids: \(ids)")

        guard isTemporaryEnabled else { return }
        removeTemporaryRecords(byID: ids)
    }

    /// 移除对应Tab
    ///
    /// - Parameter id:
    public func removeTab(id: String) {
        Self.logger.info("Remove Temporary VC ids: \(id)")

        guard isTemporaryEnabled else { return }
        removeTemporaryRecords(byID: [id])
    }

    public func removeTabCache(id: String) {
        Self.logger.info("Remove Temporary VC Cache id: \(id)")

        self.screenshotMap.removeValue(forKey: id)
        _ = self.tabCache.removeValue(forKey: id)
    }

    /// 对全部Temporary的tabs进行排序
    /// - Parameter tabs:
    public func modifyTabs(_ tabs: [TabCandidate]) {
        Self.logger.info("Modify Temporary VC")

        guard isTemporaryEnabled else { return }
        let appInfos = tabs.map { (item) -> RustPB.Basic_V1_NavigationAppInfo in
            return item.transferToNavigationAppInfo()
        }

        guard let navigationAPI = navigationAPI else { return }

        navigationAPI.modifyTemporaryRecord(appInfos: appInfos)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (ids) in
                guard let `self` = self else { return }
                Self.logger.info("Modify Temporary VC Success, ids: \(ids)")

                let newTabs = tabs.enumerated().map { (offset, item) -> TabCandidate in
                    var newItem = item
                    newItem.uniqueId = ids[offset]
                    return newItem
                }
                self.tabArray.removeAll()
                self.tabArray.append(contentsOf: newTabs)
                for key in self.tabCache.keys {
                    if !self.tabs.contains(where: {
                        $0.uniqueId == key
                    }) {
                        _ = self.tabCache.removeValue(forKey: key)
                    }
                }
                self.delegate?.updateTabs()
             }, onError: { [weak self] _ in
                 Self.logger.info("Modify Temporary VC Error")

                self?.delegate?.updateTabs()
             })
            .disposed(by: self.disposeBag)
    }

    /// 监听移除通知
    public func removeTabsnotification() -> Observable<[TabCandidate]> {
        return observable
    }
}

class TemporaryTabScreenshot: UIViewController, TabContainable {
    let item: TabCandidate

    var image: UIImage?

    var tabID: String { return item.id }

    var tabBizID: String { return item.bizId }

    var tabIcon: CustomTabIcon { return .urlString("") }

    var tabTitle: String { return item.title }

    var tabURL: String { return item.url }

    var tabAnalyticsTypeName: String { return "" }

    var isAutoAddEdgeTabBar: Bool { return false }

    /// 重新点击临时区域时是否强制刷新（重新从url获取vc）
    ///
    /// - 默认值为false
    var forceRefresh: Bool { return false }

    init(item: TabCandidate, image: UIImage?) {
        self.item = item
        super.init(nibName: nil, bundle: nil)

        self.image = image
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view = UIImageView(image: image)
    }
}
