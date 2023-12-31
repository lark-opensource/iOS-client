//
//  SendRedPacketFormCell.swift
//  LarkFinance
//
//  Created by JackZhao on 2021/11/23.
//

import Foundation
import LarkUIKit
import SnapKit
import RxCocoa
import RxSwift
import RichLabel
import UIKit
import UniverseDesignColor

class SendRedPacketFormCell: SendRedPacketBaseCell, UITextFieldDelegate {

    let titleBgView: UIView = UIView()
    let titleLabel: UILabel = UILabel()
    let unitLabel: UILabel = UILabel()
    let contentField: UITextField = UITextField()
    let detailLabel: LKLabel = LKLabel()

    override func setupCellContent() {
        self.contentView.addSubview(titleBgView)
        titleBgView.backgroundColor = UIColor.ud.bgBody
        titleBgView.layer.cornerRadius = 10
        titleBgView.layer.masksToBounds = true
        titleBgView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalToSuperview()
            $0.height.equalTo(48)
        }

        titleBgView.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(16)
            maker.centerY.equalToSuperview()
        }

        titleBgView.addSubview(unitLabel)
        unitLabel.font = UIFont.systemFont(ofSize: 16)
        unitLabel.textColor = UIColor.ud.N900
        unitLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        unitLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        unitLabel.snp.makeConstraints { (maker) in
            maker.right.equalTo(-16)
            maker.centerY.equalToSuperview()
        }

        titleBgView.addSubview(self.contentField)
        self.contentField.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(titleLabel.snp.right).offset(8)
            maker.right.equalTo(unitLabel.snp.left).offset(-8)
            maker.height.equalTo(40)
        }
        contentField.textAlignment = .right
        contentField.font = UIFont.systemFont(ofSize: 16)
        contentField.delegate = self

        self.contentView.addSubview(detailLabel)
        detailLabel.font = UIFont.systemFont(ofSize: 16)
        detailLabel.numberOfLines = 0
        detailLabel.backgroundColor = UIColor.clear
        detailLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 48
        detailLabel.snp.makeConstraints { (maker) in
            maker.right.equalTo(-32)
            maker.left.equalTo(32)
            maker.top.equalTo(self.titleBgView.snp.bottom).offset(4)
            maker.bottom.equalTo(-16)
        }
    }

    override func updateCellContent(_ result: RedPacketCheckResult) {
        self.updateErrorLabel()
    }

    func resultError() -> SendRedPacketError? {
        return nil
    }

    func updateErrorLabel() {
        if let error = self.resultError() {
            self.contentField.textColor = redPacketRed
        } else {
            self.contentField.textColor = UIColor.ud.N900
        }
    }
}
