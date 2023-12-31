//
//  ParticipantMobileCallingStatusView.swift
//  ByteView
//
//  Created by ShuaiZipei on 2022/11/8.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignTheme

/// 系统电话标识
class ParticipantSystemCallingView: ParticipantImageView {
    convenience init(isHidden: Bool) {
        self.init(frame: .zero)
        self.key = .systemCalling
        self.isHidden = isHidden
        let viewColor = UIColor.ud.N900.withAlphaComponent(0.3)
        backgroundColor = viewColor
        layer.cornerRadius = 20
        clipsToBounds = true
        contentMode = .center
    }
}
