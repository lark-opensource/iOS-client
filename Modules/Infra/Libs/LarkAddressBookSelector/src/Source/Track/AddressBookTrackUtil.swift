//
//  AddressBookTrackUtil.swift
//  LarkAddressBook
//
//  Created by zhenning on 2020/08/11.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import Homeric
import LKCommonsTracker
import LarkPerf
import AppReciableSDK

typealias ABSTracker = AddressBookTrackUtil

final class AddressBookTrackUtil {

    /// 读取到的 cp 数量 (email + phonenumber)，在任何校验、过滤、限制前的数量
    static func trackFetchCPTotalCountRaw(count: Int) {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_CP_TOTAL_COUNT,
                                  metric: ["count": count], category: [:], extra: [:]))
    }

    /// 读取到的 email 数量，在任何校验、过滤、限制前的数量
    static func trackFetchEmailCountRaw(count: Int) {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_CP_EMAIL_COUNT,
                                  metric: ["count": count], category: [:], extra: [:]))
    }

    /// 读取到的 phonenumber 数量，在任何校验、过滤、限制前的数量
    static func trackFetchPhoneCountRaw(count: Int) {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_CP_PHONE_COUNT,
                                  metric: ["count": count], category: [:], extra: [:]))
    }

    /// 开始 读取通讯录的时间耗时时长 (ms)
    static func trackStartContactLocalFetchTimingMs() {
        ClientPerf.shared.startSlardarEvent(service: Homeric.CONTACT_OPT_LOCAL_FETCH_TIMING_MS)
    }

    /// 结束 读取通讯录的时间耗时时长 (ms)
    static func trackEndContactLocalFetchTimingMs() {
        ClientPerf.shared.endSlardarEvent(service: Homeric.CONTACT_OPT_LOCAL_FETCH_TIMING_MS)
    }

    /// 开始 读取通讯录的时间耗时时长 (ms)
    static func trackStartAppReciableContactLocalFetchTimingMs() -> DisposedKey {
        return AppReciableSDK.shared.start(biz: .UserGrowth,
                                           scene: .UGCenter,
                                           event: .contactOptLocalFetch,
                                           page: nil)
    }

    /// 结束 读取通讯录的时间耗时时长 (ms)
    static func trackEndAppReciableContactLocalFetchTimingMs(disposedKey: DisposedKey) {
        AppReciableSDK.shared.end(key: disposedKey)
    }

    /// 通讯录系统授权弹窗出现，用户点击「允许」
    static func trackContactPermissionAllow() {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_PERMISSION_ALLOW,
                                  metric: [:], category: [:], extra: [:]))
    }

    /// 通讯录系统授权弹窗出现，用户点击「拒绝」
    static func trackContactPermissionDeny() {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_PERMISSION_DENY,
                                  metric: [:], category: [:], extra: [:]))
    }

    /// 通讯录提示用户前往系统设置授权弹窗出现，用户点击「取消」
    static func trackContactPermissionSettingsCancel() {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_PERMISSION_SETTINGS_CANCEL,
                                  metric: [:], category: [:], extra: [:]))
    }

    /// 通讯录提示用户前往系统设置授权弹窗出现，用户点击「前往」
    static func trackContactPermissionSettingsJump() {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_PERMISSION_SETTINGS_JUMP,
                                  metric: [:], category: [:], extra: [:]))
    }
}

// MARK: - Onboarding

extension AddressBookTrackUtil {
    /// 小B用户走完spolight流程后，系统弹出通讯录弹窗
    static func trackOnbardingSystemAddressRequstShow() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_SYSTEM_ADDRESSREQUEST_SHOW, params: ["category": "LarkAddressBookSelector"]))
    }
    /// 小B用户走完spolight流程后，系统弹出通讯录弹窗，用户选择授权
    static func trackOnbardingSystemAddressRequestAgree() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_SYSTEM_ADDRESSREQUEST_AGREE, params: ["category": "LarkAddressBookSelector"]))
    }
    /// 小B用户走完spolight流程后，系统弹出通讯录弹窗，用户选择不授权
    static func trackOnbardingSystemAddressRequestDisagree() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_SYSTEM_ADDRESSREQUEST_DISAGREE, params: ["category": "LarkAddressBookSelector"]))
    }

    /// Metrics
    /// Onboarding 流程中，通讯录系统授权弹窗出现
    static func trackMetricOnbardingSystemAddressRequstShow() {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_ONBOARDING_PERMISSION_SHOW,
                                  metric: [:], category: [:], extra: [:]))
    }
    /// Onboarding 流程中，通讯录系统授权弹窗出现，用户点击「允许」
    static func trackMetricOnbardingSystemAddressRequestAllow() {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_ONBOARDING_PERMISSION_ALLOW,
                                  metric: [:], category: [:], extra: [:]))
    }
    /// Onboarding 流程中，通讯录系统授权弹窗出现，用户点击「拒绝」
    static func trackMetricOnbardingSystemAddressRequestDeny() {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_ONBOARDING_PERMISSION_DENY,
                                  metric: [:], category: [:], extra: [:]))
    }

}
