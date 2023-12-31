//
//  GroupBotListPageCellViewModel.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/23.
//

import LKCommonsLogging

/// 「群机器人」cell的viewModel
class GroupBotListPageCellViewModel {
    /// 原始数据
    let data: GroupBotModel

    init(dataModel: GroupBotModel) {
        self.data = dataModel
    }

    /// 根据业务场景，获取title栏内容
    func getTitleText() -> String {
        return data.name ?? ""
    }

    /// 根据业务场景，获取描述栏内容
    func getDescText() -> String {
        return data.description ?? ""
    }
}
