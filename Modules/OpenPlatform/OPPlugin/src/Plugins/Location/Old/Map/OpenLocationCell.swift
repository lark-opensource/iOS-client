//
//  OpenLocationCell.swift
//  OPPlugin
//
//  Created by yi on 2021/3/1.
//

import Foundation
import UIKit
import SnapKit
import LarkTag
import OPFoundation
import UniverseDesignColor

final class OpenLocationCell: UITableViewCell {
    private(set) var location: OpenLocationModel?
    private let locationIcon: UIImageView = UIImageView(image: UIImage.op_imageNamed("ema_location"))
    private let mainTitle: UILabel = UILabel()
    private let subTitle: UILabel = UILabel()
    private let currentLabel = TagWrapperView.titleTagView(for: .calendarCurrentLocation)
    private let bottomSeparatorLine = UIView()
    private var mainTitleCenterYContraint: Constraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        contentView.addSubview(currentLabel)
        contentView.addSubview(mainTitle)
        contentView.addSubview(subTitle)
        contentView.addSubview(locationIcon)
        contentView.addSubview(bottomSeparatorLine)
        mainTitle.font = UIFont.op_title(withSize: 16)
        mainTitle.textColor = UDColor.textTitle
        subTitle.font = UIFont.op_title(withSize: 14)
        subTitle.textColor = UDColor.textCaption
        locationIcon.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.centerY.equalTo(mainTitle.snp.centerY)
            make.left.equalTo(16)
        }

        currentLabel.isHidden = true
        currentLabel.snp.makeConstraints { (make) in
            make.width.greaterThanOrEqualTo(27)
            make.centerY.equalTo(mainTitle.snp.centerY)
            make.left.equalTo(mainTitle.snp.right).offset(5)
            make.right.lessThanOrEqualToSuperview().offset(-9)
        }

        mainTitle.snp.makeConstraints { (make) in
            make.left.equalTo(locationIcon.snp.right).offset(16)
            make.top.equalToSuperview().offset(12.5).priority(.medium)
            mainTitleCenterYContraint = make.centerY.equalToSuperview().priority(.low).constraint
        }

        subTitle.snp.makeConstraints { (make) in
            make.left.equalTo(locationIcon.snp.right).offset(16)
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-13)
        }

        bottomSeparatorLine.backgroundColor = UDColor.lineDividerDefault
        bottomSeparatorLine.snp.makeConstraints { (make) in
            make.left.equalTo(mainTitle.snp.left)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(location: OpenLocationModel, isCurrent: Bool = false) {
        self.location = location
        mainTitle.text = location.name
        subTitle.text = location.address

        if isCurrent || location.address.isEmpty {
            mainTitleCenterYContraint.update(priority: ConstraintPriority.high.value)
        } else {
            mainTitleCenterYContraint.update(priority: ConstraintPriority.low.value)
        }
        currentLabel.isHidden = !isCurrent
        subTitle.isHidden = isCurrent
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if !highlighted {
            self.backgroundColor = UDColor.bgBody
        } else {
            self.backgroundColor = UDColor.fillPressed
        }
    }

}
