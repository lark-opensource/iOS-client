//
//  AvatarListComponent.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/4/22.
//

import UIKit
import Foundation
import TangramComponent

public final class AvatarListComponentProps: Props {
    public var setAvatarTasks: AsyncSerialEquatable<[UserAvatarListView.SetAvatarTask]> = .init(value: [])
    public var avatarSize: CGFloat = UserAvatarListView.defaultSize
    public var avatarOverSize: CGFloat = UserAvatarListView.defaultOverSize
    public var avatarEdgeSize: CGFloat = UserAvatarListView.defaultEdgeSize
    public var restCount: Int = 0
    public var restTextFont: EquatableWrapper<UIFont> = .init(value: UserAvatarListView.defaultFont)
    public var restTextColor: UIColor = UserAvatarListView.defaultTextColor
    public var restBackgroundColor: UIColor = UserAvatarListView.defaultBackgroundColor
    public var onTap: EquatableWrapper<UserAvatarListView.AvatarListTapped?> = .init(value: nil)

    public init() {}

    public func clone() -> AvatarListComponentProps {
        let clone = AvatarListComponentProps()
        clone.setAvatarTasks = setAvatarTasks.clone()
        clone.avatarSize = avatarSize
        clone.avatarOverSize = avatarOverSize
        clone.avatarEdgeSize = avatarEdgeSize
        clone.restCount = restCount
        clone.restTextFont = restTextFont
        clone.restTextColor = restTextColor.copy() as? UIColor ?? UserAvatarListView.defaultTextColor
        clone.restBackgroundColor = restBackgroundColor.copy() as? UIColor ?? UserAvatarListView.defaultBackgroundColor
        clone.onTap = onTap
        return clone
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? AvatarListComponentProps else { return false }
        return setAvatarTasks == old.setAvatarTasks &&
            avatarSize == old.avatarSize &&
            avatarOverSize == old.avatarOverSize &&
            avatarEdgeSize == old.avatarEdgeSize &&
            restCount == old.restCount &&
            restTextFont == old.restTextFont &&
            restTextColor == old.restTextColor &&
            restBackgroundColor == old.restBackgroundColor &&
            onTap == old.onTap
    }
}

public final class AvatarListComponent<C: Context>: RenderComponent<AvatarListComponentProps, UserAvatarListView, C> {
    public override var isSelfSizing: Bool {
        return true
    }

    public override func create(_ rect: CGRect) -> UserAvatarListView {
        let view = UserAvatarListView(setAvatarTasks: props.setAvatarTasks.value,
                                      restCount: props.restCount,
                                      avatarSize: props.avatarSize,
                                      avatarOverSize: props.avatarOverSize,
                                      avatarEdgeSize: props.avatarEdgeSize,
                                      restTextFont: props.restTextFont.value,
                                      restTextColor: props.restTextColor,
                                      restBackgroundColor: props.restBackgroundColor)
        view.frame = rect
        return view
    }

    public override func update(_ view: UserAvatarListView) {
        super.update(view)
        view.update(setAvatarTasks: props.setAvatarTasks.value, restCount: props.restCount)
        view.setTapEvent(props.onTap.value)
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return UserAvatarListView.sizeToFit(avatarCount: props.setAvatarTasks.value.count,
                                            restCount: props.restCount,
                                            avatarSize: props.avatarSize,
                                            avatarOverSize: props.avatarOverSize)
    }
}
