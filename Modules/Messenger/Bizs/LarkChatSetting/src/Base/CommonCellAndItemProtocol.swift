//
//  CommonCellAndItemProtocol.swift
//  LarkChatSetting
//
//  Created by Crazy凡 on 2020/6/28.
//

import Foundation
import LarkOpenChat
import UIKit

// ChatSetting Module不再抽象任何模型，这里对于LarkOpenChat定义的基础类型做一次桥接，来减少代码的改动
typealias SeparaterStyle = ChatSettingSeparaterStyle
typealias CommonCellItemProtocol = ChatSettingCellVMProtocol
typealias CommonCellItemType = ChatSettingCellType
typealias CommonItemStyleFormat = ChatSettingCellStyleFormat
typealias CommonCellProtocol = ChatSettingCellProtocol
typealias CommonSectionModel = ChatSettingSectionModel
typealias CommonDatasource = [CommonSectionModel]
