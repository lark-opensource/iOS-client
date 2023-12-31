//
//  CalendarManagerAddCalMemberView.swift
//  Calendar
//
//  Created by harry zou on 2019/3/22.
//

import UIKit
import SnapKit
import UniverseDesignIcon
import CalendarFoundation
final class AddCalendarMemberView: UIControl, AddBottomLineAble {
    private let addIcon = UIImageView(image: UDIcon.getIconByKey(.addnewOutlined,
                                                                 iconColor: UIColor.ud.primaryContentDefault,
                                                                 size: CGSize(width: 20, height: 20)))
    private let title: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = BundleI18n.Calendar.Calendar_Setting_AddSharingMembers
        titleLabel.textColor = UIColor.ud.primaryContentDefault
        return titleLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
        layout(addIcon: addIcon)
        layout(title: title, leftConstraint: addIcon.snp.right)
        // layout UI here
    }

    private func layout(addIcon: UIView) {
        addSubview(addIcon)
        addIcon.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.top.bottom.equalToSuperview().inset(17)
        }
    }

    private func layout(title: UILabel, leftConstraint: ConstraintItem) {
        addSubview(title)
        title.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(leftConstraint).offset(16)
            make.right.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol AddBottomLineAble {

}

extension AddBottomLineAble where Self: UIView {
    func addBottomLine(_ leftBorderWidth: CGFloat = 52) {
        let border = addBottomBorder(inset: UIEdgeInsets(top: 0, left: leftBorderWidth, bottom: 0, right: 0),
                                     lineHeight: 0.5)
        border.backgroundColor = UIColor.ud.lineDividerDefault
    }
}
