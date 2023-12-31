//
//  CalendarMemberTitleView.swift
//  Calendar
//
//  Created by harry zou on 2019/4/8.
//

import UIKit
import Foundation
import CalendarFoundation

final class CalendarMemberTitleView: UIView {
    let title = UILabel()

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        title.numberOfLines = 1
        title.text = BundleI18n.Calendar.Calendar_Setting_SharingMembers
        title.textColor = UIColor.ud.textTitle
        addSubview(title)
        title.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(18)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-8)
            make.right.lessThanOrEqualToSuperview()
        }
        self.addTopBorder()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
