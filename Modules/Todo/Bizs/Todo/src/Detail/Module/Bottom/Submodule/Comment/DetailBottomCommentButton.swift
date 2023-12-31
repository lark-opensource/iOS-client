//
//  DetailBottomCommentButton.swift
//  Todo
//
//  Created by 张威 on 2021/5/11.
//

import LarkUIKit
import LarkBadge
import UniverseDesignIcon
import UniverseDesignButton
import UniverseDesignFont

/// Detail - Bottom - CommentButton

class DetailBottomCommentButton: UIView {

    /// 控制显示 badge
    var showBadge = false {
        didSet {
            guard oldValue != showBadge else { return }
            iconView.uiBadge.badgeView?.type = showBadge ? .dot(.lark) : .none
            // LarkBadge 接口设计有些问题。有 3pt 的内边距；9x9 对应的实际 size 是 6x6
            iconView.uiBadge.badgeView?.updateSize(to: CGSize(width: 9, height: 9))
            iconView.uiBadge.badgeView?.updateOffset(offsetX: 0, offsetY: 0)
        }
    }

    /// 被点击
    var onClick: (() -> Void)?

    private let button = UDButton()
    private let iconView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody

        var config = UDButton.secondaryGray.config
        config.type = .custom(
            type: (
                size: CGSize(width: 36, height: 36),
                inset: 0,
                font: UDFont.systemFont(ofSize: 16),
                iconSize: CGSize(width: 16, height: 16)
            )
        )
        config.radiusStyle = .square
        button.config = config
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addSubview(button)
        button.snp.makeConstraints { $0.edges.equalToSuperview() }

        iconView.isUserInteractionEnabled = false
        iconView.image = UDIcon.getIconByKey(
            .addCommentOutlined,
            iconColor: UIColor.ud.iconN2,
            size: CGSize(width: 16, height: 16)
        )
        button.addSubview(iconView)
        iconView.snp.makeConstraints { $0.center.equalToSuperview() }
        iconView.uiBadge.addBadge(type: .none)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleTap() {
        onClick?()
    }

}
