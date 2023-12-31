//
//  ChatSettingLabelModel.swift
//  LarkFeedPlugin
//
//  Created by aslan on 2022/4/19.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkMessengerInterface

typealias ChatSettingLabelTapHandler = (_ cell: UITableViewCell) -> Void

struct ChatSettingLabelModel: ChatSettingCellVMProtocol {
    var type: ChatSettingCellType
    var cellIdentifier: String
    var style: ChatSettingSeparaterStyle
    var title: String
    var labels: [String]
    var tapHandler: ChatSettingLabelTapHandler

    init(type: ChatSettingCellType,
         cellIdentifier: String,
         style: ChatSettingSeparaterStyle,
         title: String,
         labels: [String],
         tapHandler: @escaping ChatSettingLabelTapHandler) {
        self.type = type
        self.cellIdentifier = cellIdentifier
        self.style = style
        self.title = title
        self.labels = labels
        self.tapHandler = tapHandler
    }
}
