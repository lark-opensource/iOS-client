//
//  AvatarComponent.swift
//  LarkThread
//
//  Created by qihongye on 2019/2/14.
//

import UIKit
import Foundation
import AsyncComponent
import LarkBizAvatar
import LarkModel
import LarkUIKit
import AvatarComponent
import AppReciableSDK
import ThreadSafeDataStructure

public final class AvatarComponent<C: AsyncComponent.Context>: ASComponent<AvatarComponent.Props, EmptyState, LarkMedalAvatar, C> {
    public final class Props: ASComponentProps {
        /// 背景颜色
        public let backgroundColor: UIColor = UIColor.ud.N300
        /// 选中时保持的颜色，防止长按背景色变化
        public let lastingColor: UIColor = UIColor.ud.N50
        /// 头像key
        public var avatarKey: String = ""
        /// 寻准key
        public var medalKey: String = ""
        /// chatterID
        public var id: String = ""
        /// 头像点击事件
        public var onTapped: SafeAtomic<((BizAvatar) -> Void)?> = nil + .readWriteLock
        /// 头像长按事件
        public var longPressed: ((BizAvatar) -> Void)?
        /// MiniIcon
        public var miniIcon: MiniIconProps?
        /// 是否是密聊
        public var isScretChat: Bool = false
        /// 是否展示medalImageView(勋章等)
        public var showMedalImageView: Bool = true
    }

    override public var isComplex: Bool {
        return true
    }

    override public func create(_ rect: CGRect) -> LarkMedalAvatar {
        let view = LarkMedalAvatar(frame: rect)
        self.bindEvent(view: view)
        return view
    }

    override public func update(view: LarkMedalAvatar) {
        super.update(view: view)
        self.bindEvent(view: view)
        view.backgroundColor = props.backgroundColor
        let size = max(view.bounds.width, view.bounds.height)
        let scene: Scene = props.isScretChat ? .SecretChat : .Chat
        view.medalImageView.isHidden = !props.showMedalImageView
        view.setAvatarByIdentifier(props.id,
                                   avatarKey: props.avatarKey,
                                   medalKey: props.medalKey,
                                   medalFsUnit: "",
                                   scene: scene,
                                   avatarViewParams: .init(sizeType: .size(size))) { [weak view] result in
            switch result {
            case .success:
                view?.backgroundColor = UIColor.clear
            default:
                 break
             }
        }
        view.setMiniIcon(props.miniIcon)
    }

    private func bindEvent(view: LarkMedalAvatar) {
        if self.props.onTapped.value != nil {
            view.onTapped = { [weak self] in
                self?.props.onTapped.value?($0)
            }
        } else {
            view.onTapped = nil
        }
        if self.props.longPressed != nil {
            view.onLongPress = { [weak self] in
                self?.props.longPressed?($0)
            }
        } else {
            view.onLongPress = nil
        }
    }
}

public protocol AvatarContext: AsyncComponent.Context {
    func handleTapAvatar(chatterId: String, chatId: String)
}

public final class AvatarWithTapEventComponent<C: AvatarContext>: ASComponent<AvatarWithTapEventComponent.Props, EmptyState, LarkMedalAvatar, C> {
    public final class Props: ASComponentProps {
        public let backgroundColor: UIColor = UIColor.ud.N300
        public let lastingColor: UIColor = UIColor.ud.N50
        public var fromChatter: Chatter?
        public var chat: Chat?
    }

    override public var isComplex: Bool {
        return true
    }

    override public func create(_ rect: CGRect) -> LarkMedalAvatar {
        let view = LarkMedalAvatar(frame: rect)
        view.lu.addTapGestureRecognizer(action: #selector(onTapped(_:)), target: self, touchNumber: 1)
        return view
    }

    override public func update(view: LarkMedalAvatar) {
        super.update(view: view)
        view.lastingColor = props.lastingColor
        let reciableKey = AppReciableSDK.shared.start(biz: .Messenger, scene: .Chat, event: .imageLoad, page: nil)
        let size = max(view.bounds.width, view.bounds.height)
        view.setAvatarByIdentifier(props.fromChatter?.id ?? "",
                                   avatarKey: props.fromChatter?.avatarKey ?? "",
                                   medalKey: props.fromChatter?.medalKey ?? "",
                                   medalFsUnit: "",
                                   scene: .Chat,
                                   avatarViewParams: .init(sizeType: .size(size))) { result in
            if case .success = result {
                AppReciableSDK.shared.end(key: reciableKey)
            }
        }
        view.setAvatarUIConfig(AvatarComponentUIConfig(backgroundColor: props.backgroundColor))
    }

    @objc
    private func onTapped(_ sender: LarkMedalAvatar) {
        guard let chatter = props.fromChatter,
            chatter.profileEnabled,
            let chat = props.chat else {
            return
        }
        context?.handleTapAvatar(chatterId: chatter.id, chatId: chat.id)
    }
}
