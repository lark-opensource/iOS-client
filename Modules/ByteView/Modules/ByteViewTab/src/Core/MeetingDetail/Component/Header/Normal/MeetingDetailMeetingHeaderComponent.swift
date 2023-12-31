//
//  MeetingDetailMeetingHeaderComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/24.
//

import Foundation
import UniverseDesignIcon

class MeetingDetailMeetingHeaderComponent: MeetingDetailHeaderComponent {

    lazy var meetingView: UIStackView = {
        let meetingView = UIStackView()
        meetingView.axis = .horizontal
        meetingView.spacing = 12
        meetingView.alignment = .center
        return meetingView
    }()

    lazy var meetingNumberLabel: UILabel = {
        let meetingNumberLabel = UILabel()
        meetingNumberLabel.font = .systemFont(ofSize: 14)
        meetingNumberLabel.textColor = UIColor.ud.textCaption
        meetingNumberLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return meetingNumberLabel
    }()

    override func setupViews() {
        super.setupViews()

        addSubview(meetingView)
        meetingView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.greaterThanOrEqualTo(20)
        }

        let meetingIcon = UIImageView()
        meetingIcon.image = UDIcon.getIconByKey(.infoOutlined, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16))
        meetingView.addArrangedSubview(meetingIcon)
        meetingIcon.snp.makeConstraints {
            $0.width.height.equalTo(16)
        }

        meetingView.addArrangedSubview(meetingNumberLabel)
    }

    override var shouldShow: Bool {
        viewModel?.meetingNumber?.isEmpty == false
    }

    override func updateViews() {
        super.updateViews()

        guard let viewModel = viewModel, let meetingNumber = viewModel.meetingNumber else { return }

        meetingNumberLabel.attributedText = .init(string: "\(I18n.View_MV_MeetingIdentification) \(Util.formatMeetingNumber(meetingNumber))",
                                                  config: .bodyAssist,
                                                  textColor: .ud.textTitle)
    }
}
