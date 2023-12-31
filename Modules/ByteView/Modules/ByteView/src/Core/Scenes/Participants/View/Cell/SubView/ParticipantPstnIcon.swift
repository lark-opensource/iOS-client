//
//  ParticipantPstnIcon.swift
//  ByteView
//
//  Created by wulv on 2023/11/27.
//

import Foundation
import UIKit

/// pstn标识(CallMe/快捷电话邀请)
class ParticipantPstnIcon: ParticipantImageView {

    convenience init(isHidden: Bool) {
        self.init(frame: .zero)
        self.key = .conveniencePstn
        self.isHidden = isHidden
    }
}
