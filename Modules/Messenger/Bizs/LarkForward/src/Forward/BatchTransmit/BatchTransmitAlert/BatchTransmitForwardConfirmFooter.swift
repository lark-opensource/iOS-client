//
//  BatchTransmitConfirmFooter.swift
//  LarkForward
//
//  Created by ByteDance on 2022/8/11.
//

import UIKit
import Foundation

// nolint: duplicated_code -- 代码可读性治理无QA，不做复杂修改
// TODO: 转发内容预览能力组件内置时优化该逻辑
final class BatchTransmitForwardConfirmFooter: BaseTapForwardConfirmFooter {
    let title: String
    init(title: String,
         previewFg: Bool = false) {
        self.title = title

        super.init()

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.N900
        self.addSubview(label)
        if previewFg {
            self.addSubview(nextImageView)
            nextImageView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-10)
                make.width.equalTo(7)
                make.height.equalTo(12)
            }
        }
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: previewFg ? 32 : 10))
        }

        label.text = "[\(BundleI18n.LarkForward.Lark_Chat_OneByOneForwardButton)] \(title)"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class BatchTransmitOldForwardConfirmFooter: BaseForwardConfirmFooter {
    let title: String
    init(title: String) {
        self.title = title

        super.init()

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 4
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.iconN1
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }

        label.text = "[\(BundleI18n.LarkForward.Lark_Chat_OneByOneForwardButton)]\(title)"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
