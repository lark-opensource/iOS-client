//
//  PickerSearchItemInfo.swift
//  LarkSearchCore
//
//  Created by Yuri on 2022/11/16.
//

import UIKit
import Foundation

public struct PickerSearchItemInfo {
    enum ItemType: String {
        case unknown
        case chatter
        case department
    }

    var type: ItemType = .unknown
    var avatarId: String?
    var avatarKey: String
    var avatarImageURL: String?
    var avatarBackgroundImage: UIImage?
    var title: NSAttributedString
    var summary: NSAttributedString?

    var isDepartment: Bool {
        return type == .department
    }
    var isChatter: Bool {
        return type == .chatter
    }
}
