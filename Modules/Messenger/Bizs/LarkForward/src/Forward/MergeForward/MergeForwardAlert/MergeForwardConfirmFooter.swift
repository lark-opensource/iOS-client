//
//  MergeForwardConfirmFooter.swift
//  LarkForward
//
//  Created by zc09v on 2018/8/6.
//

import UIKit
import Foundation
import LarkModel

final class MergeForwardConfirmFooter: BaseForwardConfirmFooter {
    let title: String
    init(title: String) {
        self.title = title

        super.init()

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 4
        label.lineBreakMode = .byTruncatingTail
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }

        label.text = "\(BundleI18n.LarkForward.Lark_Legacy_MergeForwardDialogPrefix)\(title)"
    }

    convenience init(message: Message) {
        let content = message.content as? MergeForwardContent
        self.init(title: content?.title ?? "")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ForwardMergeMessageConfirmFooter: BaseTapForwardConfirmFooter {
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

        label.text = "\(BundleI18n.LarkForward.Lark_Legacy_MergeForwardDialogPrefix) \(title)"
    }

    convenience init(message: Message, previewFg: Bool = false) {
        let content = message.content as? MergeForwardContent
        self.init(title: content?.title ?? "", previewFg: previewFg)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ForwardMergeMessageOldConfirmFooter: BaseForwardConfirmFooter {
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

        label.text = "\(BundleI18n.LarkForward.Lark_Legacy_MergeForwardDialogPrefix)\(title)"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
