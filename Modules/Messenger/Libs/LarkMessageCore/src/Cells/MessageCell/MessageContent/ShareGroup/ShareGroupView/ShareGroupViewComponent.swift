//
//  ShareGroupViewComponent.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/11.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkModel
import LarkBizAvatar
import LarkTag
import LarkZoomable

private enum Cons {
    static var avatarSize: CGFloat { 40.auto() }
    static var joinButtonFont: UIFont { UIFont.ud.body2 }
    static var joinButtonHeight: CGFloat { joinButtonFont.rowHeight + 15 }
    static var joinButtonPadding: CGFloat { 12 }
    static var nameFont: UIFont { UIFont.ud.headline }
    static var descFont: UIFont { UIFont.ud.caption1 }
    static var bottomDescFont: UIFont { UIFont.ud.body2 }
    static var minButtonWidth: CGFloat { 80 }
    static var contentPaddingBottom: CSSValue { 11 }
}

public final class ShareGroupViewComponent<C: AsyncComponent.Context>: ASComponent<ShareGroupViewComponent.Props, EmptyState, TappedView, C> {

    public final class Props: ASComponentProps {
        var content: ShareGroupChatContent?
        var joinStatusText: String = ""
        var joinButtonText: String = ""
        var joinButtonEnable: Bool = true
        var joinButtonTextColor: UIColor = UIColor.ud.textTitle
        var joinButtonBorderColor: UIColor = UIColor.ud.lineBorderComponent
        var threadMiniIconEnableFg: Bool = false
        var displayJoinButton: Bool = false
        var hasPaddingBottom: Bool = true
        weak var delegate: ShareGroupViewDelegate?
    }

    private lazy var headerProps = ShareGroupHeaderComponent<C>.Props()
    private lazy var headerComponent: ShareGroupHeaderComponent<C> = {
        let style = ASComponentStyle()
        style.paddingTop = 12
        style.paddingBottom = 12
        style.paddingLeft = 12
        style.paddingRight = 12
        style.alignItems = .center
        style.backgroundColor = UIColor.ud.bgFloat
        return ShareGroupHeaderComponent(props: headerProps, style: style)
    }()

    private lazy var bottomContainer: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.justifyContent = .spaceBetween
        style.alignItems = .center
        style.paddingLeft = 12
        style.paddingRight = 12
        style.paddingTop = 12
        style.paddingBottom = props.hasPaddingBottom ? Cons.contentPaddingBottom : 0
        style.backgroundColor = UIColor.ud.bgFloat
        return UIViewComponent<C>(props: .empty, style: style)
    }()

    private lazy var bottomDescComponent: UILabelComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.height = Cons.bottomDescFont.figmaHeight.css
        style.marginRight = 16
        let props = UILabelComponentProps()
        props.font = Cons.bottomDescFont
        props.textColor = UIColor.ud.textCaption
        props.textAlignment = .left
        props.numberOfLines = 1
        return UILabelComponent<C>(props: props, style: style)
    }()

    private lazy var buttonProps = ShareGroupButtonComponent<C>.Props()
    private lazy var buttonComponent: ShareGroupButtonComponent<C> = {
        let style = ASComponentStyle()
        let buttonHeight = Cons.joinButtonHeight
        style.height = CSSValue(cgfloat: buttonHeight)
        style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderComponent))
        style.cornerRadius = 6
        return ShareGroupButtonComponent(props: buttonProps, style: style)
    }()

    // 分割横线
    private lazy var seperateLine: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.height = CSSValue(cgfloat: 1.0)
        style.backgroundColor = UIColor.ud.lineDividerDefault
        style.marginLeft = 12
        style.marginRight = 12
        return UIViewComponent<C>(props: .empty, style: style)
    }()

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        style.flexDirection = .column
        super.init(props: props, style: style, context: context)
        bottomContainer.setSubComponents([bottomDescComponent, buttonComponent])
        setSubComponents([headerComponent, seperateLine, bottomContainer])
    }

    public override func update(view: TappedView) {
        super.update(view: view)
        view.backgroundColor = UIColor.clear
        view.onTapped = { [weak self] _ in
            self?.props.delegate?.headerTapped()
        }
    }

    public override func create(_ rect: CGRect) -> TappedView {
        let view = TappedView(frame: rect)
        view.backgroundColor = UIColor.clear
        view.initEvent(needLongPress: false)
        return view
    }

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        headerProps.threadMiniIconEnableFg = new.threadMiniIconEnableFg
        headerProps.content = new.content
        buttonProps.enable = new.joinButtonEnable
        buttonProps.joinButtonTextColor = new.joinButtonTextColor
        bottomDescComponent.props.text = new.joinStatusText
        buttonProps.buttonClicked = { [weak new] in
            new?.delegate?.joinButtonTapped()
        }

        if props.displayJoinButton {
            buttonComponent.style.display = .flex
            buttonComponent.style.border = Border(BorderEdge(width: 1, color: new.joinButtonBorderColor))
            buttonProps.title = new.joinButtonText
            buttonComponent.props = buttonProps
        } else {
            buttonComponent.style.display = .none
        }
        headerComponent.props = headerProps
        bottomContainer.style.paddingBottom = new.hasPaddingBottom ? Cons.contentPaddingBottom : 0
        return true
    }
}

final class ShareGroupHeaderComponent<C: AsyncComponent.Context>: ASComponent<ShareGroupHeaderComponent.Props, EmptyState, UIView, C> {
    final class Props: ASComponentProps {
        var content: ShareGroupChatContent?
        var threadMiniIconEnableFg: Bool = false
    }

    private lazy var avatarComponent: AvatarComponent<C> = {
        let props = AvatarComponent<C>.Props()
        let style = ASComponentStyle()
        style.flexShrink = 0
        style.height = CSSValue(cgfloat: Cons.avatarSize)
        style.width = style.height
        style.alignSelf = .center
        return AvatarComponent<C>(props: props, style: style)
    }()

    private lazy var nameComponent: ShareGroupTangramHeaderComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        let props = ShareGroupTangramHeaderComponentProps()
        return ShareGroupTangramHeaderComponent<C>(props: props, style: style)
    }()

    private lazy var nameContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        return ASLayoutComponent<C>(style: style, [nameComponent])
    }()

    private lazy var descComponent: UILabelComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginTop = 2
        let props = UILabelComponentProps()
        props.font = Cons.descFont
        props.textColor = UIColor.ud.textCaption
        props.textAlignment = .left
        props.numberOfLines = 1
        return UILabelComponent<C>(props: props, style: style)
    }()

    private lazy var nameAndDescContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.marginLeft = 8
        style.justifyContent = .center
        return ASLayoutComponent<C>(style: style, [nameContainer, descComponent])
    }()

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([avatarComponent, nameAndDescContainer])
    }

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        setUpProps(props: new)
        return true
    }

    private func setUpProps(props: Props) {

        avatarComponent.props.id = props.content?.chat?.id ?? ""
        avatarComponent.props.avatarKey = props.content?.chat?.avatarKey ?? ""
        if props.threadMiniIconEnableFg, props.content?.chat?.chatMode == .threadV2 {
            avatarComponent.props.miniIcon = MiniIconProps(.thread)
        } else {
            avatarComponent.props.miniIcon = nil
        }

        nameComponent.props.text = props.content?.chat?.name ?? ""
        var tag: Tag?
        if let chat = props.content?.chat {
            if chat.isCrossWithKa {
                tag = Tag(type: .connect)
            } else if let relationTag = chat.tagData?.tagDataItems.first(where: { item in
                return item.respTagType == .relationTagExternal || item.respTagType == .relationTagPartner
                || item.respTagType == .relationTagTenantName || item.respTagType == .relationTagUnset
            }) {
                tag = relationTag.transform().tag
            }
        }
        nameComponent.props.tag = tag
        if let description = props.content?.chat?.description, !description.isEmpty {
            nameComponent.props.titleNumberOfLines = 1
            descComponent.style.display = .flex
            descComponent.props.text = description
        } else {
            nameComponent.props.titleNumberOfLines = 2
            descComponent.style.display = .none
        }
    }
}

final class ShareGroupButtonComponent<C: AsyncComponent.Context>: ASComponent<ShareGroupButtonComponent.Props, EmptyState, ShareGroupHighlightButton, C> {
    final class Props: ASComponentProps {
        var expired: Bool = false
        var title: String = ""
        var joinButtonTextColor: UIColor = UIColor.ud.textTitle
        var enable: Bool = true
        var buttonClicked: (() -> Void)?
    }

    override var isComplex: Bool {
        return true
    }

    override var isSelfSizing: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        let width = props.title.lu.width(font: Cons.joinButtonFont, height: Cons.joinButtonFont.rowHeight) + Cons.joinButtonPadding * 2
        return CGSize(width: max(width, Cons.minButtonWidth), height: size.height)
    }

    public override func create(_ rect: CGRect) -> ShareGroupHighlightButton {
        return ShareGroupHighlightButton()
    }

    override func update(view: ShareGroupHighlightButton) {
        super.update(view: view)

        view.titleLabel?.font = Cons.joinButtonFont
        view.setTitleColor(props.joinButtonTextColor, for: .normal)
        view.setTitleColor(UIColor.ud.textDisable, for: .disabled)
        view.setTitle(props.title, for: .normal)
        view.isEnabled = props.enable

        view.removeTarget(nil, action: #selector(self.onClick), for: .touchUpInside)
        view.addTarget(self, action: #selector(self.onClick), for: .touchUpInside)
    }

    @objc
    func onClick() {
        self.props.buttonClicked?()
    }
}
