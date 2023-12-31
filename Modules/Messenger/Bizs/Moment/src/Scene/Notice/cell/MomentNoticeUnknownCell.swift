//
//  MomentNoticeUnknownCell.swift
//  Moment
//
//  Created by bytedance on 2021/4/13.
//

import Foundation
import UIKit

final class MomentNoticeUnknownCell: MomentUserNotieBaseCell {

    override class func getCellReuseIdentifier() -> String {
        return "MomentNoticeUnknownCell"
    }

    override func layoutRightView(_ view: UIView) {
        view.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(0)
        }
    }

    override func updateRightViewWithVM(_ vm: MomentsNoticeBaseCellViewModel) {
        titleLabel.attributedText = NSAttributedString(string: "", attributes: nil)
        avatarView.isHidden = true
        titleLabel.isHidden = true
        timeLabel.isHidden = true
    }

}
