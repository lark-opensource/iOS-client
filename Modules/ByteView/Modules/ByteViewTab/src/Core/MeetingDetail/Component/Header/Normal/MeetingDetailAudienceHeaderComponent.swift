//
//  MeetingDetailAudienceHeaderComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/24.
//

import Foundation
import UniverseDesignIcon
import ByteViewNetwork

class MeetingDetailAudienceHeaderComponent: MeetingDetailHeaderComponent {

    lazy var audienceView: UIStackView = {
        let audienceView = UIStackView()
        audienceView.axis = .horizontal
        audienceView.spacing = 12
        audienceView.alignment = .center
        return audienceView
    }()

    lazy var audienceLabel: UILabel = {
        let audienceLabel = UILabel()
        audienceLabel.font = .systemFont(ofSize: 14)
        audienceLabel.textColor = UIColor.ud.textCaption
        audienceLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return audienceLabel
    }()

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.audienceInfo.addObserver(self)
    }

    override func setupViews() {
        super.setupViews()

        addSubview(audienceView)
        audienceView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.greaterThanOrEqualTo(20)
        }

        let audienceIcon = UIImageView()
        audienceIcon.image = UDIcon.getIconByKey(.communityTabOutlined, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16))
        audienceView.addArrangedSubview(audienceIcon)
        audienceIcon.snp.makeConstraints {
            $0.width.height.equalTo(16)
        }

        audienceView.addArrangedSubview(audienceLabel)
    }

    override var shouldShow: Bool {
        viewModel?.isWebinarSpeaker == true
    }

    override func updateViews() {
        super.updateViews()

        guard let viewModel = viewModel, let audienceInfo = viewModel.audienceInfo.value else { return }
        audienceLabel.attributedText = .init(string: I18n.View_G_AttendeeWithNum(audienceInfo.audienceNum),
                                             config: .bodyAssist,
                                             textColor: .ud.textTitle)
    }
}

extension MeetingDetailAudienceHeaderComponent: MeetingDetailAudienceInfoObserver {
    func didReceive(data: AudienceInfo) {
        updateViews()
    }
}
