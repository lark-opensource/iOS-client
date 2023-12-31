//
//  MeetingDetailLoopHeaderComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/24.
//

import Foundation
import ByteViewNetwork
import UniverseDesignIcon

class MeetingDetailLoopHeaderComponent: MeetingDetailHeaderComponent {

    lazy var loopEventView: UIStackView = {
        let loopEventView = UIStackView()
        loopEventView.axis = .horizontal
        loopEventView.spacing = 12
        loopEventView.alignment = .top
        return loopEventView
    }()

    lazy var loopEventLabel: UILabel = {
        let loopEventLabel = UILabel()
        loopEventLabel.font = .systemFont(ofSize: 14)
        loopEventLabel.textColor = UIColor.ud.textTitle
        loopEventLabel.numberOfLines = 0
        loopEventLabel.lineBreakMode = .byTruncatingTail
        loopEventLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return loopEventLabel
    }()

    override func setupViews() {
        super.setupViews()

        addSubview(loopEventView)

        loopEventView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.greaterThanOrEqualTo(20)
        }

        let loopEventIconContainer = UIView()
        let loopEventIcon = UIImageView()
        loopEventIcon.image = UDIcon.getIconByKey(.repeatOutlined, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16))
        loopEventIconContainer.addSubview(loopEventIcon)
        loopEventIcon.snp.makeConstraints {
            $0.top.equalToSuperview().offset(2)
            $0.left.equalToSuperview()
            $0.width.height.equalTo(16)
        }

        loopEventView.addArrangedSubview(loopEventIconContainer)
        loopEventIconContainer.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.width.equalTo(16)
            $0.height.equalTo(20)
        }

        loopEventView.addArrangedSubview(loopEventLabel)
        loopEventLabel.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(20)
        }
    }

    override var shouldShow: Bool {
        viewModel?.calendarEventRule?.isEmpty == false && viewModel?.isValid1v1Call == false
    }

    override func updateViews() {
        super.updateViews()

        guard let viewModel = viewModel, let calendarEventRule = viewModel.calendarEventRule else { return }
        let rRuleDetail = DateUtil.formatRRuleString(rrule: calendarEventRule, userId: viewModel.userId)
        loopEventLabel.attributedText = .init(string: rRuleDetail,
                                              config: .bodyAssist,
                                              textColor: .ud.textTitle)
    }
}
