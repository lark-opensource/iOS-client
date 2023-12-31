//
//  ParticipantNameTailLabel.swift
//  ByteView
//
//  Created by helijian on 2022/7/27.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

///  room参会人人数展示
class ParticipantRoomCountLabel: UILabel {

    var roomCountMessage: String? {
        didSet {
            if oldValue != roomCountMessage {
                update(roomCountMessage: roomCountMessage)
            }
        }
    }

    convenience init(isHidden: Bool, height: CGFloat = 20) {
        self.init(frame: .zero)
        backgroundColor = participantsBgColor
        textColor = UIColor.ud.textCaption
        font = UIFont.systemFont(ofSize: 17)
        setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        snp.makeConstraints { make in
            make.height.equalTo(height)
        }
        self.isHidden = isHidden
    }
}

// MARK: - Private
extension ParticipantRoomCountLabel {
    private func update(roomCountMessage: String?) {
        isHidden = roomCountMessage?.isEmpty != false
        text = roomCountMessage
    }
}
