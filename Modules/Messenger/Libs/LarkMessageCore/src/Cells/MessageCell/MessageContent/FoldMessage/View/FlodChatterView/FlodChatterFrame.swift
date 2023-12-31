//
//  FlodChatterFrame.swift
//  LarkMessageCore
//
//  Created by Bytedance on 2022/9/23.
//

import Foundation
import UIKit

/// 每个Chatter的frame、头像、名字、数字的frame；全部相对于整个视图而言
struct FlodChatterFrame {
    static var numberLabelFont = UIFont(name: "DINAlternate-Bold", size: 14) ?? UIFont.systemFont(ofSize: 14)
    var contentFrame: CGRect = .zero
    private(set) var avatarFrame: CGRect = .zero
    private(set) var nameFrame: CGRect = .zero
    private(set) var numberFrame: CGRect = .zero

    /// 布局头像、名字、数字size；确认contentFrame
    mutating func layoutAvatarAndNameAndNumberSize(chatter: FlodChatter, limitSize: CGSize) {
        // 计算指定内容占用的宽高，计算时不做宽高约束，和reaction的计算保持一致
        func textSize(text: String, font: UIFont) -> CGSize {
            return NSString(string: text).boundingRect(with: .zero, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil).size
        }

        // 计算Chatter头像、名字、数量各自占用的size
        // 得到展示头像占用的size
        self.avatarFrame.size = CGSize(width: 20, height: 20)

        // 得到展示数量占用的size
        if chatter.number > 1 { self.numberFrame.size = textSize(text: "×\(chatter.number)", font: Self.numberLabelFont) }

        // 得到展示名字占用的size
        var nameSize = textSize(text: chatter.name, font: UIFont.systemFont(ofSize: 12))
        // 名字的size.width有长度限制，不能超过一行
        var nameLimitWidth: CGFloat = limitSize.width - self.avatarFrame.size.width - intervalBetweenAvatarAndName
        if chatter.number > 1 { nameLimitWidth -= (self.numberFrame.size.width + intervalBetweenNameAndNumber) }
        nameSize.width = min(nameSize.width, nameLimitWidth)
        self.nameFrame.size = nameSize

        // 得到展示整个Chatter占用的size
        // width
        self.contentFrame.size.width = self.avatarFrame.size.width + intervalBetweenAvatarAndName
        self.contentFrame.size.width += self.nameFrame.size.width
        if chatter.number > 1 { self.contentFrame.size.width += (self.numberFrame.size.width + intervalBetweenNameAndNumber) }
        // height
        self.contentFrame.size.height = max(self.avatarFrame.size.height, self.nameFrame.size.height)
        self.contentFrame.size.height = max(self.contentFrame.size.height, self.numberFrame.size.height)
    }

    /// 调整头像、名字、数字frame；contentFrame确认后调用
    mutating func adjustAvatarAndNameAndNumberFrame() {
        // 头像
        self.avatarFrame.origin.x = self.contentFrame.origin.x
        self.avatarFrame.origin.y = self.contentFrame.origin.y + (self.contentFrame.size.height - self.avatarFrame.size.height) / 2
        // 名称
        self.nameFrame.origin.x = self.avatarFrame.maxX + intervalBetweenAvatarAndName
        self.nameFrame.origin.y = self.contentFrame.origin.y + (self.contentFrame.size.height - self.nameFrame.size.height) / 2
        // 数量
        self.numberFrame.origin.x = self.nameFrame.maxX + intervalBetweenNameAndNumber
        self.numberFrame.origin.y = self.contentFrame.origin.y + (self.contentFrame.size.height - self.numberFrame.size.height) / 2
    }
}
