//
//  CalendarEditOperationButton.swift
//  Calendar
//
//  Created by Hongbin Liang on 3/24/23.
//

import Foundation
import UIKit
import UniverseDesignIcon

class CalendarEditOperationButton: EventBasicCellLikeView.BackgroundView {
    let label = UILabel()

    var onClick: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColors = (UIColor.ud.panelBgColor, UIColor.ud.fillPressed)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        let clickGesture = UITapGestureRecognizer(target: self, action: #selector(buttonClicked))
        addGestureRecognizer(clickGesture)
    }

    func setTitle(with text: String, color: UIColor) {
        label.text = text
        label.textColor = color
    }

    @objc
    private func buttonClicked() {
        onClick?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CalendarEditAddButton: EventBasicCellLikeView.BackgroundView {

    var onClick: (() -> Void)?

    lazy var iconView: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.addOutlined, iconColor: .ud.primaryContentDefault))
        return imageView
    }()

    private(set) lazy var label: UILabel = {
        let label = UILabel.cd.textLabel()
        label.text = I18n.Calendar_Setting_AddSharingMembersClick
        label.textColor = .ud.primaryContentDefault
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColors = (UIColor.ud.panelBgColor, UIColor.ud.fillPressed)
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        addSubview(label)
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(4)
        }
        let clickGesture = UITapGestureRecognizer(target: self, action: #selector(buttonClicked))
        addGestureRecognizer(clickGesture)
    }

    @objc
    private func buttonClicked() {
        onClick?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
