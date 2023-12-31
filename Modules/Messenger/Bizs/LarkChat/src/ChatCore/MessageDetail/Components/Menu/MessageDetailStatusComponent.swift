//
//  MessageDetailStatusComponent.swift
//  Action
//
//  Created by 赵冬 on 2019/8/12.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LarkMessageCore
import UniverseDesignIcon
import LarkFeatureGating
public struct MessageDetailStatusComponentLayoutConstraints {
    public static let statusSize = CGSize(width: 18.0, height: 18.0)
    public static let marginLeft: CGFloat = 6.0
    public static let marginRight: CGFloat = 0.0
}

/// 消息状态显示样式
///
/// - none: 全部隐藏
/// - success: 成功样式
/// - failed: 显示失败
/// - loading: 显示loading
public enum MessageLocalStatus {
    case none
    case success
    case failed
    case loading
}

final class MessageDetailStatusComponent<C: PageContext>: ASComponent<MessageDetailStatusComponent.Props, EmptyState, TappedView, C> {

    public final class Props: ASComponentProps {
        public var messageLocalStatus: MessageLocalStatus = .none
        public var menuTapped: ((MenuButton) -> Void)?
        public var didTappedLocalStatus: LocalStatusComponent<C>.Props.TapHandler?
    }

    private lazy var menuComponent: MenuComponent<C> = {

            let menuStyle = ASComponentStyle()
            let menuProps = MenuComponent<C>.Props(icon: UDIcon.getIconByKey(.moreOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 20, height: 20)))
            menuProps.onTapped = { [weak self] button in
                self?.props.menuTapped?(button)
            }
            return MenuComponent<C>(props: menuProps, style: menuStyle)
        }()

    private lazy var localStatusComponent: LocalStatusComponent<C> = {
        let style = ASComponentStyle()
        style.width = CSSValue(cgfloat: MessageDetailStatusComponentLayoutConstraints.statusSize.width)
        style.height = CSSValue(cgfloat: MessageDetailStatusComponentLayoutConstraints.statusSize.height)
        style.marginLeft = CSSValue(cgfloat: MessageDetailStatusComponentLayoutConstraints.marginLeft)
        style.marginRight = CSSValue(cgfloat: MessageDetailStatusComponentLayoutConstraints.marginRight)

        let localProps = LocalStatusComponent<C>.Props()
        localProps.tapHandler = { [weak self] in
            self?.props.didTappedLocalStatus?($0, $1)
        }
        localProps.status = .normal

        return LocalStatusComponent<C>(props: localProps, style: style)
    }()

    public override init(props: Props, style: ASComponentStyle, context: C?) {
        super.init(props: props, style: style, context: context)
        updateUI(props: props)
        setSubComponents([localStatusComponent, menuComponent])
    }

    public override func willReceiveProps(_ old: MessageDetailStatusComponent<C>.Props, _ new: MessageDetailStatusComponent<C>.Props) -> Bool {
        updateUI(props: new)
        return true
    }

    public override func update(view: TappedView) {
        super.update(view: view)
        view.hitTestEdgeInsets = UIEdgeInsets(top: -20, left: -20, bottom: -20, right: -20)
    }

    private func updateUI(props: Props) {
        switch props.messageLocalStatus {
        case .none:
            localStatusComponent.style.display = .none
            menuComponent.style.display = .none
        case .success:
            localStatusComponent.style.display = .none
            if context?.getStaticFeatureGating("messenger.message.mobile_message_menu_transformation") == true {
                menuComponent.style.display = .none
            } else {
                menuComponent.style.display = .flex
            }
        case .failed:
            localStatusComponent.style.display = .flex
            localStatusComponent.props.status = .failed
            menuComponent.style.display = .none
        case .loading:
            localStatusComponent.style.display = .flex
            localStatusComponent.props.status = .loading
            menuComponent.style.display = .none
        }

        menuComponent.props.onTapped = { [weak self]  view in
            self?.props.menuTapped?(view)
        }

        localStatusComponent.props.tapHandler = { [weak self] in
            self?.props.didTappedLocalStatus?($0, $1)
        }
    }
}
