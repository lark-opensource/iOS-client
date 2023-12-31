//
//  PageKeeperManager.swift
//  LarkKeepAlive
//
//  Created by Yaoguoguo on 2023/9/27.
//

import Foundation
import LarkContainer
import LarkDowngrade
import LarkSetting
import LarkQuickLaunchInterface
import LKCommonsLogging
import Swinject
import ThreadSafeDataStructure

extension PagePreservable {
    func getRealScene() -> PageKeeperScene {
        return self.getPageSceneBySelf() ?? self.pageScene
    }
}

/// https://bytedance.feishu.cn/wiki/FPlUwLWy4iEb6okXBpIcmBH2nO9?create_from=create_doc_to_wiki
struct PageKeeperSetting {
    /// Setting Type
    var type: PageKeeperType

    /// 普通情况下保活时间
    var keepTime: Double

    /// 主导航固定区保活时间
    var mainTabKeepTime: Double

    /// 主导航更多里保活时间
    var quickTabKeepTime: Double

    /// 多任务浮窗保活时间
    var suspendTaskKeepTime: Double

    /// 工作台保活时间
    var workbenchWebKeepTime: Double

    /// 临时区保活时间
    var temporaryTabKeepTime: Double

    /// 白名单保活时间
    var allowListKeepTime: Double = 0

    /// 是否为白名单用户，如果是，则不用再考虑白名单列表
    var allowUser: Bool = false
    
    /// 白名单列表app，对应pageID
    var allowList: [String] = []

    /// 保活数量
    var bizKeepliveCount: Int?

    init(type: PageKeeperType,
         keepTime: Double,
         mainTabKeepTime: Double,
         quickTabKeepTime: Double,
         suspendTaskKeepTime: Double,
         temporaryTabKeepTime: Double,
         workbenchWebKeepTime: Double,
         allowList: [String] = [],
         bizKeepliveCount: Int? = nil) {
        self.type = type
        self.keepTime = keepTime
        self.mainTabKeepTime = mainTabKeepTime
        self.quickTabKeepTime = quickTabKeepTime
        self.suspendTaskKeepTime = suspendTaskKeepTime
        self.temporaryTabKeepTime = temporaryTabKeepTime
        self.workbenchWebKeepTime = workbenchWebKeepTime
        self.allowList = allowList
        self.bizKeepliveCount = bizKeepliveCount
    }
}

extension PageKeeperManager: PageKeeperService {

    public var hasSetting: Bool {
        return cacheSetting != nil
    }

    /// 用于获取是否在场景中：主导航、多任务浮窗
    /// - Parameter sceneProvider: sceneProvider
    public func setSceneProvider(_ sceneProvider: PageSceneProvider) {
        self.sceneProviders.append(sceneProvider)
    }

    /// 可供查询是否在白名单
    public func pageIDInWhiteList(_ id: String, scene: PageKeeperScene) -> Bool {
        for setting in self.pageTypeSettings.values {
            if setting.allowUser || setting.allowList.contains(where: {
                $0 == id
            }) {
                return true
            }
        }
        return false
    }

    /// 获取cache，获取到后会从cache中移除
    /// - Parameter id: pageid
    /// - Returns: PagePreservable?
    public func popCachePage(id: String, scene: String) -> PagePreservable? {
        guard hasSetting else { return nil }

        Self.logger.info("Pop Cache Page id: \(id), scene: \(scene)")

        guard let page = getCachePage(id: id, scene: scene) else { return nil }

        removePage(page, force: false, notice: true, with: nil)

        Self.logger.info("Pop Cache Page id: \(id), scene: \(scene) success")

        return page
    }

    /// 获取cache
    /// - Parameter id: pageid
    /// - Returns: PagePreservable?
    public func getCachePage(id: String, scene: String) -> PagePreservable? {
        guard hasSetting else { return nil }

        Self.logger.info("Get Cache Page id: \(id), scene: \(scene)")

        guard let scene = PageKeeperScene(rawValue: scene), let page = self.cacheWrappers.first(where: {
            $0.page?.pageID == id && $0.page?.getRealScene() == scene
        })?.page else { return nil }

        Self.logger.info("Get Cache Page id: \(id), scene: \(scene) success")
        return page
    }

    /// 存Page
    public func cachePage(_ page: PagePreservable, with completion: ((Bool) -> Void)?) {

        Self.logger.info("Cache Page id: \(page.pageID), scene: \(page.getRealScene().rawValue)")

        guard !page.pageID.isEmpty, hasSetting else {
            completion?(false)
            return
        }

        if let error = page.shouldAddToPageKeeper() {
            Self.logger.info("Cache Page id: \(page.pageID), error: \(error.localizedDescription)")
            completion?(false)
            return
        }

        let settingKeepTime = self.calculateKeepTime(page)

        Self.logger.info("Cache Page id: \(page.pageID), keepTime: \(settingKeepTime)")

        guard settingKeepTime != 0 else { return }

        var keepTime = Date().timeIntervalSince1970 + settingKeepTime

        Self.logger.info("Cache Page id: \(page.pageID), real keepTime: \(keepTime)")

        page.willAddToPageKeeper()

        let scene = page.getRealScene()

        Self.logger.info("Cache Page id: \(page.pageID), real scene: \(scene)")

        var id = ""
        let isFull = cacheWrappers.count >= keepliveCount
        if let first = self.cacheWrappers.first(where: {
            $0.page?.pageID == page.pageID && $0.page?.pageType == page.pageType && $0.page?.getRealScene() == scene
        }) {
            first.timestamp = keepTime
            id = first.id
        } else {
            if let bizKeepliveCount = cacheSetting?.pageTypeSettings[page.pageType]?.bizKeepliveCount,
               cacheWrappers.filter({ $0.page?.pageType == page.pageType }).count >= bizKeepliveCount {
                Self.logger.info("Cache Page id: \(page.pageID), out of bizKeepliveCount :\(cacheWrappers.count)")

                let count = cacheWrappers.filter({ $0.page?.pageType == page.pageType }).count - bizKeepliveCount + 1
                removeCacheQueue(count: count, endKeepliveReason: "Cache exceeds maximum number", pageType: page.pageType)

            } else if cacheWrappers.count >= keepliveCount {
                Self.logger.info("Cache Page id: \(page.pageID), out of range :\(cacheWrappers.count)")

                let count = cacheWrappers.count - keepliveCount + 1
                removeCacheQueue(count: count, endKeepliveReason: "Cache exceeds maximum number")
            }

            let wrapper = CacheWrapper(timestamp: keepTime, page: page)
            id = wrapper.id

            Self.logger.info("Cache Page id: \(page.pageID), append")
            self.cacheWrappers.append(wrapper)
        }

        PageKeeperTracker.trackBeginKeeplive(id: id,
                                             pageID: page.pageID,
                                             type: page.pageType,
                                             beginTime: keepTime,
                                             keepTime: settingKeepTime,
                                             scene: page.getRealScene(),
                                             isFull: isFull)

        page.didAddToPageKeeper()
        updateTimeQueue()

        Self.logger.info("Cache Page id: \(page.pageID), completion")

        completion?(true)
    }

    /// 移除Page
    public func removePage(_ page: PagePreservable, force: Bool, notice: Bool, with completion: ((Bool) -> Void)?) {
        func isEuqal(wrapper: CacheWrapper, page: PagePreservable) -> Bool {
            let scene = page.getRealScene()
            return wrapper.page?.pageID == page.pageID && wrapper.page?.pageType == page.pageType && wrapper.page?.getRealScene() == scene
        }

        Self.logger.info("Remove Page id: \(page.pageID), scene: \(page.getRealScene().rawValue), force: \(force)")

        let scene = page.getRealScene()

        guard !page.pageID.isEmpty, hasSetting, self.cacheWrappers.contains(where: {
            isEuqal(wrapper: $0, page: page)
        }) else {
            completion?(false)
            return
        }

        if !force, let error = page.shouldRemoveFromPageKeeper() {
            Self.logger.info("Remove Page id: \(page.pageID), error: \(error.localizedDescription)")

            if let first = self.cacheWrappers.first(where: {
                isEuqal(wrapper: $0, page: page)
            }) {
                first.error = error
            }

            updateTimeQueue()
            completion?(false)
            return
        }

        if notice {
            page.willRemoveFromPageKeeper()
        }

        Self.logger.info("Remove Page id: \(page.pageID), real scene: \(scene)")

        var id = ""
        var error: Error?
        var newCacheWrappers = self.cacheWrappers.getImmutableCopy()
        newCacheWrappers.removeAll {
            if isEuqal(wrapper: $0, page: page) {
                id = $0.id
                error = $0.error
                return true
            }
            return false
        }

        self.cacheWrappers.removeAll()
        self.cacheWrappers.append(contentsOf: newCacheWrappers)

        PageKeeperTracker.trackEndKeeplive(id: id,
                                           pageID: page.pageID,
                                           type: page.pageType,
                                           endTime: Date().timeIntervalSince1970,
                                           endKeepliveReason: "Developer voluntarily removed",
                                           keepliveEndDelayReason: error?.localizedDescription.description ?? "")

        if notice {
            page.didRemoveFromPageKeeper()
        }
        updateTimeQueue()

        Self.logger.info("Remove Page id: \(page.pageID), completion")
        completion?(true)
    }
}

extension PageKeeperManager {
    var keepliveCount: Int {
        return cacheSetting?.keepliveCount ?? 0
    }

    var backKeepliveCount: Int {
        return cacheSetting?.backKeepliveCount ?? 0
    }

    var memoryNormal: Double {
        return cacheSetting?.memoryNormal ?? 0
    }

    var memoryWarning: Double {
        return cacheSetting?.memoryWarning ?? 0
    }

    var memorSerious: Double {
        return cacheSetting?.memorSerious ?? 0
    }

    var pageTypeSettings: [PageKeeperType: PageKeeperSetting] {
        return cacheSetting?.pageTypeSettings ?? [:]
    }
}

public class PageKeeperManager {
    static let logger = Logger.log(PageKeeperManager.self, category: "Module.PageKeeper")

    class CacheWrapper {
        let id: String
        var timestamp: TimeInterval
        var page: PagePreservable?
        var error: Error?

        init(timestamp: TimeInterval = Date().timeIntervalSince1970,
             page: PagePreservable? = nil) {
            self.id = UUID().uuidString
            self.timestamp = timestamp
            self.page = page
        }
    }

    class CacheSetting {
        var keepliveCount: Int
        var backKeepliveCount: Int
        var memoryNormal: Double
        var memoryWarning: Double
        var memorSerious: Double

        /// 缓存配置
        var pageTypeSettings: [PageKeeperType: PageKeeperSetting]

        init(keepliveCount: Int = 0,
             backKeepliveCount: Int = 0,
             memoryNormal: Double = 600,
             memoryWarning: Double = 400,
             memorSerious: Double = 200,
             pageTypeSettings: [PageKeeperType : PageKeeperSetting] = [:]) {
            self.keepliveCount = keepliveCount
            self.backKeepliveCount = backKeepliveCount
            self.memoryNormal = memoryNormal
            self.memoryWarning = memoryWarning
            self.memorSerious = memorSerious
            self.pageTypeSettings = pageTypeSettings
        }

        static func tranformTypeDict(_ dict: [String: Any]) -> CacheSetting? {
            let keepliveCount = dict["keepliveCount"] as? Int ?? 0
            let backKeepliveCount = dict["backgroundKeepliveCount"] as? Int ?? 0
            let memoryNormal = dict["memoryNormal"] as? Double ?? 0
            let memoryWarning = dict["memoryWarning"] as? Double ?? 0
            let memorSerious = dict["memorSerious"] as? Double ?? 0

            var pageTypeSettings: [PageKeeperType: PageKeeperSetting] = [:]
            pageTypeSettings[.littleapp] = tranformTypeDict(dict["microapp"] as? [String: Any], type: .littleapp)
            pageTypeSettings[.webapp] = tranformTypeDict(dict["webapp"] as? [String: Any], type: .webapp)
            pageTypeSettings[.h5] = tranformTypeDict(dict["h5"] as? [String: Any], type: .h5)
            pageTypeSettings[.ccm] = tranformTypeDict(dict["ccm"] as? [String: Any], type: .ccm)

            return CacheSetting(keepliveCount: keepliveCount,
                                backKeepliveCount: backKeepliveCount,
                                memoryNormal: memoryNormal,
                                memoryWarning: memoryWarning,
                                memorSerious: memorSerious,
                                pageTypeSettings: pageTypeSettings)
        }

        static private func tranformTypeDict(_ dict: [String: Any]?, type: PageKeeperType) -> PageKeeperSetting? {
            guard let dict = dict else { return nil }

            let keepTime = dict["keepliveTime"] as? Double ?? 0
            let mainTabKeepTime = dict["mainTabWebTime"] as? Double ?? 0
            let quickTabKeepTime = dict["quickTabWebTime"] as? Double ?? 0
            let suspendTaskKeepTime = dict["multiTaskWebTime"] as? Double ?? 0
            let temporaryTabKeepTime = dict["tmpTabWebTime"] as? Double ?? 0
            let workbenchWebKeepTime = dict["workbenchWebTime"] as? Double ?? 0
            let bizKeepliveCount = dict["bizKeepliveCount"] as? Int
            let allowList = dict["webID"] as? [String] ?? []

            return PageKeeperSetting(type: type,
                                     keepTime: keepTime,
                                     mainTabKeepTime: mainTabKeepTime,
                                     quickTabKeepTime: quickTabKeepTime,
                                     suspendTaskKeepTime: suspendTaskKeepTime,
                                     temporaryTabKeepTime: temporaryTabKeepTime,
                                     workbenchWebKeepTime: workbenchWebKeepTime,
                                     allowList: allowList,
                                     bizKeepliveCount: bizKeepliveCount)
        }
    }

    /// Scene Provider，提供判断场景
    var sceneProviders: [PageSceneProvider] = []

    var cacheSetting: CacheSetting?

    /// 缓存
    var cacheWrappers: SafeArray<CacheWrapper> = [] + .readWriteLock

    private var workItem: DispatchWorkItem?
    private let userResolver: UserResolver

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        getPageKeeperSetting()
        observeMemoryWaring()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    deinit {
        self.removeCacheQueue(count: self.cacheWrappers.count, endKeepliveReason: "deinit", force: true)
    }

    @objc
    private func applicationDidEnterBackground(_ notification: Notification) {
        Self.logger.info("Application Did Enter Background")
        guard cacheWrappers.count > backKeepliveCount, hasSetting else {
            return
        }

        Self.logger.info("Application Did Enter Background remove tabs total: \(cacheWrappers.count)")
        let count = cacheWrappers.count - backKeepliveCount
        removeCacheQueue(count: count, endKeepliveReason: "Remove from background")
    }

    private func getPageKeeperSetting() {
        guard let settings = try? userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "lark_webapp_unified_keep_live")),
              let cacheSetting = CacheSetting.tranformTypeDict(settings) else {
            return
        }

        Self.logger.info("Get PageKeeper Setting: \(settings)")
        self.cacheSetting = cacheSetting
    }

    private func observeMemoryWaring() {
        guard hasSetting else { return }

        Self.logger.info("Observe MemoryWaring, memoryNormal: \(memoryNormal) memoryWarning: \(memoryWarning) memorSerious: \(memorSerious)")

        LarkUniversalDowngradeService
            .shared
            .dynamicDowngrade(key: "LarkKeepAlivePageKeeperManager",
                              strategies: .overMemory(memoryNormal, memoryNormal) ||| .overMemory(memoryWarning, memoryWarning) ||| .overMemory(memorSerious, memorSerious)) { [weak self] dataInfo in
                guard let self = self, let info = dataInfo?["LarkPerformanceCustomStrategy"] as? LarkPerformanceAppStatues else { return }
                Self.logger.info("Observe MemoryWaring Callback info: \(info)")
                switch info.remainMemory {
                case self.memoryNormal...:
                    self.removeCacheQueue(count: 1, endKeepliveReason: "memory normal")
                case self.memoryWarning...:
                    self.removeCacheQueue(count: self.cacheWrappers.count - 1, endKeepliveReason: "memory warning")
                case self.memorSerious...:
                    self.removeCacheQueue(count: self.cacheWrappers.count, endKeepliveReason: "memory serious")
                default:
                    break
                }
            } doNormal: { _ in
                //这个是内存恢复的时候的处理，不需要执行
            }
    }

    private func getScene(_ page: PagePreservable) -> PageKeeperScene? {
        for provider in sceneProviders {
            if let scene = provider.getSceneBy(id: page.pageID) {
                return scene
            }
        }

        return nil
    }

    /// 更新计时队列
    private func updateTimeQueue() {
        guard hasSetting else { return }

        let now = Date().timeIntervalSince1970
        Self.logger.info("Update Time Queue start: \(now)")

        // 获取列表中第一个大于现在的时间戳，如果未获取到直接执行remove
        guard let firstTime = cacheWrappers.sorted(by: { lhs, rhs in
            lhs.timestamp < rhs.timestamp
        }).first(where: {
            $0.timestamp > now
        })?.timestamp else {
            removeCacheQueue(timestamp: now, endKeepliveReason: "keepliveTimeout")
            return
        }

        // 未执行的话取消当前任务
        let remainingTime = firstTime - now
        workItem?.cancel()

        Self.logger.info("Update Time Queue remainingTime: \(remainingTime)")

        // 开启新任务
        let newWorkItem = DispatchWorkItem {
            let now = Date().timeIntervalSince1970
            Self.logger.info("Update Time Queue remove")

            self.removeCacheQueue(timestamp: now, endKeepliveReason: "keepliveTimeout")
            if !self.cacheWrappers.isEmpty {
                self.updateTimeQueue()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime, execute: newWorkItem)
        workItem = newWorkItem
    }
    
    /// 用来移除小于时间戳的cache
    /// - Parameter timestamp: 需要移除的时间戳
    private func removeCacheQueue(timestamp: TimeInterval, endKeepliveReason: String) {
        Self.logger.info("Remove Cache queue timestamp: \(timestamp)")

        var newCacheWrappers = cacheWrappers.getImmutableCopy()
        newCacheWrappers.removeAll {
            if $0.timestamp > timestamp {
                return false
            }
            if let error = $0.page?.shouldRemoveFromPageKeeper() {
                Self.logger.info("PageID: \($0.page?.pageID ?? "") Refuse to remove queue error: \(error.localizedDescription)")
                return false
            }
            Self.logger.info("PageID: \($0.page?.pageID ?? ""), Remove Cache queue")
            $0.page?.willRemoveFromPageKeeper()
            $0.page?.didRemoveFromPageKeeper()

            var time = Date().timeIntervalSince1970
            if let page = $0.page {
                PageKeeperTracker.trackEndKeeplive(id: $0.id,
                                                   pageID: page.pageID,
                                                   type: page.pageType,
                                                   endTime: time,
                                                   endKeepliveReason: endKeepliveReason,
                                                   keepliveEndDelayReason: $0.error?.localizedDescription.description ?? "")
            }

            return true
        }

        self.cacheWrappers.removeAll()
        self.cacheWrappers.append(contentsOf: newCacheWrappers)
    }
    
    /// 移除指定数量的Cache，按照时间戳排序
    /// - Parameter count: <#count description#>
    private func removeCacheQueue(count: Int, endKeepliveReason: String, pageType: PageKeeperType? = nil, force: Bool = false) {
        Self.logger.info("Remove Cache queue count: \(count)")

        guard count > 0 else { return }
        var removeCount = count
        var time = Date().timeIntervalSince1970

        for cacheWrapper in cacheWrappers.getImmutableCopy().sorted(by: { lhs, rhs in
            lhs.timestamp < rhs.timestamp
        }) {

            if !force, let pageType = pageType, cacheWrapper.page?.pageType != pageType {
                Self.logger.info("PageID: \(cacheWrapper.page?.pageID ?? "") pageType unequal")
                continue
            }

            if !force, let error = cacheWrapper.page?.shouldRemoveFromPageKeeper() {
                Self.logger.info("PageID: \(cacheWrapper.page?.pageID ?? "") Refuse to remove queue error: \(error.localizedDescription)")
                continue
            }

            cacheWrapper.page?.willRemoveFromPageKeeper()

            var newCacheWrappers = cacheWrappers.getImmutableCopy()
            newCacheWrappers.removeAll {
                $0.page?.pageID == cacheWrapper.page?.pageID
            }

            self.cacheWrappers.removeAll()
            self.cacheWrappers.append(contentsOf: newCacheWrappers)

            Self.logger.info("PageID: \(cacheWrapper.page?.pageID ?? ""), Remove Cache queue")
            cacheWrapper.page?.didRemoveFromPageKeeper()

            if let page = cacheWrapper.page {
                PageKeeperTracker.trackEndKeeplive(id: cacheWrapper.id,
                                                   pageID: page.pageID,
                                                   type: page.pageType,
                                                   endTime: time,
                                                   endKeepliveReason: endKeepliveReason,
                                                   keepliveEndDelayReason: cacheWrapper.error?.localizedDescription.description ?? "")
            }

            removeCount -= 1

            if removeCount <= 0 {
                break
            }
        }
    }

    /// 计算时间戳，按照规则取最大时间戳
    /// - Parameter page:
    /// - Returns: 当没有相关配置时返回nil
    private func calculateKeepTime(_ page: PagePreservable) -> TimeInterval {
        Self.logger.info("PageID: \(page.pageID) Calculate Keep Time")

        guard let pageTypeSetting = pageTypeSettings[page.pageType] else { return 0 }

        var keepTime: TimeInterval = 0

        let scene = page.getRealScene()

        switch scene {
        case .normal:
            keepTime = pageTypeSetting.keepTime
        case .main:
            keepTime = pageTypeSetting.mainTabKeepTime
        case .quick:
            keepTime = pageTypeSetting.quickTabKeepTime
        case .temporary:
            keepTime = pageTypeSetting.temporaryTabKeepTime
        case .suspend:
            keepTime = pageTypeSetting.suspendTaskKeepTime
        case .workbench:
            keepTime = pageTypeSetting.workbenchWebKeepTime
        }

        Self.logger.info("PageID: \(page.pageID) Calculate Keep Time Scene: \(scene.rawValue), keepTime: \(keepTime)")

        return keepTime
    }
}
