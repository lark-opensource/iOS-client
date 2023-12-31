//
//  FilterFixedViewModel+DataHandler.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/8/18.
//

import Foundation

extension FilterFixedViewModel {
    // 作用: 处理 Get 和 Push 请求的结果
    // 目的: 1.处理服务端下发的固定分组栏默认展示状态; 2.做新老注册用户引导逻辑
    func updateFixedFilterSetting(_ settingModel: FeedThreeColumnSettingModel, isPushHandler: Bool) {
        if isPushHandler,
            settingModel.triggerScene == .createTag,
            settingModel.mobileShowEnable == false {
            // Push收到PC创建标签时的触发条件，不做后续响应直接触发set请求
            updateThreeColumnsSettings(scene: .createTag)
            return
        }

        filterSetting = settingModel
        if defaultShowFilter == nil {
            defaultShowFilter = settingModel.mobileShowEnable
        }

        // 处理默认展示状态
        filterSettingShowRelay.accept(settingModel.mobileShowEnable)
    }
}
