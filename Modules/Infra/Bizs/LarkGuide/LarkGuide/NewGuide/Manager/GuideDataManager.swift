//
//  GuideDataManager.swift
//  LarkGuide
//
//  Created by zhenning on 2020/6/28.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import EEAtomic
import LarkContainer
import LarkGuideUI
import LarkStorage
import LKCommonsLogging
import ThreadSafeDataStructure
import ServerPB

public typealias GuideDebugInfo = (key: String, canShow: Bool, priority: Int)

final class GuideDataManager {

    let disposeBag = DisposeBag()
    private static let logger = Logger.log(GuideDataManager.self, category: "LarkGuide")
    /// 引导可视区域配置列表 for debug, key、canshow、priority
    private var isGuideShowing: Bool = false
    private var currentUserId: String

    @SafeLazy private var userStore: KVStore
    private static let globalStore = KVStores.Guide.global()
    private let pushGuideObservable: Observable<PushUserGuideUpdatedMessage>
    private let pushUpdateTasksPublisher = PublishSubject<[String]>()
    var pushUpdateTasksDriver: Driver<[String]> {
        return pushUpdateTasksPublisher.asDriver(onErrorJustReturn: [])
    }
    @InjectedLazy private var userGuideAPI: UserGuideAPI

    /// 引导可视区域配置列表
    private var guideKeyInfoList: SafeArray<GuideKeyInfo> = [] + .readWriteLock
    /// guide locking
    private var isLocked: Bool = false
    private var lockExceptKeys: [String] = []
    private var guideKeyInfoDebugList: [GuideDebugInfo] {
        return self.guideKeyInfoList.map { ($0.key, $0.canShow, Int($0.priority)) }
    }

    init(pushGuideObservable: Observable<PushUserGuideUpdatedMessage>,
         currentUserId: String) {
        self._userStore = SafeLazy {
            KVStores.Guide.user(id: currentUserId)
        }
        self.currentUserId = currentUserId
        self.pushGuideObservable = pushGuideObservable
        self.bindObservable()
    }

    private func bindObservable() {
        self.pushGuideObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (pushGuideData)  in
                guard let self = self else { return }
                let pushPairList = self.transformPBToGuideData(viewAreaPairs: pushGuideData.pairs)
                // 处理push
                self.handlePushGuideData(pushPairList: pushPairList)
                let debugPushPairList = pushPairList.map { $0.key }
                Self.logger.debug("[LarkGuide]: push guide pairs = \(debugPushPairList)")
            })
            .disposed(by: self.disposeBag)
    }

    /// 处理push, 更新本地的引导数据
    /// 如果三端同时进行引导，Server会以推送方式同步已完成的引导key，收到推送需要刷新任务队列，将推送已完成key任务去除。
    /// 更新规则：
    /// - 以推送的status更新：
    ///   - 对于本地没有的key，推送了新key
    ///   - 对于本地已有的未展示key
    /// - 以本地状态，不刷新
    ///   - 对于本地已展示key
    private func handlePushGuideData(pushPairList: [GuideKeyInfo]) {

        // 更新本地cache
        let cachedKeys = self.guideKeyInfoList.map { $0.key }
        let pushedKeys = pushPairList.map { $0.key }
        /// 本地需更新push已展示状态的key列表；这里得到的是本地数据中已经消费过的，服务端只会把未消费的push到端上
        let cachedUpdateGuideInfos = self.guideKeyInfoList.filter { (info) -> Bool in
            return !pushedKeys.contains(info.key)
        }
        /// 推送新的未展示key列表；这里得到的是相对于本地数据新增的未消费的
        let pushNewGuideInfos = pushPairList.filter { (info) -> Bool in
            return !cachedKeys.contains(info.key)
        }
        /// 添加推送新的key
        self.guideKeyInfoList.append(contentsOf: pushNewGuideInfos)
        /// 已消费的需要把canShow设置为false
        cachedUpdateGuideInfos.forEach { (info) in
            var tmpInfo = info
            tmpInfo.canShow = false
            updateGuideDataByKeyInfo(guideKeyInfo: tmpInfo)
        }

        // 发送任务信号
        self.pushUpdateTasksPublisher.onNext(cachedUpdateGuideInfos.map({ $0.key }))

        /// update cache
        self.updateLocalCacheAsync(guideKeyInfoList: self.guideKeyInfoList.getImmutableCopy())
        Self.logger.debug("[LarkGuide]: handlePushGuideData",
                                      additionalData: ["cachedUpdateGuideInfos": "\(cachedUpdateGuideInfos)",
                                        "pushNewGuideInfos": "\(pushNewGuideInfos)",
                                        "guideKeyInfoDebugList": "\(guideKeyInfoDebugList)"])
    }

    // 只拉取UG引导
    public func fetchUserGuide(finish: (() -> Void)?) {
        self.userGuideAPI.fetchUserGuide()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (guidePairList) in
                guard let self = self else { finish?(); return }
                let guideKeyInfoList = self.transformPBToGuideData(viewAreaPairs: guidePairList)
                self.guideKeyInfoList.replaceInnerData(by: guideKeyInfoList)
                /// update cache
                self.updateLocalCacheAsync(guideKeyInfoList: self.guideKeyInfoList.getImmutableCopy(), callBack: { success in
                    if success {
                        Self.logger.debug("[LarkGuide]: fetchUserGuide set cache",
                                                        additionalData: ["guideKeyInfoList": "\(self.guideKeyInfoList)",
                                                        "guidePairList": "\(guidePairList)"])
                    }
                    finish?()
                })
            }, onError: { [weak self] _ in
                guard let self = self else { finish?(); return }
                let guideKeyInfoList = self.getLocalCacheGuideData()
                self.guideKeyInfoList.replaceInnerData(by: guideKeyInfoList)
                finish?()
            })
            .disposed(by: self.disposeBag)
    }

    // 拉取UG引导+CCM引导
    public func fetchUserGuideNew(finish: (() -> Void)?) {
        // 合并UGGuide和CCMGuide引导的key
        Observable.combineLatest(self.userGuideAPI.fetchUserGuide(), self.userGuideAPI.getCCMUserGuide())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (ugGuideList, ccmGuideList) in
                guard let self = self else { finish?(); return }
                let ugGuideKeyInfoList = self.transformPBToGuideData(viewAreaPairs: ugGuideList)
                let ccmGuideKeyInfoList = self.transformServerPBToGuideData(viewAreaPairs: ccmGuideList)
                self.guideKeyInfoList.replaceInnerData(by: ugGuideKeyInfoList)
                self.guideKeyInfoList.append(contentsOf: ccmGuideKeyInfoList)
                /// update cache
                self.updateLocalCacheAsync(guideKeyInfoList: self.guideKeyInfoList.getImmutableCopy(), callBack: { success in
                    if success {
                        Self.logger.debug("[LarkGuide]: fetchUserGuide set cache",
                                                        additionalData: [
                                                            "ugGuidePairList": "\(ugGuideKeyInfoList)",
                                                            "ccmGuidePairList": "\(ccmGuideKeyInfoList)"])
                    }
                    finish?()
                })
        }, onError: { [weak self] _ in
            guard let self = self else { finish?(); return }
            let guideKeyInfoList = self.getLocalCacheGuideData()
            self.guideKeyInfoList.replaceInnerData(by: guideKeyInfoList)
            finish?()
        }).disposed(by: self.disposeBag)
    }

    func getCurrentUserGuideCache() -> [GuideDebugInfo] {
        Self.logger.debug("[LarkGuide]: getUserGuideCache called")
        return self.guideKeyInfoDebugList
    }

    /// 设置本地内存态的引导配置, 返回是否设置成功
    func updateGuideMemoryCache(guideKey: String, canShow: Bool) -> Bool {
        /// 未展示的key
        guard var keyInfo = self.getGuideKeyInfoByKey(key: guideKey) else {
            return false
        }
        keyInfo.canShow = canShow
        self.updateGuideDataByKeyInfo(guideKeyInfo: keyInfo)
        Self.logger.debug("[LarkGuide]: updateGuideMemoryCache successed guideKey = \(guideKey), canShow = \(canShow), debug = \(self.guideKeyInfoDebugList)")
        return true
    }

    func clearUserGuideCache() {
        self.guideKeyInfoList.removeAll()
        self.userStore.removeValue(forKey: KVKeys.Guide.guideData)
        self.userStore.synchronize()
    }

    func getIsGuideShowing() -> Bool {
        return isLocked || isGuideShowing
    }

    func setIsGuideShowing(isShow: Bool) {
        guard checkMainThread() && !isLocked else { return }
        isGuideShowing = isShow
    }

    func shouldShowGuide(key: String) -> Bool {
        /// check locking
        let isKeyLocked: Bool = isKeyLockedCheck(key: key)

        Self.logger.debug("[LarkGuide]: shouldShowGuide",
                                      additionalData: ["isGuideShowing": "\(isGuideShowing)",
                                        "key": "\(key)",
                                        "keyInfo": "\(String(describing: self.getGuideKeyInfoByKey(key: key)))",
                                        "isKeyLocked": "\(isKeyLocked)",
                                        "guideKeyInfoDebugList": "\(guideKeyInfoDebugList)"])

        guard !isKeyLocked else { return false }
        /// 未展示的key
        if let keyInfo = self.getGuideKeyInfoByKey(key: key), keyInfo.canShow {
            return true
        } else {
            return false
        }
    }

    func didShowedGuide(key: String) {
        guard checkMainThread() else { return }
        // 1. update local cache
        if var keyInfo = self.getGuideKeyInfoByKey(key: key) {
            keyInfo.canShow = false
            // 2. notify server
            self.userGuideAPI.postUserConsumingGuide(guideKeys: [key])
                .subscribe(onNext: { (_) in
                    Self.logger.debug("[LarkGuide]: postUserConsumingGuide success",
                                                  additionalData: ["guideKey": "\(key)"])
                })
                .disposed(by: self.disposeBag)
            /// update cache
            self.updateLocalCacheByGuideInfo(guideKeyInfo: keyInfo)
            Self.logger.debug("[LarkGuide]: didShowedGuide called",
                                          additionalData: ["keyInfo": "\(keyInfo)"])
        }
    }

    func tryLockNewGuide(lockExceptKeys: [String]) -> Bool {
        Self.logger.debug("[LarkGuide]: tryLockNewGuide",
                                      additionalData: ["lockExceptKeys": "\(lockExceptKeys)",
                                                       "isLocked": "\(isLocked)",
                                                       "isGuideShowing": "\(isGuideShowing)"])

         guard checkMainThread() && !isLocked && !isGuideShowing else {
            let errorMsg = "isLocked = \(isLocked), isGuideShowing = \(isGuideShowing)"
            Tracer.trackGuideTryLock(succeed: false,
                                     lockExceptKeys: lockExceptKeys,
                                     trackError: LarkGuideTrackError(errorMsg: errorMsg)
            )
            return false
         }
         self.isLocked = true
         self.lockExceptKeys = lockExceptKeys
        Tracer.trackGuideTryLock(succeed: true, lockExceptKeys: lockExceptKeys)
         return true
     }

    func unlockNewGuide() {
        Self.logger.debug("[LarkGuide]: unlockNewGuide",
                                      additionalData: ["lockExceptKeys": "\(lockExceptKeys)",
                                                       "isLocked": "\(isLocked)"])

         guard checkMainThread() && isLocked else { return }
         self.isLocked = false
         self.lockExceptKeys = []
     }

    // 设置、更新key缓存配置
    func setGuideConfig<T: Encodable>(key: String, object: T) {
        let data = (try? JSONEncoder().encode(object)) ?? Data()
        Self.globalStore[KVKeys.Guide.mapGuideKey(key)] = data
        Self.globalStore.synchronize()
    }

    // 获取当前key的缓存配置
    func getGuideConfig<T: Decodable>(key: String) -> T? {
        guard self.shouldShowGuide(key: key) else { return nil }

        if let data = Self.globalStore[KVKeys.Guide.mapGuideKey(key)],
            let object = try? JSONDecoder().decode(T.self, from: data) {
            return object
        }
        return nil
    }
}

// Utils
extension GuideDataManager {

    private func updateLocalCacheByGuideInfo(guideKeyInfo: GuideKeyInfo) {
        let guideKeyInfoList = self.updateGuideDataByKeyInfo(guideKeyInfo: guideKeyInfo)
        self.updateLocalCacheAsync(guideKeyInfoList: guideKeyInfoList)
    }

    func getGuideKeyInfoByKey(key: String) -> GuideKeyInfo? {
        let info = guideKeyInfoList.first { (info) -> Bool in
            info.key == key
        }
        return info
    }

    /// 更新本地内存态引导状态
    @discardableResult
    private func updateGuideDataByKeyInfo(guideKeyInfo: GuideKeyInfo) -> [GuideKeyInfo] {
        if let index = guideKeyInfoList.firstIndex(where: { $0.key == guideKeyInfo.key }) {
            guideKeyInfoList.remove(at: index)
            guideKeyInfoList.insert(guideKeyInfo, at: index)
        }
        let _guideKeyInfoList = guideKeyInfoList.getImmutableCopy()
        Self.logger.debug("[LarkGuide]: updateGuideDataByKeyInfo after",
                                      additionalData: ["guideKeyInfoDebugList": "\(guideKeyInfoDebugList)"])
        return _guideKeyInfoList
    }

    /// 将SDKPB转成Guide数据
    private func transformPBToGuideData(viewAreaPairs: [UserGuideViewAreaPair]) -> [GuideKeyInfo] {
        viewAreaPairs.flatMap { (pair) -> [GuideKeyInfo] in
            let guideKeyInfos = pair.orderedInfos.map { (userGuideInfo) -> GuideKeyInfo in
                let viewArea = transformPBViewAreaToViewAreaInfo(userGuideViewArea: pair.area)
                /// server gives the unshowed keys, so the canShow is default true
                let canShow = true
                let guideKeyInfo = GuideKeyInfo(key: userGuideInfo.key,
                                                canShow: canShow,
                                                keyOrder: userGuideInfo.priority,
                                                viewArea: viewArea)
                return guideKeyInfo
            }
            return guideKeyInfos
        }
    }

    /// 将可视区域PB，转成可视区域结构
    private func transformPBViewAreaToViewAreaInfo(userGuideViewArea: UserGuideViewArea) -> GuideViewAreaInfo {
        let viewAreaInfo = GuideViewAreaInfo(key: userGuideViewArea.key, priority: userGuideViewArea.priority)
        return viewAreaInfo
    }

    /// 将ServerPB转成Guide
    private func transformServerPBToGuideData(viewAreaPairs: [ServerPB_Guide_UserGuideViewAreaPair]) -> [GuideKeyInfo] {
        viewAreaPairs.flatMap({ (pair) -> [GuideKeyInfo] in
            let viewArea = GuideViewAreaInfo(key: pair.area.key, priority: pair.area.priority)
            let guideKeyInfos = pair.infos.map { (userGuideInfo) -> GuideKeyInfo in
                let guideKeyInfo = GuideKeyInfo(key: userGuideInfo.key, canShow: true, keyOrder: userGuideInfo.priority, viewArea: viewArea)
                return guideKeyInfo
            }
            return guideKeyInfos
        })
    }

    /// 异步更新本地缓存
    private func updateLocalCacheAsync(guideKeyInfoList: [GuideKeyInfo],
                                      callBack: ((_ success: Bool) -> Void)? = nil) {
        /// update userDefaults
        if let data = (try? JSONEncoder().encode(guideKeyInfoList)) {
            DispatchQueue.main.async { [weak self] in
                self?.userStore[KVKeys.Guide.guideData] = data
                self?.userStore.synchronize()
                if let callBack = callBack {
                    callBack(true)
                }
            }
        } else {
            if let callBack = callBack {
                callBack(false)
            }
        }
    }

    /// 获取本地缓存
    private func getLocalCacheGuideData() -> [GuideKeyInfo] {
        guard let listData = userStore[KVKeys.Guide.guideData],
            let list = try? JSONDecoder().decode([GuideKeyInfo].self, from: listData) else {
                return []
        }
        let cacheDebugList = list.map { ($0.key, $0.canShow, Int($0.priority)) }
        Self.logger.debug("[LarkGuide]: getLocalCacheGuideData",
                                      additionalData: ["cacheDebugList": "\(cacheDebugList)"])
        return list
    }

    /// key是否被锁住
    private func isKeyLockedCheck(key: String) -> Bool {
        return self.isLocked && !self.lockExceptKeys.contains(key)
    }

    private func checkMainThread() -> Bool {
        if Thread.current != .main {
            assertionFailure("the operation should excuted in mainThread!")
            return false
        }
        return true
    }

}
