//
//  ParticipantRecordIcon.swift
//  ByteView
//
//  Created by fakegourmet on 2023/3/20.
//

import Foundation

/// 录制标识
class ParticipantRecordIcon: ParticipantImageView {

    convenience init(isHidden: Bool) {
        self.init(frame: .zero)
        self.key = .localRecord
        self.isHidden = isHidden
    }
}
