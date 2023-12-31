//
//  SubscribeNoMoreView.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/21.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import SnapKit

final class SubscribeNoMoreView: UIView {
    static let defaultHeight: CGFloat = 40.0
    let titleLable: UILabel = {
        let titleLable = UILabel()
        titleLable.textColor = UIColor.ud.textPlaceholder
        titleLable.font = UIFont.cd.font(ofSize: 12)
        return titleLable
    }()

    init(title: String = BundleI18n.Calendar.Calendar_SubscribeCalendar_NoMoreCal) {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: SubscribeNoMoreView.defaultHeight))
        titleLable.text = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layout(in: titleLable, in: self)
    }

    private func layout(in title: UILabel, in superView: UIView) {
        superView.addSubview(title)
        title.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

}
