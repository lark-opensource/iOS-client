//
//  ReplyThreadInfoComponent.swift
//  LarkMessageCore
//
//  Created by JackZhao on 2022/4/25.
//

import Foundation
import UIKit
import EEFlexiable
import LarkBizAvatar
import AsyncComponent

public let ReplyThreadInfoComponentKey: String = "replyThreadInfoComponentKey"
public final class ReplyThreadInfoComponent<C: AsyncComponent.Context>: ASComponent<ReplyThreadInfoComponent.Props, EmptyState, TappedView, C> {

    public final class Props: ASComponentProps {
        var rowLayoutDirection: FlexDirection = .row
        var chatterModels: [ReplyThreadChatterModel] = []
        var attributedText: NSAttributedString?
        var onViewClicked: (() -> Void)?
    }

    public override init(props: ReplyThreadInfoComponent.Props, style: ASComponentStyle, context: C? = nil) {
        style.backgroundColor = .clear
        props.key = ReplyThreadInfoComponentKey
        super.init(props: props, style: style, context: context)
        setSubComponents([chatters, label])
        updateProps(props: props)
    }

    private lazy var chatters: DisplayChattersComponent<C> = {
        let props = DisplayChattersComponent<C>.Props()

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return DisplayChattersComponent(props: props, style: style)
    }()

    private lazy var label: RichLabelComponent<C> = {
        let props = RichLabelProps()

        let style = ASComponentStyle()
        style.marginLeft = 6
        style.marginRight = 6
        style.marginTop = 10
        style.backgroundColor = .clear
        return RichLabelComponent(props: props, style: style)
    }()

    public override func create(_ rect: CGRect) -> TappedView {
        return TappedView(frame: rect)
    }

    public override func update(view: TappedView) {
        super.update(view: view)

        if let tapped = self.props.onViewClicked {
            view.initEvent(needLongPress: false)
            view.onTapped = { _ in
                tapped()
            }
        } else {
            view.deinitEvent()
        }
        updateProps(props: props)
    }

    public override func willReceiveProps(_ old: ReplyThreadInfoComponent.Props, _ new: ReplyThreadInfoComponent.Props) -> Bool {
        updateProps(props: new)
        return true
    }

    private func updateProps(props: ReplyThreadInfoComponent.Props) {
        label.props.attributedText = props.attributedText
        chatters.props.chatterModels = props.chatterModels
    }
}

// 展示一串连续头像的组件
public final class DisplayChattersComponent<C: AsyncComponent.Context>: ASComponent<DisplayChattersComponent.Props, EmptyState, ReplyThreadChatterView, C> {
    public final class Props: ASComponentProps {
        var chatterModels: [ReplyThreadChatterModel] = []
    }

    private let avatarPadding: CGFloat = 4
    private let verticalPadding: CGFloat = 8
    private let maxDisplayCount: Int = 5

    private var avatarSize: CGFloat {
        ReplyThreadChatterView.avatarSize
    }

    public override func create(_ rect: CGRect) -> ReplyThreadChatterView {
        return ReplyThreadChatterView(frame: rect)
    }

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        let width: CGFloat = CGFloat(props.chatterModels.count) * avatarSize + CGFloat(CGFloat(min(props.chatterModels.count - 1, maxDisplayCount - 1)) * avatarPadding)
        return CGSize(width: width,
                      height: avatarSize + verticalPadding)
    }

    public override func update(view: ReplyThreadChatterView) {
        super.update(view: view)
        view.update(chatterModels: props.chatterModels,
                    padding: avatarPadding,
                    edgeInsets: UIEdgeInsets(top: verticalPadding, left: 0, bottom: 0, right: 0),
                    maxDisplayCount: maxDisplayCount)
    }
}

public enum FlexDirection {
    case row
    case rowReverse
}

public typealias ReplyThreadChatterModel = (userId: String, key: String)

// 展示一串连续头像的View
public final class ReplyThreadChatterView: UIView {
    static let avatarSize: CGFloat = 22

    init(chatterModels: [ReplyThreadChatterModel] = [],
         padding: CGFloat = 4,
         edgeInsets: UIEdgeInsets = .zero,
         maxDisplayCount: Int = 5,
         frame: CGRect) {
        super.init(frame: frame)
        let lastViewFrame = CGRect(x: edgeInsets.left, y: edgeInsets.top, width: 0, height: 0)
        layoutAvatars(chatterModels: chatterModels,
                      lastViewFrame: lastViewFrame,
                      padding: padding,
                      edgeInsets: edgeInsets,
                      maxDisplayCount: maxDisplayCount)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(chatterModels: [ReplyThreadChatterModel] = [],
                padding: CGFloat = 4,
                edgeInsets: UIEdgeInsets = .zero,
                maxDisplayCount: Int = 5) {
        self.subviews.forEach { view in
            view.removeFromSuperview()
        }
        let lastViewFrame = CGRect(x: edgeInsets.left, y: edgeInsets.top, width: 0, height: 0)
        layoutAvatars(chatterModels: chatterModels,
                      lastViewFrame: lastViewFrame,
                      padding: padding,
                      edgeInsets: edgeInsets,
                      maxDisplayCount: maxDisplayCount)
    }

    @discardableResult
    func layoutAvatars(chatterModels: [ReplyThreadChatterModel],
                       lastViewFrame: CGRect,
                       padding: CGFloat,
                       edgeInsets: UIEdgeInsets,
                       maxDisplayCount: Int) {
        var lastViewFrame = lastViewFrame
        for (index, model) in chatterModels.enumerated() {
            if index == maxDisplayCount { break }
            let padding = index == 0 ? 0 : padding
            let avatar = getAvatarView(avatarKey: model.key, userId: model.userId)
            self.addSubview(avatar)
            avatar.frame = CGRect(x: lastViewFrame.maxX + padding, y: lastViewFrame.origin.y, width: Self.avatarSize, height: Self.avatarSize)
            lastViewFrame = avatar.frame
        }
    }

    func getAvatarView(avatarKey: String, userId: String) -> UIView {
        let avatarView = BizAvatar()
        avatarView.setAvatarByIdentifier(userId,
                                         avatarKey: avatarKey,
                                         scene: .Chat,
                                         avatarViewParams: .init(sizeType: .size(Self.avatarSize)))
        return avatarView
    }
}
