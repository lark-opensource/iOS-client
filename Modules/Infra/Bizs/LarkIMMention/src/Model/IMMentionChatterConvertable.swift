//
//  IMMentionChatterConvertable.swift
//  LarkIMMention
//
//  Created by Yuri on 2023/1/9.
//

import UIKit
import Foundation
import RustPB

protocol IMMentionChatterConvertable {
    typealias Chatter = Basic_V1_Chatter
    var currentTenantId: String { get }
    func convert(chatter: Chatter, isInChat: Bool) -> IMMentionOptionType
}

extension IMMentionChatterConvertable {
    func convert(chatter: Chatter, isInChat: Bool) -> IMMentionOptionType {
        var item = IMPickerOption()
        item.tags = []
        item.id = chatter.id
        item.type = .chatter
        item.focusStatus = chatter.status
        item.name = NSAttributedString(string: chatter.name)
        if !chatter.alias.isEmpty {
            item.name = NSAttributedString(string: chatter.alias)
        }
        item.actualName = chatter.localizedName
        item.avatarID = chatter.id
        item.avatarKey = chatter.avatarKey
        item.desc = NSAttributedString(string: chatter.description_p.text)
        if chatter.workStatus.status == .onLeave { item.tags?.append(.onLeave) }
        if chatter.tenantID != self.currentTenantId { item.tags?.append(.external) }
        if chatter.type == .bot { item.tags?.append(.robot) }
        if !chatter.isRegistered { item.tags?.append(.unregistered) }
        item.isInChat = isInChat
        item.tagData = chatter.tagInfo
        return item
    }
}
