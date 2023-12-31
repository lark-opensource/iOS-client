//
//  MeetingNotesGuideView.swift
//  Calendar
//
//  Created by huoyunjie on 2023/8/22.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont
import LarkEmotion

class MeetingNotesGuideView: UIView {

    static let emojiKey = "StatusFlashOfInspiration"

    static let textColor: UIColor = UDColor.O600

    private lazy var iconImage: UIImageView = {
        let icon = EmotionResouce.shared.imageBy(key: Self.emojiKey)
        let view = UIImageView(image: icon)
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Self.textColor
        label.numberOfLines = 0
        label.setText(text: I18n.Calendar_G_CreateMeetingNotesOnboarding_Desc,
                      font: UDFont.body1,
                      lineHeight: 22)
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Self.textColor.withAlphaComponent(0.8)
        label.numberOfLines = 0
        label.setText(text: I18n.Calendar_G_UseAgendaBeMoreEfficient_Desc,
                      font: UDFont.caption1,
                      lineHeight: 18)
        return label
    }()

    private(set) lazy var closeButton: UIButton = {
        let closeIcon = UDIcon.closeOutlined.ud.withTintColor(Self.textColor.withAlphaComponent(0.8))
        let button = UIButton()
        button.setImage(closeIcon, for: .normal)
        button.increaseClickableArea(top: -12, left: -12, bottom: -12, right: -12)
        button.addTarget(self, action: #selector(closeClick), for: .touchUpInside)
        return button
    }()


    var closeAction: (() -> Void)?

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UDColor.O50

        let leftStackView = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel])
        leftStackView.axis = .vertical
        leftStackView.spacing = 0

        addSubview(iconImage)
        addSubview(leftStackView)
        addSubview(closeButton)

        iconImage.snp.makeConstraints { make in
            make.size.equalTo(18)
            make.top.equalToSuperview().inset(9)
            make.leading.equalToSuperview().inset(6)
        }

        leftStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(6)
            make.bottom.equalToSuperview().inset(8)
            make.trailing.equalToSuperview().inset(12)
            make.leading.equalTo(iconImage.snp.trailing).offset(6)
        }

        closeButton.snp.makeConstraints { make in
            make.size.equalTo(12)
            make.top.trailing.equalToSuperview().inset(6)
        }

        self.layer.cornerRadius = 8
        self.clipsToBounds = true
    }

    @objc
    private func closeClick() {
        closeAction?()
    }
}
