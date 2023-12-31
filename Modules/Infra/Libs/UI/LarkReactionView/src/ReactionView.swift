//
//  ReactionView.swift
//  LarkReactionView
//
//  Created by 李晨 on 2019/6/5.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor

public protocol ReactionViewDelegate: AnyObject {
    /// reaction点击开始
    func reactionBeginTap(_ reactionVM: ReactionInfo, tapType: ReactionTapType)
    /// reaction点击结束(动画完成)
    func reactionDidTapped(_ reactionVM: ReactionInfo, tapType: ReactionTapType)
    func reactionViewImage(_ reactionVM: ReactionInfo, callback: @escaping (UIImage) -> Void)
    func reactionViewDidOpenEntrance()
}

public extension ReactionViewDelegate {
    func reactionBeginTap(_ reactionVM: ReactionInfo, tapType: ReactionTapType) {
        print("reactionView begin tap, type:\(tapType)")
    }
    func reactionViewDidOpenEntrance() {
        print("reactionView DidOpenEntrance")
    }
}

public final class ReactionView: UIView {
    /// icon 动画时长
    public static var iconAnimationDuration = TimeInterval(0.5)

    static var reactionTagPool = ReuseableViewPool<ReactionTag>(count: 10)

    private lazy var tagView = TagView<ReactionTag>()
    public weak var delegate: ReactionViewDelegate?

    private var textColor: UIColor = UIColor.ud.N500 {
        didSet {
            if textColor == oldValue {
                return
            }

            for tag in tagView.tags {
                tag.textColor = textColor
            }
        }
    }

    public var tagBackgroundColor: UIColor = UIColor.ud.udtokenReactionBgGrey {
        didSet {
            if tagBackgroundColor == oldValue {
                return
            }
            for tag in tagView.tags {
                tag.backgroundColor = tagBackgroundColor
            }
        }
    }

    public var reactions: [ReactionInfo] = [] {
        didSet {
            tagView.setTags(buildReactionTags(reactions: reactions))
        }
    }

    public var preferMaxLayoutWidth: CGFloat {
        set {
            self.tagView.preferredMaxLayoutWidth = newValue
        }
        get {
            return self.tagView.preferredMaxLayoutWidth
        }
    }

    /// 设置reactions
    /// - Parameters:
    ///   - reactions: reaction数据
    ///   - showReactionOpenEntrance: 是否在面板最后显示Reaction点击入口
    ///   - reactionOpenEntranceImage: 面板最后显示Reaction点击入口图片(没有或空则使用默认)
    public func setReactionsData(reactions: [ReactionInfo], showReactionOpenEntrance: Bool = false, reactionOpenEntranceImage: UIImage? = nil) {
        var buildReactions = reactions
        buildReactions.removeAll { // 先移除可能存在的openEntrance
            $0.reactionKey == ReactionOpenEntrance.reactionKey
        }
        let hasOpenEntrance = showReactionOpenEntrance && !(buildReactions.isEmpty)
        if hasOpenEntrance {
            if let image = reactionOpenEntranceImage {
                ReactionOpenEntrance.reactionImage = image
            }
            let reactionInfo = ReactionInfo(reactionKey: ReactionOpenEntrance.reactionKey, users: [])
            reactionInfo.reactionSize = ReactionOpenEntrance.reactionSize
            buildReactions.append(reactionInfo)
        }
        self.reactions = buildReactions
    }

    /// 重置面板最后显示Reaction点击入口图片
    /// - Parameter image: 图片
    public func resetReactionOpenEntranceImage(_ image: UIImage) {
        guard let reactionTag = tagView.getTag(ReactionOpenEntrance.reactionKey) else { return }
        reactionTag.resetReactionView(image)
    }

    /// 移除面板最后Reaction点击入口
    public func removeReactionOpenEntrance() {
        guard let reactionTag = tagView.getTag(ReactionOpenEntrance.reactionKey) else { return }
        tagView.removeTag(reactionTag)
    }

    private func buildReactionTags(reactions: [ReactionInfo]) -> [ReactionTag] {
        let tags = ReactionView.reactionTagPool
            .getUseableViews(count: reactions.count, occupyed: (tagView.subviews as? [ReactionTag])!)
        tags.enumerated().forEach { (index, tag) in
            tag.tagDidOpenEntrance = { [weak self] in
                self?.delegate?.reactionViewDidOpenEntrance()
            }
            tag.tagDidTap = { [weak self] (tag, tapType) in
                self?.tapTagAtIndex(tag, tapType: tapType)
            }
            tag.tagBeginTap = { [weak self] (tag, tapType) in
                self?.beginTapTagAtIndex(tag, tapType: tapType)
            }
            tag.reactionImageFetcher = { [weak self] (model: ReactionInfo, callback: @escaping (UIImage) -> Void) in
                self?.delegate?.reactionViewImage(model, callback: callback)
            }
            tag.model = reactions[index]
            tag.backgroundColor = self.tagBackgroundColor
            tag.accessibilityIdentifier = "reaction.view.tag.\(index)"
        }

        return tags
    }

    public init() {
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    deinit {
        ReactionView.reactionTagPool.free(to: 10)
    }

    private func commonInit() {
        self.tagView.frame = CGRect.zero
        self.tagView.isUserInteractionEnabled = true
        self.tagView.accessibilityIdentifier = "reaction.view.tag.view"
        self.addSubview(self.tagView)
        self.tagView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(0)
            make.bottom.equalTo(0).priority(ConstraintPriority.high)
        }
        self.tagView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        reactions = []
    }

    private func tapTagAtIndex(_ tag: ReactionTag, tapType: ReactionTapType) {
        if let model = tag.model {
            self.delegate?.reactionDidTapped(model, tapType: tapType)
        }
    }

    private func beginTapTagAtIndex(_ tag: ReactionTag, tapType: ReactionTapType) {
        if let model = tag.model {
            self.delegate?.reactionBeginTap(model, tapType: tapType)
        }
    }
}
