//
//  RoundAvatarStackView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/15.
//

import SnapKit
//import /*LarkCore*/
import Foundation
import LarkBizAvatar
import UIKit

final public class RoundAvatarStackView: UIView {
    public var blueCircleWidth: CGFloat = 2
    private let overlappingWidth: CGFloat
    private let avatarWidth: CGFloat
    private let showBgColor: Bool
    private(set) var avatarViews: [UIView]

    private var widthConstraint: Constraint?

    public init(avatarViews: [UIView], avatarWidth: CGFloat = 28, overlappingWidth: CGFloat = 9, showBgColor: Bool = true, blueCircleWidth: CGFloat = 2) {
        self.blueCircleWidth = blueCircleWidth
        self.overlappingWidth = overlappingWidth
        self.avatarWidth = avatarWidth
        self.avatarViews = avatarViews
        self.showBgColor = showBgColor
        super.init(frame: .zero)

        snp.makeConstraints { (make) in
            widthConstraint = make.width.equalTo(0).constraint
            make.height.equalTo(avatarWidth + 2 * blueCircleWidth)
        }
        set(avatarViews)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(_ avatarViews: [UIView]) {
        self.avatarViews = avatarViews
        subviews.forEach { $0.removeFromSuperview() }

        if avatarViews.isEmpty {
            widthConstraint?.update(offset: 0)
        } else {
            var startOffset: CGFloat = 0
            let totalWidth = avatarWidth + 2 * blueCircleWidth
            avatarViews
                .forEach { (avatarView) in
//                    guard let avatarView = avatarView as? RoundAvatarView else { return }
                    addSubview(avatarView)
                    sendSubviewToBack(avatarView)
                    avatarView.snp.makeConstraints { (make) in
                        make.centerY.equalToSuperview()
                        make.left.equalTo(startOffset)
                    }
                    startOffset += totalWidth - overlappingWidth
                }
            widthConstraint?.update(offset: startOffset + overlappingWidth)
        }
    }
}
