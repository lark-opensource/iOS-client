//
//  UnknownPinConfirmView.swift
//  LarkChat
//
//  Created by zc09v on 2022/5/26.
//

import UIKit
import Foundation
import LarkModel

final class UnknownPinConfirmViewModel: PinAlertViewModel {
}

final class UnknownPinConfirmView: PinConfirmContainerView {
    private let contentLabel: UILabel = UILabel(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(contentLabel)
        contentLabel.text = BundleI18n.LarkChat.Lark_Legacy_UnknownMessageTypeTip()
        contentLabel.numberOfLines = 0
        contentLabel.textColor = UIColor.ud.N900
        contentLabel.font = UIFont.systemFont(ofSize: 16)
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(BubbleLayout.commonInset.top)
            make.left.equalTo(BubbleLayout.commonInset.left)
            make.right.equalTo(-BubbleLayout.commonInset.right)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)
    }
}
