//
//  LarkInterface+FeatureGating.swift
//  LarkInterface
//
//  Created by Meng on 2019/8/19.
//  Copyright © 2019年 Bytedance.Inc. All rights reserved.
//

import Foundation
import ThreadSafeDataStructure
/// https://bytedance.feishu.cn/space/doc/doccnucrmtZ33GK6SvqMi3VaIvb

public typealias SwitchHandler = () -> Void

/// Feature定义，凡是在部署态有多种落地形态的Feature在此处定义。
/// 随着iPhone和iPad产品迭代，各个业务Owner共同维护此表，直至iPhone与iPad业务对齐。
///
/// 如：calendarTab在iPhone上显示，在iPad上未适配，因此不显示
///
public enum Feature: Int, CaseIterable {
    /// iPhone&iPad scene默认关闭
    /// 需要调试适配的，从「高级调试」->「FeatureSwitch打开」
    case scene

    case threadTab
    case calendarTab
    case microAppTab
    case webAppTab
    case gadgetAppTab
    case mailTab
    case wikiTab
    case allPinTab
    case videoConferenceTab

    // onboarding: launchguide & tour
    case onboarding

    // feed
    case feedGuide                      // feed 引导

    /// 系统设置
    case sysSettingAccountSafey

    ///  快捷搜索过滤
    case searchFilter

    /// 搜索中的 profile 按钮
    case searchProfile

    /// contact
    case contactSelection

    /// trace打印userInterfaceIdiom
    case tracerUserInterfaceIdiom

    /// 加密通话
    case voip

    /// 手机通话
    case phoneCall

    /// 服务台小程序入口
    case oncallMiniProgram

    /// 加密通话消息(Chat & Feed)
    case voipMessage

    /// 拨打电话消息(Chat & Feed)
    case phoneCallMessage

    /// 小程序 相关
    case microApp

    /// 投票 入口
    case vote

    /// 机器人详情页面
    case appDetail

    public static func on(_ feature: Feature) -> FeatureApplyer {
        return FeatureApplyer(feature: feature)
    }

}

extension Feature {

    /// 策略表，用于标识Feature具体的落地策略
    ///
    /// ```
    ///     .xxxFeature: .off,                                      // 全关
    ///     .xxxFeature: .apply(phone: .on, others: .off)           // iPhone开，其他关
    ///     .xxxFeature: .apply(pad: .downgraded, others: .on)      // iPad降级，其他开
    /// ```
    ///
    public static var applyConfigs: SafeDictionary<Feature, ApplyConfig> = [
        .scene: .off,
        .threadTab: .apply(phone: .on, others: .off),
        .calendarTab: .apply(phone: .on, others: .on),
        .microAppTab: .apply(phone: .on, others: .off),
        .webAppTab: .apply(phone: .on, others: .off),
        .gadgetAppTab: .apply(phone: .on, others: .off),
        .mailTab: .on,
        .wikiTab: .apply(phone: .on, others: .off),
        .videoConferenceTab: .apply(phone: .on, others: .off),
        .onboarding: .apply(phone: .on, pad: .on, others: .off),
        .feedGuide: .apply(phone: .on, others: .off),
        .sysSettingAccountSafey: .apply(phone: .on, others: .on),
        .searchFilter: .apply(phone: .on, others: .on),
        .searchProfile: .apply(phone: .on, others: .on),
        .tracerUserInterfaceIdiom: .apply(pad: .on, others: .off),
        .contactSelection: .apply(phone: .off, others: .on),
        .voip: .apply(phone: .on, others: .off),
        .phoneCall: .apply(phone: .on, others: .off),
        .oncallMiniProgram: .apply(pad: .downgraded, others: .on),
        .voipMessage: .apply(pad: .downgraded, others: .on),
        .phoneCallMessage: .apply(pad: .downgraded, others: .on),
        .microApp: .apply(pad: .downgraded, others: .on),
        .vote: .apply(phone: .on, others: .off),
        .appDetail: .apply(pad: .downgraded, others: .on),
        .allPinTab: .apply(phone: .on, others: .off)
    ] + .readWriteLock
}

// swiftlint:disable missing_docs
public struct FeatureApplyer {

    public let feature: Feature

    /// 落地逻辑,注意落地的block必须与策略表严格对应，否则会assert
    ///
    /// 使用方法：
    /// ```
    ///     Feature.on(.calendarTab).apply(on: {
    ///         // on for iPhone
    ///     }, off: {
    ///         // off for iPad
    ///     })
    /// ```
    ///
    /// - Parameters:
    ///   - on: 开策略
    ///   - off: 关策略
    ///   - downgraded: 降级策略
    public func apply(on: SwitchHandler? = nil, off: SwitchHandler? = nil, downgraded: SwitchHandler? = nil) {
        var applyOn = Feature.applyConfigs[feature] == .on
        var applyOff = Feature.applyConfigs[feature] == .off
        var applyDowngraded = Feature.applyConfigs[feature] == .downgraded

        // 如果有设置过debug开关，替换现有配置
        if let config = FeatureSwitchDebug.getFeatureFromDebug(feature: feature) {
            applyOn = false
            applyOff = false
            applyDowngraded = false
            switch config {
            case .on: applyOn = true
            case .off: applyOff = true
            case .downgraded: applyDowngraded = true
            }
        }

        assert(applyOn && on != nil || !applyOn, "Check your Feature applyConfigs.")
        assert(applyOff && off != nil || !applyOff, "Check your Feature applyConfigs.")
        assert(applyDowngraded && downgraded != nil || !applyDowngraded, "Check your Feature applyConfigs.")

        if applyOn {
            on?()
        }
        if applyOff {
            off?()
        }
        if applyDowngraded {
            downgraded?()
        }
    }

}
// swiftlint:enable missing_docs
