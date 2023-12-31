//
//  BaseFeedNaviBar.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/6/9.
//

import UIKit
import Foundation
import LarkUIKit
import LarkTag
import AnimatedTabBar
import LarkInteraction
import LarkTab
import UniverseDesignColor

class BaseFeedNaviBar: TitleNaviBar {

    var backButtonClickedBlock: (() -> Void)?

    private let backWrapper = UIView()
    private let backButton = UIButton()
    private let unreadLabel = PaddingUILabel()

    init(titleView: UIView) {
        super.init(titleView: titleView)

        contentview.addSubview(backWrapper)
        backWrapper.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(12)
            maker.centerY.equalToSuperview()
        }
        backWrapper.addPointer(
            .init(
                effect: .highlight,
                shape: { (size) -> PointerInfo.ShapeSizeInfo in
                    return (CGSize(width: size.width + 10, height: 36), 8)
                }
            )
        )

        backButton.setImage(LarkUIKit.Resources.navigation_back_light.ud.withTintColor(UIColor.ud.iconN1),
                            for: .normal)
        backWrapper.addSubview(backButton)
        backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        backButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        backButton.snp.makeConstraints { (make) in
            make.left.bottom.top.equalToSuperview()
        }

        backWrapper.addSubview(unreadLabel)
        unreadLabel.paddingLeft = 5
        unreadLabel.paddingRight = 5
        unreadLabel.isUserInteractionEnabled = true
        unreadLabel.lu.addTapGestureRecognizer(action: #selector(backButtonClicked), target: self)
        unreadLabel.textAlignment = .center
        unreadLabel.textColor = UIColor.ud.N900
        unreadLabel.font = UIFont.boldSystemFont(ofSize: 13)
        unreadLabel.color = UIColor.ud.N300
        unreadLabel.layer.masksToBounds = true
        unreadLabel.layer.cornerRadius = Cons.unreadLabelRadius
        unreadLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        unreadLabel.snp.makeConstraints { (make) in
            make.height.equalTo(22)
            make.width.greaterThanOrEqualTo(unreadLabel.snp.height)
            make.left.equalTo(backButton.snp.right)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }

        titleView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleView.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(backWrapper.snp.right)
            make.right.lessThanOrEqualTo(rightStackView.snp.left)
        }

        self.setBadge(.none)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setBadge(_ badge: BadgeType) {
        var messageCount = 0
        switch badge {
        case .number(let num):
            messageCount = Int(num)
        default:
            messageCount = 0
        }
        if messageCount > 0 {
            self.unreadLabel.text = messageCount > Cons.messageMaxCount ? "999+" : "\(messageCount)"
            self.unreadLabel.isHidden = false
        } else {
            self.unreadLabel.text = ""
            self.unreadLabel.isHidden = true
        }
    }

    @objc
    private func backButtonClicked() {
        backButtonClickedBlock?()
    }

    enum Cons {
        static let unreadLabelRadius: CGFloat = 11.0
        static let messageMaxCount: Int = 999
    }
}
