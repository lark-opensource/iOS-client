//
//  SubscribePeopleCell.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/11.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import LarkBizAvatar

public final class SubscribePeopleCell: SubscribeBaseCell {

    static let identifie = "SubscribePeopleCell"
    let avatar: AvatarView = {
        let view = AvatarView()
        view.isUserInteractionEnabled = false
        return view
    }()

    private let subLabels = SubscribeLables()
    private let bottomSeperator = UIView()
    var isLastRow = false {
        didSet {
            let leftOffset = isLastRow ? 0 : 76
            bottomSeperator.snp.updateConstraints { (make) in
                make.left.equalTo(leftOffset)
            }
        }
    }

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBody
        addCustomHighlightedView()
    }

    func updateWith(_ data: SubscribePeopleCellModel) {
        subLabels.updateWith(data.title, subTitle: data.subTitle)
        subButton.setSubStatus(data.subscribeStatus)
        let avatar = SubAvatar(avatarKey: data.avatarKey, userName: data.title, identifier: data.calendarID)
        self.avatar.setAvatar(avatar, with: 48)

        subLabels.externalTag.isHidden = !data.isExternal
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layout(avatar: avatar, in: contentView)
        layout(in: subLabels, rightView: subButton, in: contentView)
        layout(seperator: bottomSeperator, in: contentView)
    }

    func layout(avatar: UIView, in superView: UIView) {
        superView.addSubview(avatar)
        avatar.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 48, height: 48))
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
    }

    func layout(in labels: UIView, rightView: UIView, in superView: UIView) {
        superView.addSubview(labels)
        labels.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(avatar.snp.right).offset(12)
            make.right.lessThanOrEqualTo(rightView.snp.left).offset(Margin.rightMargin)
        }
    }

    func layout(seperator: UIView, in superView: UIView) {
        superView.addSubview(bottomSeperator)
        seperator.backgroundColor = UIColor.ud.lineDividerDefault
        seperator.snp.makeConstraints { (make) in
            make.left.equalTo(subLabels)
            make.height.equalTo(1.0 / UIScreen.main.scale)
            make.right.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
