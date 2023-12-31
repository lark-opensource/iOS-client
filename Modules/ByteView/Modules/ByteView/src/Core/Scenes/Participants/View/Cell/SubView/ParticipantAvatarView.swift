//
//  ParticipantAvatarView.swift
//  ByteView
//
//  Created by wulv on 2022/2/21.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import UIKit
import ByteViewUI

/// 头像(含红点)
class ParticipantAvatarView: UIView {

    static let Size: CGSize = CGSize(width: 40, height: 40)

    var avatarInfo: AvatarInfo? {
        didSet {
            if oldValue != avatarInfo {
                update(avatarInfo: avatarInfo)
            }
        }
    }
    var showRedDot: Bool = false {
        didSet {
            if oldValue != showRedDot {
                update(showRedDot: showRedDot)
            }
        }
    }
    var tapAction: (() -> Void)? {
        didSet {
            update(tapAction: tapAction)
        }
    }

    private lazy var _avatar = AvatarView(style: .circle)

    private lazy var _redDot: CALayer = {
        let layer = CALayer()
        layer.frame = CGRect(origin: .zero, size: CGSize(width: 10, height: 10))
        layer.cornerRadius = 10 / 2
        layer.ud.setBackgroundColor(UIColor.ud.colorfulRed, bindTo: self)
        return layer
    }()

    convenience init(isHidden: Bool, size: CGSize = ParticipantAvatarView.Size) {
        self.init(frame: .zero)
        backgroundColor = participantsBgColor
        addSubview(_avatar)
        _avatar.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        layer.addSublayer(_redDot)
        _redDot.frame.origin = CGPoint(x: 28, y: 2)
        _redDot.isHidden = !showRedDot
        self.isHidden = isHidden
        snp.makeConstraints { make in
            make.size.equalTo(size)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if _avatar.frame != bounds {
            _avatar.frame = bounds
        }
    }
}

// MARK: - Private
extension ParticipantAvatarView {
    private func update(avatarInfo: AvatarInfo?) {
        if let avatarInfo = avatarInfo {
            _avatar.setTinyAvatar(avatarInfo)
        } else {
            _avatar.setAvatarInfo(.asset(nil))
        }
    }

    private func update(showRedDot: Bool) {
        _redDot.isHidden = !showRedDot
    }

    private func update(tapAction: (() -> Void)?) {
        _avatar.setTapAction(tapAction)
    }
}
