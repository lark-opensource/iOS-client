//
//  ParticipantHandsUpLabel.swift
//  ByteView
//
//  Created by wulv on 2022/2/25.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewUI

/// 申请发言
class ParticipantHandsUpLabel: UIView {

    private var textConfig: VCFontConfig = .bodyAssist

    private var priority: UILayoutPriority = ParticipantStatusPriority.askToSpeak.priority

    private lazy var containerView: UIStackView = {
        let containerView = UIStackView()
        containerView.axis = .horizontal
        containerView.spacing = 4.0
        containerView.alignment = .fill
        containerView.distribution = .equalSpacing
        return containerView
    }()

    convenience init(isHidden: Bool, minWidth: CGFloat = 30, height: CGFloat = 22) {
        self.init(frame: .zero)
        backgroundColor = participantsBgColor
        setContentCompressionResistancePriority(priority, for: .horizontal)
        addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(minWidth)
            make.height.equalTo(height)
        }
        self.isHidden = isHidden
    }

    private func addLine() {
        let lineContainer = UIView()
        let line = UIView()
        line.backgroundColor = UIColor.ud.textPlaceholder
        lineContainer.addSubview(line)
        containerView.addArrangedSubview(lineContainer)
        line.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(1.0)
            $0.height.equalTo(14.0)
        }
    }

    private func createLabel(_ text: String, priority: UILayoutPriority) -> UILabel {
        let label = UILabel()
        label.attributedText = .init(
            string: text,
            config: textConfig,
            alignment: .left,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.ud.textPlaceholder
        )
        label.setContentCompressionResistancePriority(priority, for: .horizontal)
        return label
    }

    func setText(isMicrophone: Bool = false, isCamera: Bool = false, isLocalRecord: Bool = false) {
        containerView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        if isMicrophone {
            containerView.addArrangedSubview(createLabel(I18n.View_M_WantsToSpeak, priority: priority - 1))
            if isCamera || isLocalRecord {
                addLine()
            }
        }
        if isCamera {
            containerView.addArrangedSubview(createLabel(I18n.View_G_RequestingCamOnState, priority: priority - 2))
            if isLocalRecord {
                addLine()
            }
        }
        if isLocalRecord {
            containerView.addArrangedSubview(createLabel(I18n.View_G_RequestLocalRecordStatus, priority: priority - 3))
        }
    }
}
