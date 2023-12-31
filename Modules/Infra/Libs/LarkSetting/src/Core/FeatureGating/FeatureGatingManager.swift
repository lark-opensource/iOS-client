//
//  FeatureGatingManager.swift
//  LarkSetting
//
//  Created by Supeng on 2021/6/3.
//

import Foundation
import RxSwift
import LarkCombine
import LarkContainer
import LKCommonsLogging

/// FG管理类，单例，提供FG获取接口
public final class FeatureGatingManager {
    private static let logger = Logger.log(FeatureGatingManager.self, category: "LarkSetting")

    private let featureType: FeatureGatingType

    private init(type: FeatureGatingType) { featureType = type }
}

// MARK: public methods
public extension FeatureGatingManager {
    struct Key: RawRepresentable, ExpressibleByStringLiteral {
        public init(stringLiteral value: String) { self.rawValue = value }
        public init?(rawValue: String) { self.rawValue = rawValue }

        public let rawValue: String
    }

    /// 静态FG获取单例
    static let shared = FeatureGatingManager(type: .static)
    /// 实时FG获取单例
    static let realTimeManager = FeatureGatingManager(type: .dynamic)

    /// 当前用户id
    static var currentChatterID: (() -> String) = { "" }
    
    /// 指定用户所有静态且固化的FG
    static func immutableFeatures(of id: String) -> [String: Bool] { FeatureGatingStorage.immutableFeatures(of: id) }

    /// 指定用户所有动态的FG
    static func mutableFeatures(of id: String) -> Set<String> { FeatureGatingStorage.mutableFeatures(of: id) }

    /// 用户online/offline
    static func userStateDidChange(isOnline: Bool, of userID: String) {
        FeatureGatingStorage.changeSyncStrategy(enable: isOnline, of: userID)
    }

    /// FG更新的信号
    var fgCombineSubjectPublisher: AnyPublisher<Void, Never> {
        FeatureGatingStorage.fgCombineSubject
            .filter { $0.0 == Self.currentChatterID() && $0.1 == self.featureType }.map { _ in }.eraseToAnyPublisher()
    }
    /// FG更新的信号
    var fgObservable: Observable<Void> {
        FeatureGatingStorage.fgRxSubject.filter { $0.0 == Self.currentChatterID() && $0.1 == self.featureType }
            .map { _ in }.asObservable()
    }

    /// 根据type取FG的值，优先返回debug页面修改的值，其次是内存缓存--磁盘缓存--打包内置
    ///
    /// - Parameters:
    ///   - key: FeatureGatingManager.Key，可传字符串字面量
    /// - Returns: FG的bool值
    ///
    /// ```swift
    /// let someFG = FeatureGatingManager.shared.featureGatingValue(with: "someKey")
    /// ```
    func featureGatingValue(with key: Key) -> Bool {
        return FeatureGatingStorage.featureValue(of: Self.currentChatterID(), key: key.rawValue, type: featureType)
    }

    ///  Key粒度监听可变的FG,  FG发生变更时, 向业务方推送最新的值
    /// - Parameters:
    ///     - key:FeatureGatingManager.Key, 可传入FG Key的字符串字面量
    /// - returns: 被监听的FG Key对应的观察者对象
    /// ```swift
    /// let ob = FeatureGatingManager.shared.observeKey(key: "xxx")
    ///     .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
    ///     .subscribe(onNext: { print($0) })
    /// ```
    @available(*, deprecated, message: "Use FeatureGatingService.observeKey instead")
    func observeKey(key: Key) -> Observable<Bool>? {
        return FeatureGatingStorage.observeKey(of: Self.currentChatterID(), key: key.rawValue)
    }
}
