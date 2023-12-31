//
//  FlagRecallMessageCell.swift
//  LarkFlag
//
//  Created by Fan Hui on 2022/5/31.
//

import UIKit
import Foundation
import LarkMessageCore

final class FlagRecallMessageCell: FlagMessageCell {
    override class var identifier: String {
        return FlagRecallMessageViewModel.identifier
    }

    public lazy var defaultLabel: UILabel = {
        let label = UILabel()
        label.font = Cons.nameFont
        label.textColor = UIColor.ud.textCaption
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .left
        return label
    }()

    override public func setupUI() {
        super.setupUI()
        self.isShowName = false
        self.contentWraper.addSubview(defaultLabel)
        self.contentWraper.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(Cons.contentTopMargin)
            make.right.equalToSuperview().offset(-Cons.contentInset)
        }

        self.defaultLabel.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(22)
        }

        self.defaultLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private lazy var lynxcardRenderFG: Bool = {
        guard let flagMessageVM = viewModel as? FlagMessageCellViewModel else { return false }
        return flagMessageVM.userResolver.fg.staticFeatureGatingValue(with: "lynxcard.client.render.enable")
    }()

    override public func updateCellContent() {
        super.updateCellContent()
        guard let flagMessageVM = viewModel as? FlagMessageCellViewModel else { return }
        self.defaultLabel.text = MessageSummarizeUtil.getSummarize(message: flagMessageVM.message,
                                                                   lynxcardRenderFG: lynxcardRenderFG)
    }
}
