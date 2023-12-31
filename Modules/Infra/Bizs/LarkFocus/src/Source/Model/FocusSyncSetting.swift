//
//  FocusSyncSetting.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2022/1/12.
//

import Foundation
import RustPB

/// 新版的个人状态同步设置 支持云端下发新的同步设置
/// ```
/// public struct FocusSyncSetting {
///     public var id: Int64 // 用于服务端识别不同的设置
///     public var settingType: SettingType // 用于客户端识别同步设置（暂时没用到）
///     public var content: String // i18n后的设置内容
///     public var explain: String  // i18n后的设置解释
///     public var isOpen: Bool // i18n后的设置解释
/// }
/// ```
/// 服务端下发的设置
/// ```
/// public enum SettingType: Int {
///     case unknown // = 0, 新增需要客户端识别的设置，旧版被兼容为UNKNOWN，设置不展示
///     case common // = 1, 服务端下发的普通设置，无需客户端上识别
///     case calendarMeeting // = 2, 日程会议设置，需要sdk识别上报日程会议（后续新增为需要客户端识别的设置）
/// }
/// ```
public typealias FocusSyncSetting = Contact_V1_CustomStatusSettingV2

extension FocusSyncSetting {

    /// 将个人状态中的 syncSetting 转换为用于更新的数据模型
    func toUpdater() -> Contact_V1_UpdateUserCustomStatusMeta.UpdateSynSettingsV2 {
        var updater = Contact_V1_UpdateUserCustomStatusMeta.UpdateSynSettingsV2()
        updater.id = self.id
        updater.isOpen = self.isOpen
        return updater
    }
}
