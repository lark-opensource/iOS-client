//
//  ShareUserCardViewComponent.swift
//  LarkMessageCore
//
//  Created by 赵家琛 on 2020/4/21.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkZoomable

private enum Cons {
    static var contentPaddingBottom: CSSValue { 11 }
}

public final class ShareUserCardViewComponent<C: AsyncComponent.Context>: ASComponent<ShareUserCardViewComponent.Props, EmptyState, TappedView, C> {
    public final class Props: ASComponentProps {
        var avatarKey: String = ""
        var name: String = ""
        var chatterId: String = ""
        var cardTapped: (() -> Void)?
        var hasPaddingBottom: Bool = true
    }

    private lazy var topContainer: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.paddingTop = 12
        style.paddingBottom = 12
        style.backgroundColor = UIColor.ud.bgFloat
        return UIViewComponent<C>(props: .empty, style: style)
    }()

    private lazy var avatarComponent: AvatarComponent<C> = {
        let props = AvatarComponent<C>.Props()
        let style = ASComponentStyle()
        style.marginLeft = 12
        style.flexShrink = 0
        style.alignSelf = .center
        style.width = 40.auto()
        style.height = 40.auto()
        return AvatarComponent<C>(props: props, style: style)
    }()

    private lazy var nameComponent: UILabelComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginLeft = 8
        style.marginRight = 12
        let props = UILabelComponentProps()
        props.textColor = UIColor.ud.textTitle
        props.font = UIFont.ud.headline
        props.textAlignment = .left
        props.lineBreakMode = .byTruncatingTail
        props.numberOfLines = 2
        props.text = ""
        return UILabelComponent<C>(props: props, style: style)
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

    private lazy var bottomContainer: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.paddingLeft = 12
        style.paddingRight = 12
        style.paddingTop = 9
        style.paddingBottom = props.hasPaddingBottom ? Cons.contentPaddingBottom : 0
        style.backgroundColor = UIColor.ud.bgFloat
        return UIViewComponent<C>(props: .empty, style: style)
    }()

    private lazy var descComponent: UILabelComponent<C> = {
        let style = ASComponentStyle()
        let descFont = UIFont.ud.body2
        style.backgroundColor = UIColor.clear
        style.height = descFont.figmaHeight.css
        let props = UILabelComponentProps()
        props.font = descFont
        props.textColor = UIColor.ud.textCaption
        props.textAlignment = .left
        props.numberOfLines = 1
        props.text = BundleI18n.LarkMessageCore.Lark_Legacy_SendUserCard
        return UILabelComponent<C>(props: props, style: style)
    }()

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        style.flexDirection = .column
        super.init(props: props, style: style, context: context)
        topContainer.setSubComponents([avatarComponent, nameComponent])
        bottomContainer.setSubComponents([descComponent])
        setSubComponents([topContainer,
                          seperateLine,
                          bottomContainer])
    }

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        nameComponent.props.text = new.name
        avatarComponent.props.avatarKey = new.avatarKey
        avatarComponent.props.id = new.chatterId
        bottomContainer.style.paddingBottom = new.hasPaddingBottom ? Cons.contentPaddingBottom : 0
        return true
    }

    public override func update(view: TappedView) {
        super.update(view: view)
        view.onTapped = { [weak self] _ in
            self?.props.cardTapped?()
        }
    }

    public override func create(_ rect: CGRect) -> TappedView {
        let view = TappedView(frame: rect)
        view.initEvent(needLongPress: false)
        return view
    }
}
