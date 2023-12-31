//
//  PadToolBarReactionView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/9/2.
//

import UIKit

class PadToolBarReactionView: PadToolBarItemView {
    private static let reactionSpace: CGFloat = 8
    var reactions: [ReactionView] = []
    var reactionHiddenMasks: [Bool] = []
    private var allowSendReaction = true

    var reactionItem: ToolBarReactionItem? {
        item as? ToolBarReactionItem
    }

    override var itemWidth: CGFloat {
        guard let item = reactionItem else { return 0 }
        let showingReactions = item.allowSendReaction ? reactions.filter { !$0.isHidden } : []
        let reactionWidth = showingReactions.map { $0.intrinsicContentSize.width + Self.reactionSpace }.reduce(0, +)
        let space = CGFloat(showingReactions.count) * Self.reactionSpace
        let buttonWidth: CGFloat = showingReactions.isEmpty ? 40 : 44
        return reactionWidth + space + buttonWidth
    }

    override func setupSubviews() {
        super.setupSubviews()
        layer.cornerRadius = 8
        layer.masksToBounds = true
        button.layer.cornerRadius = 0
        button.vc.setBackgroundColor(.clear, for: .normal)

        guard let reactionItem = item as? ToolBarReactionItem else { return }
        reactions = reactionItem.showingReactions.map {
            let view = ReactionView()
            view.emotion = item.meeting.service.emotion
            view.delegate = reactionItem
            view.reactionKey = $0
            if $0.lowercased().contains("thumbsup") {
                view.verticalInset = -0.5
            }
            return view
        }
        reactionHiddenMasks = .init(repeating: false, count: reactions.count)
        for view in reactions {
            addSubview(view)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(toolbarDidFinishLayout), name: .padToolBarFinishedLayout, object: nil)
    }

    override func bind(item: ToolBarItem) {
        super.bind(item: item)
        guard let reactionItem = reactionItem else { return }
        for (i, view) in reactions.enumerated() {
            view.isHidden = !reactionItem.allowSendReaction || reactionHiddenMasks[i]
            view.reactionKey = reactionItem.showingReactions[i]
        }
        if allowSendReaction != reactionItem.allowSendReaction {
            allowSendReaction = reactionItem.allowSendReaction
            superview?.setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        var x: CGFloat = 0
        if reactionItem?.allowSendReaction == true {
            for view in reactions where !view.isHidden {
                let size = CGSize(width: view.intrinsicContentSize.width + Self.reactionSpace, height: view.intrinsicContentSize.height + Self.reactionSpace)
                view.frame = CGRect(x: x + Self.reactionSpace, y: (bounds.height - size.height) / 2 + view.verticalInset, width: size.width, height: size.height)
                x += size.width + Self.reactionSpace
            }
        }

        button.frame = CGRect(x: x, y: 0, width: x == 0 ? 40 : 44, height: bounds.height)
        iconView.frame.size = Self.iconSize
        iconView.center = CGPoint(x: button.frame.width / 2, y: button.frame.height / 2)
    }

    override func collapseStep() -> Bool {
        if reactionItem?.allowSendReaction == false {
            return true
        }

        if let last = reactions.lastIndex(where: { !$0.isHidden }) {
            reactionHiddenMasks[last] = true
            reactions[last].isHidden = true
            return false
        }
        return true
    }

    override func reset() {
        super.reset()
        reactionHiddenMasks = .init(repeating: false, count: reactions.count)
        reactions.forEach { $0.isHidden = reactionItem?.allowSendReaction == false }
    }

    override func meetingLayoutStyleDidChange(_ layoutStyle: MeetingLayoutStyle) {
        if layoutStyle == .tiled {
            backgroundColor = UIColor.ud.vcTokenMeetingBtnBgToolbar
        } else {
            backgroundColor = UIColor.ud.N900.withAlphaComponent(0.06)
        }
    }

    @objc private func toolbarDidFinishLayout() {
        reactionItem?.updateViewHidden(![.left, .center, .right].contains(item.actualPadLocation))
        setNeedsLayout()
    }
}
