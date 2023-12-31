//
//  GuideManager.swift
//  Lark
//
//  Created by lichen on 2017/8/10.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import KeychainAccess
import LKCommonsLogging
import LarkStorage

public final class GuideManager: GuideService {

    static private let globalStore = KVStores.Guide.global()

    static let logger = Logger.log(GuideManager.self, category: "GuideManager")
    // 3.0 版本以后已弃用，留着标记keychain使用情况，以便后续需要清理
    static private let launchGuideKeychain = Keychain(service: "com.bytedance.ee.lark.launchGuide").synchronizable(false)
    static private let launchGuideKey = "LAUNCHGUIDEKEY"

    private var isLocked: Bool = false
    private var guideIsShowing: Bool = false
    private var exceptKeys: [String] = []

    private let disposeBag = DisposeBag()
    private let productGuideAPI: ProductGuideAPI
    private let pushObservable: Observable<PushProductGuideMessage>

    private var productGuideList: [String: Bool] = {
        return GuideManager.globalStore[KVKeys.Guide.GuideList] ?? [:]
    }()
    private var currentDate: Date?
    private let coolTime: Double = 0

    init(productGuideAPI: ProductGuideAPI,
         pushObservable: Observable<PushProductGuideMessage>) {

        self.productGuideAPI = productGuideAPI
        self.pushObservable = pushObservable

        self.pushObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (msg)  in
                self?.productGuideList.merge(msg.guides, uniquingKeysWith: { $1 })
                GuideManager.globalStore[KVKeys.Guide.GuideList] = self?.productGuideList
            })
            .disposed(by: self.disposeBag)
    }

    public func asyncUpdateProductGuideList() {
        DispatchQueue.global().async {
            self.productGuideAPI.getProductGuide()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (dic) in
                    self?.productGuideList = dic
                    GuideManager.globalStore[KVKeys.Guide.GuideList] = self?.productGuideList
                })
                .disposed(by: self.disposeBag)
        }
    }

    public func clearProductGuideList() {
        self.productGuideList.removeAll()
        GuideManager.globalStore.removeValue(forKey: KVKeys.Guide.GuideList)
    }

    public func setGuideIsShowing(isShow: Bool) {
        guard checkMainThread() && !isLocked else { return }
        guideIsShowing = isShow
    }

    public func getGuideIsShowing() -> Bool {
        return isLocked || guideIsShowing
    }

    public func needShowGuide(key: String) -> Bool {
        guard checkMainThread() else { return false }
        #if DEBUG
        if GuideManager.globalStore[KVKeys.Guide.DisablePopup] {
            return false
        }
        #endif

        if isLocked && !exceptKeys.contains(key) || guideIsShowing { return false }

        if let result = self.productGuideList[key] {
            if currentDate != nil {
                // 5minute cooling Time
                let timeInterval = Date().timeIntervalSince(currentDate!)
                if timeInterval > coolTime {
                    currentDate = Date()
                    return result
                } else {
                    return false
                }
            } else {
                currentDate = Date()
                return result
            }

        } else {
            return false
        }
    }

    public func showGuide<T: Decodable>(key: String) -> T? {
        guard checkMainThread() else { return nil }
        #if DEBUG
        if GuideManager.globalStore[KVKeys.Guide.DisablePopup] {
            return nil
        }
        #endif

        if !needShowGuide(key: key) {
            return nil
        }

        if let data = GuideManager.globalStore[KVKeys.Guide.guideKey(key)],
            let object = try? JSONDecoder().decode(T.self, from: data) {
            return object
        }
        return nil
    }

    public func didShowGuide(key: String) {
        guard checkMainThread() else { return }
        if self.productGuideList[key] != nil {
            self.productGuideList[key] = false
            GuideManager.globalStore[KVKeys.Guide.GuideList] = self.productGuideList
            self.productGuideAPI.deleteProductGuide(guides: [key])
                .subscribe(onNext: { (_) in
                })
                .disposed(by: self.disposeBag)
        }
    }

    public func setShowGuide<T: Encodable>(key: String, object: T) {
        guard checkMainThread() else { return }
        let data = (try? JSONEncoder().encode(object)) ?? Data()
        GuideManager.globalStore[KVKeys.Guide.guideKey(key)] = data
        GuideManager.globalStore.synchronize()
    }

    public func tryLockGuide(exceptKeys: [String]) -> Bool {
        guard checkMainThread() && !isLocked && !guideIsShowing else { return false }
        self.isLocked = true
        self.exceptKeys = exceptKeys
        return true
    }

    public func unlockGuide() {
        guard checkMainThread() && isLocked else { return }
        self.isLocked = false
        self.exceptKeys = []
    }

    private func checkMainThread() -> Bool {
        if Thread.current != .main {
            assertionFailure("operation need in mainThread")
            return false
        }
        return true
    }

}
