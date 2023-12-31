//
//  MeetingRoomFormTopView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/3/28.
//

import UIKit

final class MeetingRoomFormTopView: UIView {

    private(set) lazy var tipsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.body0
        label.text = BundleI18n.Calendar.Calendar_MeetingRoom_CustomizedResevationFormTitle
        label.numberOfLines = 0
        return label
    }()

    private(set) lazy var subtipsLabel: UILabel = {
        let label = UILabel()

        let requireMark = "*"
        let text = BundleI18n.Calendar.Calendar_MeetingRoom_CustomizedResevationFormContent(mark: requireMark)
        let attributedText = NSMutableAttributedString(string: text,
                                                       attributes: [.foregroundColor: UIColor.ud.textCaption,
                                                                    .font: UIFont.body3])
        let redRange = (text as NSString).range(of: requireMark)
        attributedText.addAttribute(.foregroundColor, value: UIColor.ud.functionDangerContentDefault, range: redRange)
        label.attributedText = attributedText
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        preservesSuperviewLayoutMargins = true
        layoutMargins = UIEdgeInsets(horizontal: 16, vertical: 16)

        layer.cornerRadius = 4

        backgroundColor = UIColor.ud.primaryFillSolid02

        addSubview(tipsLabel)
        addSubview(subtipsLabel)

        tipsLabel.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin)
            make.trailing.equalTo(snp.trailingMargin)
            make.top.equalTo(snp.topMargin)
        }

        subtipsLabel.snp.makeConstraints { make in
            make.top.equalTo(tipsLabel.snp.bottom).offset(10)
            make.leading.equalTo(snp.leadingMargin)
            make.trailing.equalTo(snp.trailingMargin)
            make.bottom.equalTo(snp.bottomMargin)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
