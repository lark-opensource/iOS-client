//
//  SubscribeCalendarCell.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/9.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import SnapKit
import UniverseDesignIcon

public final class SubscribeCalendarCell: SubscribeBaseCell {
    static let identifie = "SubscribeCalendarCell"

    let avatarView = UIImageView()

    private let titleLabel: UILabel = UILabel.cd.textLabel()
    private let numLabel = UILabel.cd.subTitleLabel()
    private let spliter = UIView()
    private let subTitleLabel: UILabel = UILabel.cd.subTitleLabel()
    private let resignedTagView = TagViewProvider.resignedTagView

    fileprivate let bottomSeperator = UIView()
    var isLastRow = false

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBody
        addCustomHighlightedView()

        let titleStackView = UIStackView()
        contentView.addSubview(titleStackView)
        titleStackView.axis = .horizontal
        titleStackView.spacing = 6
        titleStackView.distribution = .fill
        titleStackView.alignment = .center

        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(resignedTagView)

        var avatarSize: CGSize
        if FG.optimizeCalendar {
            avatarView.layer.cornerRadius = 24
            avatarView.clipsToBounds = true
            avatarSize = CGSize(width: 48, height: 48)
        } else {
            avatarSize = CGSize(width: 20, height: 20)
        }

        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.size.equalTo(avatarSize)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }

        titleStackView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(Margin.topMargin)
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.height.equalTo(26)
            make.right.lessThanOrEqualTo(subButton.snp.left).offset(Margin.rightMargin)
        }

        let subTitleStack = UIStackView()
        contentView.addSubview(subTitleStack)
        subTitleStack.spacing = 6
        subTitleStack.alignment = .center

        subTitleStack.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(Margin.bottomMargin)
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.height.equalTo(22)
            make.right.lessThanOrEqualTo(subButton.snp.left).offset(Margin.rightMargin)
        }

        if FG.showSubscribers {
            subTitleStack.addArrangedSubview(numLabel)
            subTitleStack.addArrangedSubview(spliter)
        }
        subTitleStack.addArrangedSubview(subTitleLabel)
        subTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        numLabel.isHidden = true
        spliter.backgroundColor = .ud.lineDividerDefault
        spliter.isHidden = true
        spliter.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(12)
        }

        contentView.addSubview(bottomSeperator)
        bottomSeperator.backgroundColor = UIColor.ud.lineDividerDefault
        bottomSeperator.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.height.equalTo(1.0 / UIScreen.main.scale)
            make.right.bottom.equalToSuperview()
        }
    }

    func updateWith(_ data: SubscribeCalendarCellModel) {
        titleLabel.text = data.title
        subTitleLabel.text = data.subTitle
        numLabel.text = I18n.Calendar_Share_NumPplSubscribe_Desc(num: data.subNum)
        subButton.setSubStatus(data.subscribeStatus)

        subTitleLabel.isHidden = subTitleLabel.text.isEmpty
        numLabel.isHidden = numLabel.text.isEmpty
        spliter.isHidden = subTitleLabel.isHidden || numLabel.isHidden

        resignedTagView.isHidden = !data.isDismissed
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
