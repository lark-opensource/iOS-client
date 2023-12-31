//
//  DetailFollowerView.swift
//  Todo
//
//  Created by 白言韬 on 2021/3/4.
//

import Foundation
import CTFoundation
import LarkBizAvatar
import UniverseDesignIcon

protocol DetailFollowerViewDataType {
    var avatars: [AvatarSeed] { get }
    var countText: String { get }
}

/// Detail - Follower - View

class DetailFollowerView: BasicCellLikeView, ViewDataConvertible {

    var viewData: DetailFollowerViewDataType? {
        didSet {
            guard let viewData = viewData else { return }

            if !viewData.avatars.isEmpty, !viewData.countText.isEmpty {
                content = .customView(subTaskFollowerConetntView)
                let icon = UDIcon.rightOutlined.ud.resized(to: CGSize(width: 14, height: 14))
                let avatars = viewData.avatars.map { CheckedAvatarViewData(icon: .avatar($0)) }
                let groupViewData = AvatarGroupViewData(avatars: Array(avatars.prefix(5)), style: .big)
                subTaskFollowerConetntView.viewData = DetailUserViewData(
                    avatarData: groupViewData,
                    content: viewData.countText,
                    icon: icon
                )
            } else {
                content = .customView(emptyFollowerContentView)
            }
        }
    }

    var emptyClickHandler: (() -> Void)? {
        didSet {
            emptyFollowerContentView.onTapHandler = emptyClickHandler
        }
    }
    var contentClickHandler: (() -> Void)? {
        didSet {
            subTaskFollowerConetntView.onTapContentHandler = contentClickHandler
        }
    }

    private lazy var emptyFollowerContentView: DetailEmptyView = {
        let view = DetailEmptyView()
        view.text = I18N.Todo_AddFollower_Tooltip
        return view
    }()

    private lazy var subTaskFollowerConetntView = DetailUserContentView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let follow = UDIcon.getIconByKey(
            .subscribeOutlined,
            renderingMode: .automatic,
            iconColor: nil,
            size: CGSize(width: 20, height: 20)
        )
        icon = .customImage(follow.ud.withTintColor(UIColor.ud.iconN3))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: 48)
    }

}
