//
//  ConfigurationProxy.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/10/9.
//

import Foundation
import RxSwift
import RustPB
import LarkAppConfig

public protocol ConfigurationProxy {
    /// 获取免打扰提醒样式
    func getAndReviseBadgeStyle() -> (Observable<RustPB.Settings_V1_BadgeStyle>, Observable<RustPB.Settings_V1_BadgeStyle>)

    /// 根据业务获取domain
    func getDomainSetting(key: InitSettingKey) -> [String]
    
    /// 获取是否24小时制
    var is24HourTime: Bool { get }

    /// 获取是否飞书品牌（否则是Lark）
    var isFeishuBrand: Bool { get }
}
