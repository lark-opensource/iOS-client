//
//  MomentsProfileActivityCellComponent.swift
//  Moment
//
//  Created by ByteDance on 2022/7/21.
//

import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageCore
import UniverseDesignColor
import LarkFeatureGating
import UIKit

final class MomentsProfileActivityCellProps: ASComponentProps {
    var contentComponent: ComponentWithContext<BaseMomentContext>
    var createTime: String = ""
    var interactionEntityRemoved: Bool = false

    var userName: String = ""
    var avatarKey: String = ""
    var avatarId: String = ""

    var interactionAvatarKey: String = ""
    var interactionAvatarId: String = ""
    var interactionAvatarTapped: (() -> Void)?
    var interactionAreaTapped: (() -> Void)?

    var interactionAttributedText: NSAttributedString = NSAttributedString()
    var titleAttributedText: NSAttributedString = NSAttributedString()
    init(contentComponent: ComponentWithContext<BaseMomentContext>) {
        self.contentComponent = contentComponent
    }
}

/// profile特有的cell
final class MomentsProfileActivityCellComponent: ASComponent<MomentsProfileActivityCellProps, EmptyState, UIView, BaseMomentContext> {
    /// 头像
    lazy var avatar: AvatarComponent<BaseMomentContext> = {
        let props = AvatarComponent<BaseMomentContext>.Props()
        props.key = MomentPostCellConsts.avatarKey
        props.showMedalImageView = false
        let style = ASComponentStyle()
        style.width = 40
        style.height = 40
        style.marginTop = 16
        style.marginLeft = 16
        style.position = .absolute
        return AvatarComponent(props: props, style: style)
    }()

    /// 交互文字区
    private lazy var titleSelectionLabelProps: SelectionLabelComponent<BaseMomentContext>.Props = {
        let selectionLabelProps = SelectionLabelComponent<BaseMomentContext>.Props()
        selectionLabelProps.pointerInteractionEnable = false
        return selectionLabelProps
    }()

    /// 交互文字区
    private lazy var titleTextComponent: SelectionLabelComponent<BaseMomentContext> = {
        var style = ASComponentStyle()
        style.backgroundColor = .clear
        return SelectionLabelComponent<BaseMomentContext>(
            props: self.titleSelectionLabelProps,
            style: style
        )
    }()

    /// 创建时间
    lazy var createTime: UILabelComponent<BaseMomentContext> = {
        let props = UILabelComponentProps()
        props.font = UIFont.systemFont(ofSize: 14)
        props.textColor = UIColor.ud.N500
        props.numberOfLines = 1
        let style = ASComponentStyle()
        style.marginTop = 4
        style.marginBottom = 4
        style.backgroundColor = .clear
        return UILabelComponent<BaseMomentContext>(props: props, style: style)
    }()

    /// 整个区域
    lazy var contentConatiner: ASLayoutComponent<BaseMomentContext> = {
        let style = ASComponentStyle()
        style.paddingLeft = 64
        style.paddingRight = 16
        style.paddingBottom = 16
        style.paddingTop = 16
        style.width = 100%
        style.flexDirection = .column
        return ASLayoutComponent(style: style, context: context, [])
    }()

    lazy var interactionContainer: TappedComponent<BaseMomentContext> = {
        let props = TappedComponentProps()
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.ud.bgBodyOverlay
        style.alignItems = .center
        style.marginTop = 12
        style.height = 72
        style.paddingLeft = 8
        style.paddingRight = 8
        style.cornerRadius = 4
        let component = TappedComponent<BaseMomentContext>(props: props, style: style, context: context)
        component.setSubComponents([interactionAvatar, interactionTextComponent])
        return component
    }()

    /// 交互文字区
    private lazy var selectionLabelProps: SelectionLabelComponent<BaseMomentContext>.Props = {
        let selectionLabelProps = SelectionLabelComponent<BaseMomentContext>.Props()
        selectionLabelProps.pointerInteractionEnable = false
        selectionLabelProps.numberOfLines = 2
        selectionLabelProps.autoDetectLinks = false
        selectionLabelProps.outOfRangeText = self.getOutOfRangeAttributedString()
        return selectionLabelProps
    }()

    /// 交互文字区
    private lazy var interactionTextComponent: SelectionLabelComponent<BaseMomentContext> = {
        var style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginLeft = 8
        return SelectionLabelComponent<BaseMomentContext>(
            props: self.selectionLabelProps,
            style: style
        )
    }()

    /// 交互头像区
    lazy var interactionAvatar: AvatarComponent<BaseMomentContext> = {
        let props = AvatarComponent<BaseMomentContext>.Props()
        props.showMedalImageView = false
        let style = ASComponentStyle()
        style.width = 40
        style.height = 40
        style.flexShrink = 0
        return AvatarComponent(props: props, style: style)
    }()

    /// 当评论被删除的时候展示
    lazy var deleComponent: UILabelComponent<BaseMomentContext> = {
        let props = UILabelComponentProps()
        props.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        props.textColor = UIColor.ud.textCaption
        props.numberOfLines = 2
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return UILabelComponent<BaseMomentContext>(props: props, style: style)
    }()

    override init(props: MomentsProfileActivityCellProps,
                  style: ASComponentStyle,
                  context: BaseMomentContext? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([
            avatar,
            contentConatiner
        ])
    }

    override func render() -> BaseVirtualNode {
        self.style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        return super.render()
    }

    override func willReceiveProps(_ old: MomentsProfileActivityCellProps, _ new: MomentsProfileActivityCellProps) -> Bool {
        avatar.props.avatarKey = new.avatarKey
        avatar.props.id = new.avatarId
        /// 添加空函数（profile页头像不可点击，并防止点击进入详情页）
        avatar.props.onTapped.value = { _ in }
        createTime.props.text = new.createTime
        contentConatiner.setSubComponents([titleTextComponent,
                                           createTime,
                                           new.contentComponent,
                                           interactionContainer])
        titleTextComponent.props.attributedText = new.titleAttributedText
        interactionTextComponent.props.attributedText = new.interactionAttributedText
        if new.interactionAvatarKey.isEmpty, new.interactionAttributedText.string.isEmpty {
            interactionContainer.style.display = .none
        } else {
            interactionContainer.style.display = .flex
        }
        interactionContainer.props.onClicked = { [weak new] in
            new?.interactionAreaTapped?()
        }
        interactionAvatar.style.display = new.interactionAvatarKey.isEmpty ? .none : .flex
        interactionTextComponent.style.marginLeft = (interactionAvatar.style.display == .none ? 0 : 8)
        if !new.interactionAvatarKey.isEmpty {
            interactionAvatar.props.id = new.interactionAvatarId
            interactionAvatar.props.avatarKey = new.interactionAvatarKey
            interactionAvatar.props.onTapped.value = { [weak new] _ in
                guard let props = new else { return }
                props.interactionAvatarTapped?()
            }
        }
        return true
    }
    private func getOutOfRangeAttributedString() -> NSAttributedString {
        let text = "\u{2026} "
        let attributesNomal: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.textTitle,
            .font: UIFont.systemFont(ofSize: 17, weight: .regular)
        ]
        return NSAttributedString(string: text, attributes: attributesNomal)
    }
}
