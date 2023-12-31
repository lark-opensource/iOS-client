//
//  MeetingDetailGuestHeaderComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/24.
//

import Foundation
import UniverseDesignIcon
import ByteViewNetwork

class MeetingDetailGuestHeaderComponent: MeetingDetailParticipantHeaderComponent {

    lazy var guestLabel: UILabel = {
        let guestLabel = UILabel()
        guestLabel.font = .systemFont(ofSize: 14)
        guestLabel.textColor = UIColor.ud.textCaption
        guestLabel.setContentHuggingPriority(.required, for: .horizontal)
        guestLabel.attributedText = .init(string: I18n.View_G_PanelistColon,
                                          config: .bodyAssist,
                                          textColor: .ud.textTitle)
        return guestLabel
    }()

    override func setupViews() {
        super.setupViews()

        let guestIcon = UIImageView()
        guestIcon.image = UDIcon.getIconByKey(.webinarOutlined, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16))
        addSubview(guestIcon)
        guestIcon.snp.makeConstraints {
            $0.width.height.equalTo(16)
            $0.left.centerY.equalToSuperview()
        }

        addSubview(guestLabel)
        guestLabel.snp.makeConstraints {
            $0.left.equalTo(guestIcon.snp.right).offset(12.0)
            $0.centerY.equalToSuperview()
        }

        addSubview(previewView)
        previewView.snp.makeConstraints {
            $0.left.equalTo(guestLabel.snp.right).offset(12.0)
            $0.top.bottom.equalToSuperview()
        }
    }

    override var shouldShow: Bool {
        viewModel?.isWebinarSpeaker == true
    }
}
