//
//  ThreadDetailHeader.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/3/2.
//

import UIKit
import Foundation

final class ThreadDetailHeader: UIView {

    enum Cons {
        static var titleFont: UIFont { return UIFont.ud.title3 }
        static var titleColor: UIColor { return UIColor.ud.textTitle }
        static var headerHeight: CGFloat { return titleFont.pointSize + 33 }
    }

    private let replysCountLabel = UILabel(frame: .zero)

    init(repliesCount: Int) {
        super.init(frame: .zero)

        self.backgroundColor = UIColor.ud.bgBody

        let label = UILabel(frame: .zero)
        label.text = BundleI18n.LarkThread.Lark_Chat_Topic_DetailPage_Replies_Title
        label.font = Cons.titleFont
        label.textColor = Cons.titleColor
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }

        replysCountLabel.isHidden = true
        replysCountLabel.text = BundleI18n.LarkThread.Lark_Chat_Topic_DetailPage_Replies_Title
        replysCountLabel.font = Cons.titleFont
        replysCountLabel.textColor = Cons.titleColor
        replysCountLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.addSubview(replysCountLabel)
        replysCountLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(label)
            make.leading.equalTo(label.snp.trailing).offset(4)
            make.trailing.lessThanOrEqualTo(-16)
        }

        self.updateRepliesCount(repliesCount)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateRepliesCount(_ repliesCount: Int) {
        if repliesCount > 0 {
            replysCountLabel.isHidden = false
            replysCountLabel.text = String(repliesCount)
        } else {
            replysCountLabel.isHidden = true
        }
    }
}
