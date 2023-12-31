//
//  PinConfirmContainerView.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/9/14.
//

import Foundation
import UIKit
import LarkCore
import LarkModel
import LarkExtensions

class PinAlertViewModel {
    var senderName: String {
        guard let chatter = self.message.fromChatter else {
            return ""
        }
        return getSenderName(chatter)
    }
    var sendTime: TimeInterval {
        return self.message.createTime
    }

    let message: Message
    let getSenderName: (Chatter) -> String

    init(message: Message, getSenderName: @escaping (Chatter) -> String) {
        self.message = message
        self.getSenderName = getSenderName
    }
}

class PinConfirmContainerView: UIView {
    private(set) var nameLabel: UILabel = .init()
    private(set) var timeLabel: UILabel = .init()

    var alertViewModel: PinAlertViewModel? {
        didSet {
            if let source = alertViewModel {
                let creatTime = Date(timeIntervalSince1970: source.sendTime).lf.formatedTime_v2()
                self.nameLabel.text = source.senderName
                self.timeLabel.text = " " + BundleI18n.LarkChat.Lark_Legacy_PinPostAt + " " + creatTime
                self.setPinConfirmContentView(source)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.ud.N100
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true

        let nameLabel = UILabel()
        nameLabel.textColor = UIColor.ud.N500
        nameLabel.font = UIFont.systemFont(ofSize: 12)
        nameLabel.textAlignment = .left
        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(BubbleLayout.commonInset.left)
            make.bottom.equalTo(-BubbleLayout.commonInset.bottom)
        }
        self.nameLabel = nameLabel

        let timeLabel = UILabel()
        timeLabel.textColor = UIColor.ud.N500
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textAlignment = .left
        timeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        self.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.right)
            make.bottom.equalTo(-BubbleLayout.commonInset.bottom)
            make.right.lessThanOrEqualTo(-BubbleLayout.commonInset.right)
        }
        self.timeLabel = timeLabel
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        /// 子类实现
    }
}
