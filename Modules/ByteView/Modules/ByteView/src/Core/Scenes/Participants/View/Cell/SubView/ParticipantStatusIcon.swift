//
//  ParticipantStatusIcon.swift
//  ByteView
//
//  Created by lutingting on 2022/8/31.
//

import Foundation
import UIKit

class ParticipantLeaveIcon: ParticipantImageView {

    convenience init(isHidden: Bool) {
        self.init(frame: .zero)
        self.key = .leave
        self.isHidden = isHidden
    }
}

class ParticipantStatusHandsUpIcon: ParticipantImageView {

    convenience init(isHidden: Bool) {
        self.init(frame: .zero)
        self.key = .handsUp("")
        self.isHidden = isHidden
    }
}
