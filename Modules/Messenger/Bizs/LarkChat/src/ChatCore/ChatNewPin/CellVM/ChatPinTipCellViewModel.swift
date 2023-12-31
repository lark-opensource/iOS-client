//
//  ChatPinTipCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/11/7.
//

import Foundation

final class ChatPinTipCellViewModel: ChatPinCardContainerCellAbility {
    var identifier: String {
        return ChatPinListTipCell.reuseIdentifier
    }

    let title: String
    init(title: String) {
        self.title = title
    }

    func getCellHeight() -> CGFloat {
        return ChatPinListTipCell.height
    }
}
