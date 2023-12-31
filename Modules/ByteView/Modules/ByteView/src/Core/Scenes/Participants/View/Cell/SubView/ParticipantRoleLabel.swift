//
//  ParticipantRoleLabel.swift
//  ByteView
//
//  Created by wulv on 2022/2/24.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 主持人/联席主持人标签
class ParticipantRoleLabel: ParticipantBaseLabel {

    var config: ParticipantRoleConfig? {
        didSet {
            if oldValue != config {
                update(config: config)
            }
        }
    }

    convenience init(isHidden: Bool, height: CGFloat = 18, minWidth: CGFloat = 35) {
        self.init(frame: .zero)
        backgroundColor = UIColor.ud.udtokenTagNeutralBgInverse
        textInsets = UIEdgeInsets(top: 0.0,
                                  left: 4.0,
                                  bottom: 0.0,
                                  right: 4.0)
        font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        textAlignment = .center
        contentMode = .center
        adjustsFontSizeToFitWidth = true
        baselineAdjustment = .alignCenters
        layer.cornerRadius = 4.0
        clipsToBounds = true
        setContentCompressionResistancePriority(ParticipantStatusPriority.hostTag.priority, for: .horizontal)
        snp.makeConstraints { make in
            make.height.equalTo(height)
            make.width.greaterThanOrEqualTo(minWidth)
        }
        self.isHidden = isHidden
    }
}

// MARK: - Private
extension ParticipantRoleLabel {
    private func update(config: ParticipantRoleConfig?) {
        text = config?.role
        isHidden = config?.role?.isEmpty != false
        backgroundColor = config?.tagBgColor
        textColor = config?.textColor
        if let w = config?.minWidth {
            snp.updateConstraints { make in
                make.width.greaterThanOrEqualTo(w)
            }
        }
    }
}
