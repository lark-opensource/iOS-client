//
//  ReactionTagFactory.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2019/9/9.
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
    // default values not used
    weak var delegate: ReactionViewDelegate?
    var reaction: Reaction = Reaction(type: "", chatterIds: [], chatterCount: 0)
    var userIDs: [String] = []
    var userNameWidths: [CGFloat] = []
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
            tag.iconRect = layout.iconRect
            tag.separatorRect = layout.separatorRect
            tag.nameRect = layout.nameRect
            /// model
            tag.delegate = model.delegate
            /// copy reaction
            let reaction = Reaction(type: model.reaction.type, chatterIds: model.reaction.chatterIds, chatterCount: model.reaction.chatterCount)
            reaction.chatters = model.reaction.chatters
            tag.reaction = reaction
            tag.userIDs = model.userIDs
            tag.userNameWidths = model.userNameWidths
            tag.font = model.font
            tag.userNamesText = model.userNamesText
            tag.textColor = model.textColor
            tag.tagBgColor = model.tagBgColor
            tag.separatorColor = model.separatorColor
            return tag
        })
    }
}
