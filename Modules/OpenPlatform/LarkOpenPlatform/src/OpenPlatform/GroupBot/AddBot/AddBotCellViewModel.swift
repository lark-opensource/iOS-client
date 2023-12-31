//
//  AddBotPageCellViewModel.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/9.
//

import Foundation
import LKCommonsLogging

/// 「添加机器人」cell的viewModel
class AddBotPageCellViewModel {
    /// 原始数据
    let data: AbstractBotModel
    /// 是否为推荐应用。true则显示「获取」 ，否则显示「添加」
    let isRecommended: Bool
    /// 是否「已添加」
    var isAdded: Bool {
        if data is GroupBotModel, let model = data as? GroupBotModel, let isInvited = model.isInvited, isInvited {
            return true
        }
        return false
    }
    var botImageEntityID: String? {
        if data is GroupBotModel, let groupBotModel = data as? GroupBotModel {
            return groupBotModel.botID
        }
        if data is RecommendBotModel, let recBotModel = data as? RecommendBotModel {
            return recBotModel.appID
        }
        return ""
    }
    /// 是否能够添加机器人到群
    var canAddToGroup: Bool {
        return !isRecommended && !isAdded
    }
    /// 是否为推荐机器人
    var canRecommendToGroup: Bool {
        return isRecommended
    }

    init(dataModel: AbstractBotModel, isRecommended: Bool) {
        self.data = dataModel
        self.isRecommended = isRecommended
    }

    /// 根据业务场景，获取title栏内容
    func getTitleText() -> String {
        return data.name ?? ""
    }

    /// 根据业务场景，获取描述栏内容
    func getDescText() -> String {
        return data.description ?? ""
    }

    /// 根据业务场景，获取按钮显示内容（获取 or 添加）
    func getButtonTitle() -> String {
        if canRecommendToGroup {
            return BundleI18n.GroupBot.Lark_GroupBot_Get
        }
        if isAdded {
            return BundleI18n.GroupBot.Lark_GroupBot_Added
        }
        return BundleI18n.GroupBot.Lark_GroupBot_Add
    }
}
