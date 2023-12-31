//
//  ChatterSettingAPI.swift
//  LarkSDKInterface
//
//  Created by chengzhipeng-bytedance on 2018/5/30.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import RustPB

public protocol ChatterSettingAPI {
    /// 获取用户通用设置
    /// - Returns: 1.通知栏是否显示消息详情状态，2.是否已经设置了不再显示提醒拨打电话警告
    func fetchRemoteSetting(strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<(Bool, Bool, Bool)>

    /// 更新通知栏是否显示消息详情状态
    ///
    /// - Parameter status: 通知栏是否显示消息详情状态
    ///
    func updateRemoteSetting(showNotifyDetail: Bool) -> Observable<Void>

    /// 更新是否在拨打电话前弹出提示
    ///
    /// - Parameter status: 更新是否在拨打电话前弹出提示
    ///
    func updateRemoteSetting(showPhoneAlert: Bool) -> Observable<Void>

    /// 更新手机消息通知状态
    ///
    /// - Parameter
    ///  - notifyEnabled: 手机通知是否开启
    ///
    /// - Returns: 是否更新成功
    func updateNotificationStatus(notifyDisable: Bool) -> Observable<Bool>

    /// 更新手机消息通知状态
    ///
    /// - Parameter
    ///  - notifyAtEnabled: 手机通知关闭时候，是否仍然通知@消息
    ///
    /// - Returns: 是否更新成功
    func updateNotificationStatus(notifyAtEnabled: Bool) -> Observable<Bool>

    /// 更新手机消息通知状态
    ///
    /// - Parameter
    ///  - notifyAtEnabled: 手机通知关闭时候，是否仍然通知星标联系人的消息
    ///
    /// - Returns: 是否更新成功
    func updateNotificationStatus(notifySpecialFocus: Bool) -> Observable<Bool>

    /// 更新手机消息通知声音
    ///
    /// - Parameter
    ///  - item: 手机通知声音
    ///
    /// - Returns: 是否更新成功
    func updateNotificationStatus(items: [Basic_V1_NotificationSoundSetting.NotificationSoundSettingItem]) -> Observable<Bool>
}

public typealias ChatterSettingAPIProvider = () -> ChatterSettingAPI
