//
//  SubscribeBaseCell.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/11.
//  Copyright © 2019 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import SnapKit

typealias SubscribeTapAction = () -> Void
public class SubscribeBaseCell: UITableViewCell {
    final class Size {
        static let subButtonHeight: CGFloat = 28
    }

    final class Margin {
        static let rightMargin: CGFloat = -15
        static let topMargin: CGFloat = 10
        static let bottomMargin: CGFloat = -10
    }

    struct SubAvatar: Avatar {
        var avatarKey: String
        var userName: String
        var identifier: String
    }

    let subButton = SubscribeButton()
    var tapAction: SubscribeTapAction?
    static let cellHeight: CGFloat = 68
    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        subButton.addTarget(self, action: #selector(subButtonOnClick), for: .touchUpInside)
        subButton.increaseClickableArea(top: -15,
                                        left: 0,
                                        bottom: -15,
                                        right: 0)
        layout(subButton: subButton, in: contentView)
    }

    @objc
    private func subButtonOnClick() {
        tapAction?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout(subButton: UIView, in superView: UIView) {
        superView.addSubview(subButton)
        subButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(Margin.rightMargin)
            make.height.equalTo(Size.subButtonHeight)
            make.centerY.equalToSuperview()
        }
    }
}
