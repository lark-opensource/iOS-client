//
//  ReactionTagFactory.swift
//  Calendar
//
//  Created by pluto on 2023/1/15.
//

import UIKit
import Foundation
import LarkModel

/// 组装Tag，一种Tag对应一种reaction展示view
/// 展示view由两部分组成：layout + 内容，对应这里的Layout + Model
/// 如果出现不同的组装方式，比如view变了，那需要自己创建一个新实现类继承此类
class TagFactory<Model, Layout, Tag> {
    func createTags(_ array: [(Model, Layout)]) -> [Tag] { return [] }
}

// MARK: - ReactionTagFactory 针对ReactionTagView定制的Factory，产生ReactionTag
struct ReactionTagModel {
    var userIDs: [String] = []
    var userNameWidths: [CGFloat] = []
    var rsvpStatusType: ReplyStatus = .needsAction
    var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    var userNamesText: String = ""
    var textColor: UIColor = .clear
    var tagBgColor: UIColor = .clear
    var separatorColor: UIColor = .clear
}
/// 布局：[internal - icon - internal - 分割线 - internal - 名字区域 - internal]
struct ReactionTagLayout {
    var origin: CGPoint = .zero
    var contentSize: CGSize = .zero
    var frame: CGRect = .zero
    var iconRect: CGRect = .zero
    var separatorRect: CGRect = .zero
    var nameRect: CGRect = .zero
}
final class ReactionTagFactory: TagFactory<ReactionTagModel, ReactionTagLayout, ReactionTag> {
    override func createTags(_ array: [(ReactionTagModel, ReactionTagLayout)]) -> [ReactionTag] {
        return array.map({ (model, layout) -> ReactionTag in
            var tag = ReactionTag()
            /// layout
            tag.frame = CGRect(origin: layout.origin, size: layout.contentSize)
            tag.iconRect = FG.rsvpStyleOpt ? (model.rsvpStatusType == .needsAction ? .zero : layout.iconRect) : layout.iconRect
            tag.separatorRect = layout.separatorRect
            tag.nameRect = layout.nameRect
            /// model
            tag.userIDs = model.userIDs
            tag.userNameWidths = model.userNameWidths
            tag.font = model.font
            tag.userNamesText = model.userNamesText
            tag.textColor = model.textColor
            tag.tagBgColor = model.tagBgColor
            tag.separatorColor = model.separatorColor
            tag.rsvpStatusType = model.rsvpStatusType
            return tag
        })
    }
}
