//
//  ParticipantFeedbackLabel.swift
//  ByteView
//
//  Created by wulv on 2022/6/7.
//

import Foundation


/// 呼叫反馈，展示(已拒绝、未接听等)文案
class ParticipantFeedbackLabel: UILabel {

    var feedback: String? {
        didSet {
            if oldValue != feedback {
                update(feedback: feedback)
            }
        }
    }

    convenience init(isHidden: Bool, height: CGFloat = 24) {
        self.init(frame: .zero)
        backgroundColor = participantsBgColor
        textColor = UIColor.ud.textPlaceholder
        font = UIFont.systemFont(ofSize: 17)
        snp.makeConstraints { make in
            make.height.equalTo(height)
        }
        self.isHidden = isHidden
    }
}

// MARK: - Private
extension ParticipantFeedbackLabel {
    private func update(feedback: String?) {
        text = feedback
        isHidden = feedback?.isEmpty != false
    }
}

class ParticipantRefuseReplyLabel: UILabel {
    var refuseReply: String? {
        didSet {
            if oldValue != refuseReply {
                update(refuseReply: refuseReply)
            }
        }
    }

    /// 拒绝回复是否部分展示
    var partialDisplay: Bool {
        guard !isHidden else {
            return false
        }
        if let refuseReply = refuseReply {
            let width = self.frame.width
            let height = self.frame.height
            let displayWidth = refuseReply.vc.boundingWidth(height: height, font: font)
            return width < displayWidth
        }
        return false
    }

    convenience init(isHidden: Bool, height: CGFloat = 20) {
        self.init(frame: .zero)
        backgroundColor = participantsBgColor
        textColor = UIColor.ud.textPlaceholder
        font = UIFont.systemFont(ofSize: 12)
        snp.makeConstraints { make in
            make.height.equalTo(height)
        }
        self.isHidden = isHidden
    }
}

// MARK: - Private
extension ParticipantRefuseReplyLabel {
    private func update(refuseReply: String?) {
        text = refuseReply
        isHidden = refuseReply?.isEmpty != false
    }
}
