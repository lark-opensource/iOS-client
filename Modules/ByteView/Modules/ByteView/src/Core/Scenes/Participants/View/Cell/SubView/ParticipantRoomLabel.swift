//
//  ParticipantRoomLabel.swift
//  ByteView
//
//  Created by wulv on 2022/2/28.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 会议室地点
class ParticipantRoomLabel: UILabel {

    var room: String? {
        didSet {
            if oldValue != room {
                update(room: room)
            }
        }
    }

    convenience init(isHidden: Bool, height: CGFloat = 16) {
        self.init(frame: .zero)
        backgroundColor = participantsBgColor
        font = UIFont.systemFont(ofSize: 14)
        textColor = UIColor.ud.textPlaceholder
        setContentHuggingPriority(.defaultLow - 2, for: .horizontal)
        snp.makeConstraints { make in
            make.height.equalTo(height)
        }
        self.isHidden = isHidden
    }
}

// MARK: - Private
extension ParticipantRoomLabel {
    private func update(room: String?) {
        text = room
        isHidden = room?.isEmpty != false
    }
}
