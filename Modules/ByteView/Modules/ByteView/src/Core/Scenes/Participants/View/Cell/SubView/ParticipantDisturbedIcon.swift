//
//  ParticipantDisturbedIcon.swift
//  ByteView
//
//  Created by wulv on 2022/3/3.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

/// 勿扰
class ParticipantDisturbedIcon: ParticipantImageView {

    convenience init(isHidden: Bool) {
        self.init(frame: .zero)
        key = .disturbed
        setContentHuggingPriority(.sceneSizeStayPut, for: .horizontal)
        setContentCompressionResistancePriority(.sceneSizeStayPut, for: .horizontal)
        self.isHidden = isHidden
    }
}
