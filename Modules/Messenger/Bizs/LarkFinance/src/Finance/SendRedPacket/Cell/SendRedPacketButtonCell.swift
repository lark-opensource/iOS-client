//
//  SendRedPacketButtonCell.swift
//  LarkFinance
//
//  Created by JackZhao on 2021/11/23.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignColor

final class SendRedPacketButtonCell: SendRedPacketBaseCell {

    var sendRedPacketBlock: (() -> Void)?
    var sendRedPacketEnable: () -> Bool = { return false }

    fileprivate let clickButton: UIButton = UIButton()

    override func setupCellContent() {
        self.contentView.addSubview(clickButton)
        clickButton.accessibilityIdentifier = "send_red_packet"
        clickButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.sendRedPacketBlock?()
        }).disposed(by: self.disposeBag)
        clickButton.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.top.bottom.equalToSuperview().inset(28)
            maker.height.equalTo(48)
        }
        clickButton.setTitle(BundleI18n.LarkFinance.Lark_Legacy_SendNow, for: .normal)
        clickButton.setTitleColor(UIColor.ud.Y200.alwaysLight, for: .normal)
        clickButton.setTitleColor(UDColor.udtokenBtnPriTextDisabled, for: .disabled)
        clickButton.setBackgroundImage(UIImage.ud.fromPureColor(redPacketRed), for: .normal)
        clickButton.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.functionDangerFillSolid03), for: .disabled)
        clickButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        clickButton.layer.cornerRadius = 6
        clickButton.layer.masksToBounds = true
    }

    override func updateCellContent(_ result: RedPacketCheckResult) {
        let sendEnable = result.errors.isEmpty &&
            ((result.content.type == .p2P && result.content.totalAmount != nil) ||
            (result.content.type == .groupRandom && result.content.totalAmount != nil && result.content.totalNum != nil) ||
            (result.content.type == .groupFix && result.content.singleAmount != nil && result.content.totalNum != nil) ||
             (result.content.type == .exclusive && result.content.singleAmount != nil && result.content.totalNum != nil))

        self.clickButton.isEnabled = sendEnable
    }
}
