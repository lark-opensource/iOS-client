//
//  JoinAndLeaveItem.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/10/12.
//

import UIKit
import Foundation
import RichLabel

struct JoinAndLeaveItem {
    var id: String
    var chatterID: String
    var name: String
    var avatarKey: String
    var time: String
    var content: NSAttributedString
    var textLinks: [LKTextLink]?
    var isShowBoaderLine: Bool = true
}
