//
//  FocusPickerOption.swift
//  LarkFocus
//
//  Created by 白镜吾 on 2023/1/9.
//

import UIKit
import Foundation
import LarkMention

struct FocusPickerOption: PickerOptionType {
    var id: String

    var type: LarkMention.PickerOptionItemTyle

    var meta: LarkMention.MentionMeta?

    var isEnableMultipleSelect: Bool = false

    var isMultipleSelected: Bool = false

    var avatarID: String?

    var avatarKey: String?

    var name: NSAttributedString?

    var subTitle: NSAttributedString?

    var desc: NSAttributedString?

    var tags: [LarkMention.PickerOptionTagType]?
}


