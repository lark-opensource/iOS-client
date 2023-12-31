//
//  ChatCardOpenCenterComponent.swift
//  Todo
//
//  Created by wangwanxin on 2021/10/15.
//

import AsyncComponent
import UniverseDesignIcon
import UniverseDesignFont

/// Bot 卡片 - 查看更多模块

// nolint: magic number
final class ChatCardOpenCenterComponentProps: ASComponentProps {
    var title = ""
    var onTap: (() -> Void)?
}

final class ChatCardOpenCenterComponent<C: Context>: ASComponent<ChatCardOpenCenterComponentProps, EmptyState, UIView, C> {

    private let iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        let icon = UDIcon.viewinchatOutlined.ud.resized(to: CGSize(width: 14, height: 14))
        props.setImage = { task in
            task.set(image: icon.ud.withTintColor(UIColor.ud.iconN2))
        }
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.marginTop = 12
        style.marginRight = 2
        style.flexShrink = 0
        return UIImageViewComponent(props: props, style: style)
    }()

    private lazy var labelComponent: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UDFont.systemFont(ofSize: 14)
        props.textColor = UIColor.ud.textCaption
        props.numberOfLines = 1
        props.textAlignment = .left

        let style = ASComponentStyle()
        style.marginTop = 8
        style.backgroundColor = .clear
        style.height = 24.auto()
        return UILabelComponent(props: props, style: style)
    }()

    private lazy var gesture = UITapGestureRecognizer(target: self, action: #selector(onTap))

    override init(props: ChatCardOpenCenterComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.justifyContent = .spaceBetween
        style.flexDirection = .row
        super.init(props: props, style: style, context: context)
        setSubComponents([labelComponent, iconComponent])
    }

    override func update(view: UIView) {
        super.update(view: view)

        view.removeGestureRecognizer(gesture)
        view.addGestureRecognizer(gesture)
    }

    override func willReceiveProps(
        _ old: ChatCardOpenCenterComponentProps,
        _ new: ChatCardOpenCenterComponentProps
    ) -> Bool {
        labelComponent.props.text = new.title
        return true
    }

    @objc
    private func onTap() {
        props.onTap?()
    }

}

final class ChatCardOpenCenterContainerComponent<C: Context>: ASComponent<ChatCardOpenCenterComponentProps, EmptyState, UIView, C> {

    private lazy var separateLine: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = 0
        style.backgroundColor = UIColor.ud.lineDividerDefault
        style.height = CGFloat(1.0 / UIScreen.main.scale).auto()
        return UIViewComponent(props: .init(), style: style)
    }()

    private lazy var contentView: ChatCardOpenCenterComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return ChatCardOpenCenterComponent(props: .init(), style: style)
    }()

    override init(props: ChatCardOpenCenterComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.alignContent = .stretch
        style.flexDirection = .column
        super.init(props: props, style: style, context: context)
        setSubComponents([separateLine, contentView])
    }

    override func willReceiveProps(
        _ old: ChatCardOpenCenterComponentProps,
        _ new: ChatCardOpenCenterComponentProps
    ) -> Bool {
        contentView.props = new
        return true
    }

}
