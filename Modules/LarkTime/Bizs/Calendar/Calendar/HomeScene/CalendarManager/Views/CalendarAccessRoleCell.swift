//
//  CalendarAccessRoleCell.swift
//  Calendar
//
//  Created by heng zhu on 2019/3/23.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import SnapKit
import UniverseDesignIcon

final class CalendarAccessRoleCell: UIControl {
    private let titleLable = UILabel.cd.textLabel()
    private let icon = UIImageView(image: UDIcon.getIconByKey(.listCheckColorful,
                                                              renderingMode: .alwaysOriginal,
                                                              size: CGSize(width: 16, height: 16)))
    private let subTitleLable: UILabel = {
        let label = UILabel.cd.subTitleLabel()
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 2
        return label
    }()

    init(title: String, subTitle: String, withBottomBorder: Bool = true) {
        super.init(frame: .zero)
        self.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(68)
        }

        titleLable.text = title
        subTitleLable.text = subTitle
        icon.isHidden = true
        layout(icon: icon)
        layout(title: titleLable)
        layout(subTitle: subTitleLable)
        if withBottomBorder {
            addBottomBorder(inset: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0))
        }
    }

    public func update(isSelected: Bool) {
        icon.isHidden = !isSelected
    }

    private func layout(icon: UIView) {
        addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
    }

    private func layout(title: UIView) {
        addSubview(title)
        title.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(11)
            make.right.equalTo(icon.snp.left).offset(-16)
        }
    }

    private func layout(subTitle: UIView) {
        addSubview(subTitle)
        subTitle.snp.makeConstraints { (make) in
            make.top.equalTo(titleLable.snp.bottom)
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-11)
            make.right.equalTo(icon.snp.left).offset(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
