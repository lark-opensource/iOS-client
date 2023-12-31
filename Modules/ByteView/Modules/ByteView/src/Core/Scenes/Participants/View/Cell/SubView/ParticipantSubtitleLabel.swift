//
//  ParticipantSubtitleLabel.swift
//  ByteView
//
//  Created by wulv on 2022/3/3.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 子标题
class ParticipantSubtitleLabel: UILabel {

    var subtitle: String? {
        didSet {
            if oldValue != subtitle {
                update(subtitle: subtitle)
            }
        }
    }

    convenience init(isHidden: Bool, height: CGFloat = 20) {
        self.init(frame: .zero)
        backgroundColor = participantsBgColor
        font = UIFont.systemFont(ofSize: 14)
        textColor = UIColor.ud.textPlaceholder
        snp.makeConstraints { make in
            make.height.equalTo(height)
        }
        self.isHidden = isHidden
        setContentCompressionResistancePriority(ParticipantStatusPriority.subtitle.priority, for: .horizontal)
    }
}

// MARK: - Private
extension ParticipantSubtitleLabel {
    private func update(subtitle: String?) {
        text = subtitle
        isHidden = subtitle?.isEmpty != false
    }
}
