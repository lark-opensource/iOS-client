//
//  ParticipantJoinStateLabel.swift
//  ByteView
//
//  Created by wulv on 2022/7/21.
//

import Foundation
import UIKit

/// 入会状态（未加入会议）
class ParticipantJoinStateLabel: UILabel {

    enum State {
        case joined
        case idle

        var text: String? {
            switch self {
            case .joined: return nil
            case .idle: return I18n.View_G_NotJoined_StatusGrey
            }
        }
    }

    var state: State = .idle {
        didSet {
            if oldValue != state {
                update(state: state)
            }
        }
    }

    convenience init(isHidden: Bool, height: CGFloat = 24) {
        self.init(frame: .zero)
        backgroundColor = participantsBgColor
        textColor = UIColor.ud.textPlaceholder
        font = UIFont.systemFont(ofSize: 17)
        setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        snp.makeConstraints { make in
            make.height.equalTo(height)
        }
        update(state: .idle)
        self.isHidden = isHidden
    }
}

// MARK: - Private
extension ParticipantJoinStateLabel {
    private func update(state: State) {
        text = state.text
    }
}
