//
//  CalendarDetailViewV1.swift
//  Calendar
//
//  Created by zhuheng on 2021/5/28.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import LarkDatePickerView
import UniverseDesignTheme
import UniverseDesignColor
import UniverseDesignEmpty

protocol CalendarDetailViewDataType {
    var title: String { get }
    var creatorName: String { get }
    var description: String { get }
    var isSubscribed: Bool { get }
}

final class LegacyCalendarDetailView: UIView, ViewDataReceiver {
    var creatorTapped: (() -> Void)?
    var buttonTapped: (() -> Void)?

    private lazy var icon: UIImageView = UIImageView(image: UIImage.cd.image(named: "icon_calendar_detail"))
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 17)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        return label
    }()
    private lazy var creatorLabel: UILabel = {
        let label = UILabel()
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(creatorClicked))
        label.addGestureRecognizer(tap)
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.textColor = UIColor.ud.N600
        label.numberOfLines = 0
        return label
    }()

    private lazy var operationButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 4
        button.layer.borderWidth = 1

        button.addTarget(self, action: #selector(operationButtonClicked), for: .touchUpInside)
        return button
    }()

    init() {
        super.init(frame: .zero)

        addSubview(icon)
        icon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().inset(16)
            make.width.height.equalTo(32)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(icon)
            make.left.equalTo(icon.snp.right).offset(13)
            make.right.equalToSuperview().offset(-16)
        }

        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(0.5)
            make.top.equalTo(icon.snp.bottom).offset(16)
        }

        addSubview(operationButton)
        addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(lineView)
            make.top.equalTo(lineView.snp.bottom).offset(16)
            make.bottom.lessThanOrEqualTo(operationButton.snp.top).offset(-12)
        }

        operationButton.snp.makeConstraints { make in
            make.left.right.equalTo(lineView)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-42)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(viewData: CalendarDetailViewDataType) {
        let data = viewData
        titleLabel.text = data.title

        let attrHeader = NSMutableAttributedString(
            string: I18n.Calendar_Calendar_Creator,
            attributes: [.font: UIFont.systemFont(ofSize: 16),
                         .foregroundColor: UIColor.ud.textTitle])

        let attrTail = NSAttributedString(string: data.creatorName,
                                          attributes: [.font: UIFont.systemFont(ofSize: 16),
                                                       .foregroundColor: UIColor.ud.colorfulBlue])
        attrHeader.append(attrTail)
        creatorLabel.attributedText = attrHeader

        descriptionLabel.text = data.description

        let isSubscribed = data.isSubscribed

        let borderColor = isSubscribed ? UIColor.ud.N300.cgColor : UIColor.clear.cgColor
        let title = isSubscribed ? I18n.Calendar_Calendar_ViewCalendarButton : I18n.Calendar_Calendar_SubscribeToCalendarButton
        let bgColor = isSubscribed ? UIColor.ud.N00 : UIColor.ud.colorfulBlue
        let titleColor = isSubscribed ? UIColor.ud.N900 : UIColor.ud.N00

        operationButton.layer.borderColor = borderColor
        operationButton.setTitle(title, for: .normal)
        operationButton.backgroundColor = bgColor
        operationButton.setTitleColor(titleColor, for: .normal)
    }
    @objc
    func creatorClicked () {
        creatorTapped?()
    }

    @objc
    func operationButtonClicked () {
        buttonTapped?()
    }

}

final class NoAccessCalendarDetailView: UIView {
    private let icon = UIImageView(image: UDEmptyType.noPreview.defaultImage())
    lazy var title: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.textColor = UIColor.ud.N600
        label.textAlignment = .center
        return label
    }()

    init() {
        super.init(frame: .zero)
        addSubview(icon)
        icon.snp.makeConstraints { make in
            make.width.height.equalTo(120)
            make.top.centerX.equalToSuperview()
        }

        addSubview(title)
        title.snp.makeConstraints { make in
            make.top.equalTo(icon.snp.bottom).offset(12)
            make.height.equalTo(20)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
