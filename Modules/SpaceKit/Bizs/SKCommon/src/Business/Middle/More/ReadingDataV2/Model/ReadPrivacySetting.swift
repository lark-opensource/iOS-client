//
//  ReadPrivacySetting.swift
//  SKCommon
//
//  Created by peilongfei on 2023/11/30.
//  


import Foundation
import SKResource

enum ReadPrivacySetting {
    case showRecord(_ model: SwitchSettingModel)
    case showAvatar(_ model: SwitchSettingModel)

    var model: SwitchSettingModel? {
        switch self {
        case let .showRecord(model), let .showAvatar(model):
            return model
        }
    }
}

class SwitchSettingModel {
    let title: String
    let detail: String
    /// 获取或修改配置时，把这个属性名传给后端
    let property: String
    /// 用于排序
    let order: Int
    /// 打开埋点事件
    let openEvent: DocsDetailInfoReport.SettingViewClick
    /// 关闭埋点事件
    let closeEvent: DocsDetailInfoReport.SettingViewClick
    /// 开关的状态
    var isOn: Bool

    init(title: String, detail: String, property: String, order: Int, openEvent: DocsDetailInfoReport.SettingViewClick, closeEvent: DocsDetailInfoReport.SettingViewClick, isOn: Bool) {
        self.title = title
        self.detail = detail
        self.property = property
        self.order = order
        self.openEvent = openEvent
        self.closeEvent = closeEvent
        self.isOn = isOn
    }
}
