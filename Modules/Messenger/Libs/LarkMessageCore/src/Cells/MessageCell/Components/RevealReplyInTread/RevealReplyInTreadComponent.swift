//
//  RevealReplyInTreadComponent.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/9/30.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkModel
import LarkMessageBase
import UniverseDesignIcon
import RichLabel

public protocol RevealReplyInTreadComponentContext: ComponentContext { }

public struct RevealReplyInfo {
    let nameAndReply: NSAttributedString
    let position: Int32
    let chatter: Chatter
}

final public class RevealReplyInTreadComponentProps: ASComponentProps {
    /// 一共有多少条话题回复
    var totalReplyCount: Int32 = 0
    /// 最近5条话题回复
    var replyInfos: [RevealReplyInfo] = []
    /// 是否显示底部「回复话题」
    var showReplyTip: Bool = true
    /// 底部「回复话题」使用使用更浅色的icon + 文本
    var useLightColor: Bool = false
    /// 点击底部「回复话题」，点击事件单独暴露，用于埋点
    var replyTipClick: (() -> Void)?
    /// 「查看更多x条回复」文字颜色
    var viewColor = UIColor.ud.textLinkNormal
    /// 点击了「查看更多x条回复」
    var viewClick: (() -> Void)?
    /// 点击了某条回复
    var replyClick: ((Int32) -> Void)?
    /// 头像 + 名称 + 评论内容一起的最大宽度
    var contentPreferMaxWidth: CGFloat = 0
    /// 评论最多显示两行，超出显示"..."
    var outOfRangeText: NSAttributedString?
}

public final class RevealReplyInTreadComponent<C: RevealReplyInTreadComponentContext>: ASComponent<RevealReplyInTreadComponentProps, EmptyState, UIView, C> {

    public override init(props: RevealReplyInTreadComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setUpProps(props: props)
    }

    private lazy var lineComponent: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.height = 1
        style.flexGrow = 1
        style.marginRight = 12
        style.backgroundColor = UIColor.ud.lineDividerDefault
        return UIViewComponent(props: .empty, style: style)
    }()

    /// 查看更多x条回复
    private lazy var moreReplyLabelComponent: RichLabelComponent<C> = {
        let style = ASComponentStyle()
        style.marginLeft = 12
        let props = RichLabelProps()
        props.numberOfLines = 1
        style.backgroundColor = .clear
        return RichLabelComponent(props: props, style: style, context: context)
    }()

    private lazy var moreReplyTipView: TouchViewComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        let component = TouchViewComponent(props: TouchViewComponentProps(), style: style, context: context)
        component.setSubComponents([moreReplyLabelComponent, lineComponent])
        return component
    }()

    private lazy var iconView: IconViewComponent<C> = {
        let props = IconViewComponentProps()
        props.icon = UDIcon.replyCnOutlined.ud.withTintColor(self.props.useLightColor ? UIColor.ud.iconN3 : UIColor.ud.iconN2)
        props.iconSize = CGSize(width: 16, height: 16)
        props.iconAndLabelSpacing = 7
        let attributedText = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_IM_SwitchedTopicGroup_ReplyToTopic_Button)
        attributedText.addAttributes(
            [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: self.props.useLightColor ? UIColor.ud.textPlaceholder : UIColor.ud.textCaption
            ],
            range: NSRange(location: 0, length: attributedText.length)
        )
        props.attributedText = attributedText
        let style = ASComponentStyle()
        style.paddingLeft = 14.5
        style.paddingRight = 14.5
        style.paddingTop = 12
        style.paddingBottom = 12
        return IconViewComponent<C>(props: props, style: style)
    }()

    public override func willReceiveProps(_ old: RevealReplyInTreadComponentProps,
                                          _ new: RevealReplyInTreadComponentProps) -> Bool {
        setUpProps(props: new)
        return true
    }

    private func setUpProps(props: RevealReplyInTreadComponentProps) {
        let count = props.totalReplyCount - Int32(props.replyInfos.count)
        // swiftlint:disable all
        moreReplyLabelComponent.style.display = count > 0 ? .flex : .none
        lineComponent.style.marginLeft = count > 0 ? 8 : 12
        if count > 0 {
            let paragraph = NSMutableParagraphStyle()
            paragraph.minimumLineHeight = 19
            paragraph.maximumLineHeight = 19
            let tipText = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_IM_SwitchedTopicGroup_ViewNumMoreTopicReplies_Text(count))
            tipText.addAttributes(
                [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: props.viewColor,
                    NSAttributedString.Key.paragraphStyle: paragraph
                ],
                range: NSRange(location: 0, length: tipText.length)
            )
            moreReplyLabelComponent.props.attributedText = tipText
        } else {
            moreReplyLabelComponent.props.attributedText = nil
        }
        if props.replyInfos.count > 0 {
            moreReplyTipView.style.marginBottom = 8
        } else {
            moreReplyTipView.style.marginBottom = 0
        }
        var subComponents: [ComponentWithContext<C>] = []
        subComponents.append(moreReplyTipView)
        for i in 0..<props.replyInfos.count {
            let style = ASComponentStyle()
            if i != props.replyInfos.count - 1 {
                style.marginBottom = 8
            }
            let replyInfo = props.replyInfos[i]
            let replyInfoProps = RevealReplyComponentComponentProps(replyInfo: replyInfo,
                                                                    outOfRangeText: props.outOfRangeText,
                                                                    contentPreferMaxWidth: props.contentPreferMaxWidth)
            replyInfoProps.replyClick = props.replyClick
            let revealReply = RevealReplyComponent<C>(props: replyInfoProps, style: style)
            subComponents.append(revealReply)
        }
        iconView.props.onViewClicked = props.replyTipClick
        moreReplyTipView.props.onTapped = props.viewClick
        iconView.style.display = props.showReplyTip ? .flex : .none
        subComponents.append(iconView)
        self.setSubComponents(subComponents)
        // swiftlint:enable all
    }
}

private class RevealReplyComponentComponentProps: ASComponentProps {
    var replyInfo: RevealReplyInfo
    var replyClick: ((Int32) -> Void)?
    var outOfRangeText: NSAttributedString?
    var contentPreferMaxWidth: CGFloat = 0
    init(replyInfo: RevealReplyInfo, outOfRangeText: NSAttributedString?, contentPreferMaxWidth: CGFloat) {
        self.replyInfo = replyInfo
        self.outOfRangeText = outOfRangeText
        self.contentPreferMaxWidth = contentPreferMaxWidth
    }
}

private class RevealReplyComponent<C: RevealReplyInTreadComponentContext>: ASComponent<RevealReplyComponentComponentProps, EmptyState, TappedView, C> {
    private lazy var header: AvatarComponent<C> = {
        let props = AvatarComponent<C>.Props()
        let style = ASComponentStyle()
        style.width = 20
        style.height = 20
        style.marginRight = 4
        style.marginLeft = 12
        style.flexShrink = 0
        return AvatarComponent(props: props, style: style)
    }()

    private lazy var nameLabelComponent: RichLabelComponent<C> = {
        let style = ASComponentStyle()
        let props = RichLabelProps()
        props.numberOfLines = 2
        props.lineSpacing = 0
        style.backgroundColor = .clear
        style.marginRight = 12
        return RichLabelComponent(props: props, style: style, context: context)
    }()

    public override init(props: RevealReplyComponentComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        self.style.flexDirection = .row
        self.style.alignItems = .stretch
        setUpProps(props: props)
    }

    private func setUpProps(props: RevealReplyComponentComponentProps) {
        header.props.avatarKey = props.replyInfo.chatter.avatarKey
        header.props.id = props.replyInfo.chatter.id
        nameLabelComponent.props.attributedText = props.replyInfo.nameAndReply
        nameLabelComponent.props.outOfRangeText = props.outOfRangeText
        nameLabelComponent.props.preferMaxLayoutWidth = props.contentPreferMaxWidth - CGFloat(header.style.width.value) - CGFloat(header.style.marginRight.value)
        self.setSubComponents([header, nameLabelComponent])
    }

    public override func create(_ rect: CGRect) -> TappedView {
        return TappedView(frame: rect)
    }

    public override func update(view: TappedView) {
        super.update(view: view)

        if let replyClick = self.props.replyClick {
            view.initEvent(needLongPress: false)
            view.onTapped = { [weak self] _ in
                replyClick(self?.props.replyInfo.position ?? -1)
            }
        } else {
            view.deinitEvent()
        }
    }
}
