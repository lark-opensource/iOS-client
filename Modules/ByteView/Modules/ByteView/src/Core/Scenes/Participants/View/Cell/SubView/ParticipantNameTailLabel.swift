//
//  ParticipantNameTailLabel.swift
//  ByteView
//
//  Created by wulv on 2022/2/24.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

/// 小尾巴，展示(me、访客等)文案
class ParticipantNameTailLabel: UILabel {

    var nameTail: String? {
        didSet {
            if oldValue != nameTail {
                update(nameTail: nameTail)
            }
        }
    }

    convenience init(isHidden: Bool, height: CGFloat = 20) {
        self.init(frame: .zero)
        backgroundColor = participantsBgColor
        textColor = UIColor.ud.textTitle
        font = UIFont.systemFont(ofSize: 17)
        setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        snp.makeConstraints { make in
            make.height.equalTo(height)
        }
        self.isHidden = isHidden
    }
}

// MARK: - Private
extension ParticipantNameTailLabel {
    private func update(nameTail: String?) {
        text = nameTail
    }
}
