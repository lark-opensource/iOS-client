//
//  ReplyInThreadHeader.swift
//  LarkThread
//
//  Created by ByteDance on 2022/4/12.
//

import Foundation
import UIKit
import SnapKit
import LarkSearchFilter
final class ReplyInThreadHeader: UIView {

    private let tipLabel = UILabel()

    init(repliesCount: Int) {
        super.init(frame: .zero)
        setupUI()
        updateReplyCount(repliesCount)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        tipLabel.font = UIFont.systemFont(ofSize: 12)
        tipLabel.textColor = UIColor.ud.textPlaceholder
        tipLabel.text = BundleI18n.LarkThread.Lark_IM_Thread_NoReplies_Placeholder
        addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(line)
        line.snp.makeConstraints { make in
            make.left.equalTo(tipLabel.snp.right).offset(8)
            make.centerY.equalTo(tipLabel)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(1)
        }
    }

    private func updateReplyCount(_ replyCount: Int) {
        if replyCount > 0 {
            tipLabel.text = BundleI18n.LarkThread.Lark_IM_Thread_NumRepliesToThread_Tooltip(replyCount)
        } else {
            tipLabel.text = BundleI18n.LarkThread.Lark_IM_Thread_NoReplies_Placeholder
        }
    }
}
