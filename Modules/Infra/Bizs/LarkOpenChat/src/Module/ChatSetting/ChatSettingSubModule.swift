//
//  ChatSettingSubModule.swift
//  LarkOpenChat
//
//  Created by JackZhao on 2021/8/24.
//

import UIKit
import Foundation
import LarkOpenIM

/// 复写方法时，记得先调用super
open class ChatSettingSubModule: Module<ChatSettingContext, ChatSettingMetaModel> {
    open func createItems(model: ChatSettingMetaModel) { }

    // 所有cell的vm集合
    open var items: [ChatSettingCellVMProtocol] = []

    // 所有cell的类型字典
    open var cellIdToTypeDic: [String: UITableViewCell.Type]? { nil }

    // 所有搜索items的工厂
    open var searchItemFactoryTypes: [ChatSettingSerachDetailItemsFactory.Type]? { nil }

    // 所有应用items的工厂
    open var fuctionItemFactoryTypes: [ChatSettingFunctionItemsFactory.Type]? { nil }

    // 是否是可感知耗时
    open var isAppreciable: Bool {
        return false
    }
}
