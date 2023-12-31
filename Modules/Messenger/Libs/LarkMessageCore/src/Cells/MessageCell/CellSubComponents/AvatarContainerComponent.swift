//
//  AvatarContainerComponent.swift
//  LarkChat
//
//  Created by Ping on 2023/2/20.
//

import UIKit
import LarkUIKit
import Foundation
import LarkModel
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import UniverseDesignIcon
import UniverseDesignColor
import LarkMessengerInterface

extension ChatContext: AvatarContext {
    public func handleTapAvatar(chatterId: String, chatId: String) {
        let body = PersonCardBody(chatterId: chatterId,
                                  chatId: chatId,
                                  source: .chat)

        if Display.phone {
            self.navigator(type: .push, body: body, params: nil)
        } else {
            self.navigator(
                type: .present,
                body: body,
                params: NavigatorParams(prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                }))
        }
    }
}

public struct ChatCellConsts {
    public static let avatarKey = "chat-cell-avatar"
    public static let secretAvatarKey = "chat-cell-secretAvatar"
    public static let bubbleKey = "chat-cell-bubble"
    public static let checkboxKey = "chat-cell-checkbox"
}

public enum AvatarLayout {
    case left
    case right
}

public final class AvatarContainerComponentProps: ASComponentProps {
    public var avatarTapped: (() -> Void)?
    public var avatarSize: CGFloat = 30.auto()
    public var hideUserInfo: Bool = false
    // 头像和名字
    public var fromChatter: Chatter?
    public var isScretChat: Bool = false
    public var avatarLayout: AvatarLayout = .left
}

public final class AvatarContainerComponent<C: Context>: ASLayoutComponent<C> {
    public var props: AvatarContainerComponentProps {
        didSet {
            update()
        }
    }

    /// 头像
    lazy var avatar: AvatarComponent<C> = {
        let props = AvatarComponent<C>.Props()
        props.key = ChatCellConsts.avatarKey
        let style = ASComponentStyle()
        let avatarSize = CSSValue(cgfloat: self.props.avatarSize)
        style.width = avatarSize
        style.height = avatarSize
        style.display = .none
        return AvatarComponent(props: props, style: style)
    }()

    /// 单聊密聊头像的假头像
    lazy var secretAvatar: TappedImageComponent<C> = {
        let props = TappedImageComponentProps()
        props.key = ChatCellConsts.secretAvatarKey
        props.image = Resources.secret_single_head
        props.iconSize = CGSize(width: self.props.avatarSize, height: self.props.avatarSize)
        let style = ASComponentStyle()
        style.display = .none
        return TappedImageComponent<C>(props: props, style: style)
    }()

    /// 密聊icon
    lazy var scretChatIcon: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.display = .none
        style.position = .absolute
        style.right = (-4).auto()
        style.bottom = -2
        let size: CGFloat = 16.auto()
        style.width = CSSValue(cgfloat: size)
        style.height = CSSValue(cgfloat: size)
        style.cornerRadius = size / 2
        style.backgroundColor = UIColor.ud.N700 & UIColor.ud.N300
        style.alignItems = .center
        style.justifyContent = .center

        let imageProps = UIImageViewComponentProps()
        let iconSize: CGFloat = 10.auto()
        imageProps.setImage = { $0.set(image: UDIcon.getIconByKey(.lockChatFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: iconSize, height: iconSize))) }
        let imageStyle = ASComponentStyle()
        imageStyle.width = CSSValue(cgfloat: iconSize)
        imageStyle.height = CSSValue(cgfloat: iconSize)
        let imageComponent = UIImageViewComponent<C>(props: imageProps, style: imageStyle)
        let viewComponent = UIViewComponent<C>(props: .empty, style: style)
        viewComponent.setSubComponents([imageComponent])
        return viewComponent
    }()

    public init(
        props: AvatarContainerComponentProps,
        key: String = "",
        style: ASComponentStyle,
        context: C? = nil
    ) {
        self.props = props
        super.init(key: key, style: style, context: context, [])
        setSubComponents([avatar, secretAvatar, scretChatIcon])
    }

    private func update() {
        if props.hideUserInfo {
            avatar.style.display = .none
            avatar.props.onTapped.value = nil
            secretAvatar.style.display = .flex
            secretAvatar.props.iconSize = CGSize(width: self.props.avatarSize, height: self.props.avatarSize)
            secretAvatar.props.onClicked = { [weak props] _ in
                guard let props = props else { return }
                props.avatarTapped?()
            }
        } else {
            avatar.style.display = .flex
            let avatarSize = CSSValue(cgfloat: self.props.avatarSize)
            avatar.style.width = avatarSize
            avatar.style.height = avatarSize
            avatar.props.onTapped.value = { [weak props] _ in
                guard let props = props else { return }
                props.avatarTapped?()
            }
            avatar.props.isScretChat = props.isScretChat
            avatar.props.medalKey = props.fromChatter?.medalKey ?? ""
            avatar.props.avatarKey = props.fromChatter?.avatarKey ?? ""
            avatar.props.id = props.fromChatter?.id ?? ""
            secretAvatar.style.display = .none
            secretAvatar.props.onClicked = nil
        }
        // 密聊icon
        scretChatIcon.style.display = props.isScretChat ? .flex : .none
        self.style.flexDirection = (props.avatarLayout == .left ? .row : .rowReverse)
    }
}
