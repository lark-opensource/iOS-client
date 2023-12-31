//
//  ParticipantNameLabel.swift
//  ByteView
//
//  Created by wulv on 2022/2/23.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 昵称
class ParticipantNameLabel: UILabel {

    var displayName: String? {
        didSet {
            if oldValue != displayName {
                update(displayName: displayName)
            }
        }
    }

    convenience init(isHidden: Bool, height: CGFloat = 20) {
        self.init(frame: .zero)
        backgroundColor = participantsBgColor
        textColor = UIColor.ud.textTitle
        font = UIFont.systemFont(ofSize: 17.0)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        snp.makeConstraints { make in
            make.height.equalTo(height)
        }
        self.isHidden = isHidden
    }
}

// MARK: - Private
extension ParticipantNameLabel {
    private func update(displayName: String?) {
        text = displayName
    }
}
