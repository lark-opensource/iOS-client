//
//  ReactionView.swift
//  LarkThread
//
//  Created by qihongye on 2019/2/25.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import LarkUIKit

public protocol ReactionViewDelegate: AnyObject {
    /// 点击类reaction上面的UI触发
    /// - Parameters:
    ///   - reaction: 点击哪个类型的reaction
    ///   - tapType: 点击的reaction的部分
    func reactionDidTapped(_ reaction: Reaction, tapType: ReactionActionType)

    /// 需要补偿的reaction数量 一些场景下可能不会传入所有的reaction
    /// 需要根据缺少的数量 重新计算一下，不需要的话，直接返回nil
    /// - Parameter reaction: 需要补偿数量的 reaction
    func reactionAbsenceCount(_ reaction: Reaction) -> Int?

    /// 根据需要扩充reaction icon的点击区域
    func reactionTagIconActionAreaEdgeInsets() -> UIEdgeInsets?

    /// reaction最多展示几个 默认展示5个, 业务可以根基不同的reaction定制
    func maxReactionDisplayCount(_ reaction: Reaction) -> Int

    /// reaction只展示数量不展示名字
    func justShowCountFor(reaction: Reaction) -> Bool

    /// 不需要达到最大数量 也会去读取补偿的书reaction数量 比如3 +...5个人
    func forceShowMoreAbsenceCount(reaction: Reaction) -> Bool
}

public extension ReactionViewDelegate {
    func maxReactionDisplayCount(_ reaction: Reaction) -> Int { return 5 }
    func justShowCountFor(reaction: Reaction) -> Bool { return false }
    func forceShowMoreAbsenceCount(reaction: Reaction) -> Bool { return false }
}
/// ReactionTagView需要的一切属性，由外部组装
struct ReactionTag {
    var frame: CGRect = .zero
    weak var delegate: ReactionViewDelegate?
    var reaction: Reaction = Reaction(type: "", chatterIds: [], chatterCount: 0)
    var userIDs: [String] = []
    var userNameWidths: [CGFloat] = []
    var iconRect: CGRect = .zero
    var separatorRect: CGRect = .zero
    var nameRect: CGRect = .zero
    // Default values not used.
    var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    var userNamesText: String = ""
    var textColor: UIColor = .clear
    var tagBgColor: UIColor = .clear
    var separatorColor: UIColor = .clear
}
/// 展示reactions的视图
public final class ReactionView: UIView {
    var tags: [ReactionTag] = []
    var identifier = ""
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isUserInteractionEnabled = true
    }

    func syncTagsToSubviews() {
        guard let subviews = self.subviews as? [ReactionTagView] else { return }
        var idx = 0
        while idx < self.tags.count && idx < subviews.count {
            subviews[idx].update(tag: self.tags[idx])
            idx += 1
        }
        for i in idx..<self.tags.count {
            self.addSubview(ReactionTagView(tag: self.tags[i]))
        }
        for i in idx..<subviews.count {
            subviews[i].removeFromSuperview()
        }
        self.subviews.forEach { view in
            if let view = view as? ReactionTagView {
                view.identifier = self.identifier
            }
        }
    }
}

/// 每个reaction对应的视图
final class ReactionTagView: UIView {
    /// icon、分割线、名字区域
    private let reactionView = ReactionImageView(frame: .zero)
    private let separator = UIView()
    private let namesLabel = UILabel(frame: .zero)
    /// reaction delegate
    private var reaction = Reaction(type: "", chatterIds: [], chatterCount: 0)
    private weak var delegate: ReactionViewDelegate?
    /// reaction所有点击者的id
    private var userIDs: [String] = []
    /// 记录显示前i个人的长度
    private var userNameWidths: [CGFloat] = []
    var identifier = ""

    init(tag: ReactionTag) {
        super.init(frame: .zero)
        self.isUserInteractionEnabled = true
        self.layer.cornerRadius = ReactionTagLayoutItem.Cons.totalHeight / 2
        self.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.8)
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowColor = UIColor.ud.staticBlack.withAlphaComponent(0.1).cgColor
        self.layer.shadowRadius = 2.5
        self.addSubview(self.reactionView)
        self.separator.backgroundColor = UIColor.ud.N400
        self.addSubview(self.separator)
        self.addSubview(self.namesLabel)
        self.update(tag: tag)
    }

    func update(tag: ReactionTag) {
        self.frame = tag.frame
        /// 属性赋值
        self.delegate = tag.delegate
        /// copy reaction
        let copyReaction = Reaction(type: tag.reaction.type, chatterIds: tag.reaction.chatterIds, chatterCount: tag.reaction.chatterCount)
        copyReaction.chatters = tag.reaction.chatters
        self.reaction = copyReaction
        self.userIDs = tag.userIDs
        self.userNameWidths = tag.userNameWidths
        /// icon
        self.reactionView.frame = tag.iconRect
        self.reactionView.set(height: tag.iconRect.height, type: copyReaction.type)
        /// 分割线
        self.separator.frame = tag.separatorRect
        self.separator.backgroundColor = tag.separatorColor
        /// 名字区域
        self.namesLabel.frame = tag.nameRect
        self.namesLabel.font = tag.font
        self.namesLabel.text = tag.userNamesText
        self.namesLabel.textColor = tag.textColor
        /// 背景
        self.backgroundColor = tag.tagBgColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func offsetAtUserNamesIdx(_ offset: CGFloat) -> Int {
        if offset < 0 { return -1 }
        let (before, _) = self.userNameWidths.lf_bsearch(offset, comparable: { Int($0) - Int($1) })
        return before + 1
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        /// tap icon
        var responseFrame = self.reactionView.frame
        if let insets = self.delegate?.reactionTagIconActionAreaEdgeInsets() {
            responseFrame = CGRect(
                x: responseFrame.minX - insets.left,
                y: responseFrame.minY - insets.top,
                width: responseFrame.width + insets.left + insets.right,
                height: responseFrame.height + insets.top + insets.bottom
            )
        }
        if responseFrame.contains(point) {
            let idStr = self.identifier
            self.reactionView.layer.lu.bounceAnimation(frames: [1, 1, 1, 0.8, 1], duration: 0.5, key: nil) { [weak self] in
                guard let `self` = self else { return }
                if self.identifier == idStr {
                    self.delegate?.reactionDidTapped(self.reaction, tapType: .icon)
                }
            }
            return
        }
        let offset = point.x - self.namesLabel.frame.minX
        let idx = self.offsetAtUserNamesIdx(offset)
        /// tap more
        if idx >= self.userNameWidths.count {
            self.delegate?.reactionDidTapped(self.reaction, tapType: .more)
            return
        }
        /// tap user，越界防护，空数组idx是0会造成越界
        if idx >= 0, idx < self.userIDs.count {
            self.delegate?.reactionDidTapped(self.reaction, tapType: .name(self.userIDs[idx]))
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
}
