//
//  TrackService+ABTest.swift
//  AFgzipRequestSerializer
//
//  Created by 李晨 on 2019/12/5.
//

import Foundation
import RangersAppLog
import RxSwift
import ThreadSafeDataStructure
import LarkAppLog

// swiftlint:disable missing_docs

extension TrackService {
    // MARK: A/B Test
    /*
     userInfo
     @{ kBDAutoTrackNotificationAppID           :appID,
        kBDAutoTrackNotificationData            :data,
     };
     通知在子线程，每次触发注册成功后，且该 App ID 配置了 ABTest 功能，会触发 ABTest 配置拉取。
     收到通知成功后，则可以开始读取 ABTest 值，如果未收到通知，则读取的 ABTest 为上次拉取成功的值。
     这里重点说明不需要去解析data的结构，简单check一下data.count == 0 即可
    */
    public func addPullABTestConfigObserve(observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(
            observer,
            selector: selector,
            name: NSNotification.Name(rawValue: BDAutoTrackNotificationABTestSuccess),
            object: nil
        )
    }

    /// 读取 ab_version
    public var abVersions: String { LarkAppLog.shared.tracker.abVids() ?? "" }

    /// 读取所有的 ab_version
    public var allAbVersions: String { LarkAppLog.shared.tracker.allAbVids() ?? "" }

    /// 获取某一个实验配置 value
    public func abTestValue(key: String, defaultValue: Any) -> Any? {
        LarkAppLog.shared.tracker.abTestConfigValue(forKey: key, defaultValue: defaultValue)
    }

    /*
     读取所有配置
     注意，此接口仅仅用于获取所有配置，调用此接口不会触发曝光和统计；
     如果是正常读取，请调用读取实验配置Value的接口。
    */
    public var allABTestConfigs: [AnyHashable: Any] { LarkAppLog.shared.tracker.allABTestConfigs() ?? [:] }

    /*
     设置日志上报 ABTest 属性
     支持外部获取 A/B 配置，然后通过这个接口将对应曝光执行存储和上报
    */
    public func setABSDKVersions(versions: String?) { LarkAppLog.shared.tracker.setExternalABVersion(versions) }

    /// 获取请求 A/B 实验配置的公共参数(详见 BDAutoTrackParamters.h)
    public func commonABExpParams(appId: String) -> [AnyHashable: Any] {
        bd_requestPostHeaderParameters(appId) as? [AnyHashable: Any] ?? [:]
    }
}
