//
//  ThreadPostCardContentComponent.swift
//  LarkMessageCore
//
//  Created by liluobin on 2021/6/10.
//
import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LarkZoomable
import LKCommonsLogging
import UniverseDesignCardHeader

final class MergeForwardCardTapView: TappedView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        initEvent(needLongPress: false)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MergeForwardPostCardContentComponent<C: Context>: ASComponent<MergeForwardPostCardContentComponent.Props, EmptyState, MergeForwardCardTapView, C> {

    final class Props: ASComponentProps {
        public var tapAction: (() -> Void)?
        public var fromAvatarAction: (() -> Void)?
        public var fromTitleAction: (() -> Void)?
        public var imageViewTap: ((UIImageView) -> Void)?
        public var title: String = ""
        public var content: String = ""
        public var fromTitle: String = ""
        public var entityId: String = ""
        public var fromAvatarKey: String = ""
        public var imageWarpperProps: ChatImageViewWrapperComponent<C>.Props?
    }

    lazy var titleWrapperComponent: UDCardHeaderComponent<C> = {
        let props = UDCardHeaderComponentProps()
        props.colorHue = UDCardHeaderHue.blue
        let style = ASComponentStyle()
        style.width = 100%
        style.flexDirection = .column
        return UDCardHeaderComponent<C>(props: props, style: style)
    }()

    lazy var titleComponent: UILabelComponent<C> = {
        let style = ASComponentStyle()
        style.minHeight = 36
        style.flexGrow = 0
        style.flexShrink = 1
        style.marginLeft = 12
        style.marginRight = 12
        style.backgroundColor = UIColor.clear
        let props = UILabelComponentProps()
        props.font = UIFont.ud.headline
        props.textColor = UDCardHeaderHue.blue.textColor
        props.textAlignment = .left
        return UILabelComponent<C>(props: props, style: style)
    }()

    lazy var contentConatiner: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginBottom = 16
        style.marginTop = 12
        style.paddingLeft = 12
        style.paddingRight = 12
        style.width = 100%
        style.alignItems = .flexStart
        style.justifyContent = .spaceBetween
        return ASLayoutComponent(style: style, context: context, [contentComponent, imageViewComponent])
    }()

    private lazy var imageViewComponent: ChatImageViewWrapperComponent<C> = {
        let style = ASComponentStyle()
        style.width = 64
        style.height = 64
        style.cornerRadius = 4
        style.flexShrink = 0
        style.marginLeft = 16
        let props = ChatImageViewWrapperComponent<C>.Props()
        return ChatImageViewWrapperComponent<C>(props: props, style: style)
    }()

    lazy var contentComponent: UILabelComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        let props = UILabelComponentProps()
        props.font = UIFont.systemFont(ofSize: 14)
        props.textAlignment = .left
        props.numberOfLines = 3
        props.textColor = UIColor.ud.N900
        return UILabelComponent<C>(props: props, style: style)
    }()

    lazy var lineViewComponent: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.ud.lineDividerDefault
        style.height = 1
        style.marginLeft = 12
        style.marginRight = 12
        return UIViewComponent(props: ASComponentProps(), style: style)
    }()

    /// 最顶部区域 名字 时间、关注
    lazy var bottomConatiner: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginBottom = 16
        style.marginTop = 12
        style.width = 100%
        style.paddingLeft = 12
        style.paddingRight = 12
        return ASLayoutComponent(style: style, context: context, [fromGroupAvatar, fromGroupDesComponent])
    }()
    /// 头像
    lazy var fromGroupAvatar: AvatarComponent<C> = {
        let props = AvatarComponent<C>.Props()
        let style = ASComponentStyle()
        style.width = 16
        style.height = 16
        style.marginRight = 5
        return AvatarComponent(props: props, style: style)
    }()

    lazy var fromGroupDesComponent: UILabelComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        let props = UILabelComponentProps()
        props.font = UIFont.systemFont(ofSize: 12)
        props.textColor = UIColor.ud.textCaption
        props.textAlignment = .left
        props.numberOfLines = 1
        return UILabelComponent<C>(props: props, style: style)
    }()

    override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.flexDirection = .column
        titleWrapperComponent.setSubComponents([titleComponent])
        setSubComponents([titleWrapperComponent,
                          contentConatiner,
                          lineViewComponent,
                          bottomConatiner])
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        titleComponent.props.text = new.title
        contentComponent.props.text = new.content
        fromGroupAvatar.props.avatarKey = new.fromAvatarKey
        fromGroupAvatar.style.display = new.fromAvatarKey.isEmpty ? .none : .flex
        fromGroupAvatar.props.id = new.entityId
        fromGroupDesComponent.props.text = new.fromTitle
        fromGroupDesComponent.props.onTap = new.fromTitleAction
        let action = new.fromAvatarAction
        fromGroupAvatar.props.onTapped.value = { (_) in
            action?()
        }
        imageViewComponent.style.display = new.imageWarpperProps == nil ? .none : .flex
        imageViewComponent.style.height = imageViewComponent.style.display == .flex ? 64 : 0
        if let imageWarpperProps = new.imageWarpperProps {
            imageViewComponent.props = imageWarpperProps
        }
        return true
    }

    public override func update(view: MergeForwardCardTapView) {
        view.onTapped = { [weak self] (_) in
            self?.props.tapAction?()
        }
        super.update(view: view)
        view.backgroundColor = UIColor.ud.bgFloat
    }

    public override func create(_ rect: CGRect) -> MergeForwardCardTapView {
        let view = MergeForwardCardTapView(frame: rect)
        return view
    }

}
