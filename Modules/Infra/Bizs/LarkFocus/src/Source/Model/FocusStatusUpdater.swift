//
//  FocusStatusUpdater.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/10.
//

import Foundation
import RustPB
import LarkMessageBase

/// 修改个人状态的传参
///
/// 数据结构
/// ```
/// struct FocusStatusUpdater {
///     var id: Int64
///     var title: String
///     var iconKey: String
///     var effectiveInterval: FocusEffectiveTime
///     var isNotDisturbMode: Bool
///     var lastSelectedDuration: FocusDurationType
///     var lastCustomizedEndTime: Int64
///     var synSettings: Dictionary<Int64, Bool>
///     var fields: [UserCustomStatusField]
/// }
/// ```
///
/// 变更字段
/// ```
/// enum UserCustomStatusField {
///     case title
///     case iconKey
///     case isNotDisturbMode
///     case effectiveInterval
///     case lastSelectedDefaultDuration
///     case lastCustomizedEndTime
///     case synSettings
/// }
/// ```
public typealias FocusStatusUpdater = Contact_V1_UpdateUserCustomStatusMeta

public extension FocusStatusUpdater {

    static func assemble(old: UserFocusStatus, new: UserFocusStatus) -> FocusStatusUpdater? {
        guard old.id == new.id else {
            return nil
        }
        var updater = FocusStatusUpdater()
        updater.id = old.id
        if new.title != old.title {
            updater.title = new.title
            updater.fields.append(.title)
        }
        if new.iconKey != old.iconKey {
            updater.iconKey = new.iconKey
            updater.fields.append(.iconKey)
        }
        if !new.statusDesc.richText.isContentEqualTo(old.statusDesc.richText) {
           if new.statusDesc.hasRichText {
               updater.statusDesc = new.statusDesc.richText
           }
            updater.fields.append(.statusDesc)
        }
        if new.effectiveInterval != old.effectiveInterval {
            updater.effectiveInterval = new.effectiveInterval
            // isShowEndTime 只有服务端能设为 false，约定客户端上报均为 true
            updater.effectiveInterval.isShowEndTime = true
            updater.fields.append(.effectiveInterval)
        }
        if new.isNotDisturbMode != old.isNotDisturbMode {
            updater.isNotDisturbMode = new.isNotDisturbMode
            updater.fields.append(.isNotDisturbMode)
        }
        if new.lastSelectedDuration != old.lastSelectedDuration {
            updater.lastSelectedDuration = new.lastSelectedDuration
            updater.fields.append(.lastSelectedDefaultDuration)
        }
        if new.lastCustomizedEndTime != old.lastCustomizedEndTime {
            updater.lastCustomizedEndTime = new.lastCustomizedEndTime
            updater.fields.append(.lastCustomizedEndTime)
        }
        if new.settingsV2 != old.settingsV2 {
            updater.synSettingsV2 = new.settingsV2.map { $0.toUpdater() }
            updater.fields.append(.synSettingsV2)
        }
        return updater.fields.isEmpty ? nil : updater
    }
}
