//
//  TimeZoneSearchQueryView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/17.
//

import UIKit
import SnapKit

final class TimeZoneSearchQueryView: UIView {

    lazy var textField: SearchTextField = {
        let textField = SearchTextField()
        textField.placeholder = BundleI18n.Calendar.Calendar_Timezone_Search
        textField.keyboardType = .webSearch
        return textField
    }()
    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.Calendar.Calendar_Common_Cancel, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(textField)
        textField.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.left.equalToSuperview().offset(16)
        }

        addSubview(cancelButton)
        cancelButton.snp.makeConstraints {
            $0.centerY.equalTo(textField)
            $0.left.equalTo(textField.snp.right).offset(16)
            $0.right.equalToSuperview().offset(-16)
        }

        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        cancelButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
