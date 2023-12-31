//
//  ParticipantInterpretLabel.swift
//  Logger
//
//  Created by wulv on 2022/2/25.
//

import Foundation

/// 传译标签
class ParticipantInterpretLabel: ParticipantBaseLabel {

    var interpret: String? {
        didSet {
            if oldValue != interpret {
                update(interpret: interpret)
            }
        }
    }

    convenience init(isHidden: Bool, minWidth: CGFloat = 44, height: CGFloat = 18) {
        self.init(frame: .zero)
        textInsets = UIEdgeInsets(top: 0.0,
                                  left: 4.0,
                                  bottom: 0.0,
                                  right: 4.0)
        font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        textColor = UIColor.ud.udtokenTagNeutralTextNormal
        backgroundColor = UIColor.ud.udtokenTagNeutralBgNormal
        lineBreakMode = .byTruncatingTail
        layer.cornerRadius = 4.0
        clipsToBounds = true
        setContentCompressionResistancePriority(ParticipantStatusPriority.interpretation.priority, for: .horizontal)
        snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(minWidth)
            make.height.equalTo(height)
        }
        self.isHidden = isHidden
    }
}

// MARK: - Private
extension ParticipantInterpretLabel {
    private func update(interpret: String?) {
        text = interpret
        isHidden = interpret?.isEmpty != false
    }
}
