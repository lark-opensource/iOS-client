//
//  ParticipantShareIcon.swift
//  ByteView
//
//  Created by wulv on 2022/2/24.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

/// 共享标识
class ParticipantShareIcon: ParticipantImageView {

    convenience init(isHidden: Bool) {
        self.init(frame: .zero)
        self.key = .share
        self.isHidden = isHidden
    }
}
