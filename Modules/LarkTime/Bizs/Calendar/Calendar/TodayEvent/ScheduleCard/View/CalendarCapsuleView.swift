//
//  CalendarCapsuleView.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/7.
//

import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignIcon

class CalendarCapsule: UIView {
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.caption1
        label.textColor = UDColor.textCaption
        label.text = BundleI18n.Calendar.Calendar_Meeting_Event
        return label
    }()

    lazy var iconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.orange
        view.layer.cornerRadius = 10
        return view
    }()

    lazy var icon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.calendarFilled.colorImage(UDColor.staticWhite)
        return imageView
    }()

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UDColor.N9005
        setupView()
    }

    private func setupView() {
        self.layer.cornerRadius = 12

        let containerInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 8)
        self.addSubview(textLabel)
        self.addSubview(iconContainer)
        iconContainer.addSubview(icon)

        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(4)
            make.height.equalTo(20)
            make.top.bottom.trailing.equalToSuperview().inset(containerInsets)
        }
        iconContainer.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.top.bottom.leading.equalToSuperview().inset(containerInsets)
        }
        icon.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
            make.width.height.equalTo(12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
