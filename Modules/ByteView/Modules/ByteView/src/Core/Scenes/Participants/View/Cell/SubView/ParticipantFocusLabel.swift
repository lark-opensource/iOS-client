//
//  ParticipantFocusLabel.swift
//  ByteView
//
//  Created by wulv on 2022/2/25.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 焦点视频
class ParticipantFocusLabel: ParticipantBaseLabel {

    convenience init(isHidden: Bool, minWidth: CGFloat = 44, height: CGFloat = 18) {
        self.init(frame: .zero)
        backgroundColor = UIColor.ud.udtokenTagNeutralBgNormal
        textInsets = UIEdgeInsets(top: 0.0,
                                  left: 4.0,
                                  bottom: 0.0,
                                  right: 4.0)
        font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        textColor = UIColor.ud.udtokenTagNeutralTextNormal
        layer.cornerRadius = 4.0
        clipsToBounds = true
        text = I18n.View_MV_FocusVideo_UserYellowIcon
        setContentCompressionResistancePriority(ParticipantStatusPriority.focusVideo.priority, for: .horizontal)
        snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(minWidth)
            make.height.equalTo(height)
        }
        self.isHidden = isHidden
    }
}
