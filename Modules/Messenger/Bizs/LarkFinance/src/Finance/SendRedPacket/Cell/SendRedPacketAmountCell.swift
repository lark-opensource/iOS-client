//
//  SendRedPacketAmountCell.swift
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

final class SendRedPacketAmountCell: SendRedPacketBaseCell {

    fileprivate let titleLabel: UILabel = UILabel()
    fileprivate let unitLabel: UILabel = UILabel()
    fileprivate let errorView: UIView = UIView()
    fileprivate let errorLabel: UILabel = UILabel()

    override func setupCellContent() {
        self.contentView.addSubview(titleLabel)
        if let font = UIFont(name: "DINAlternate-Bold", size: 40) {
            titleLabel.font = font
        } else {
            titleLabel.font = UIFont.systemFont(ofSize: 40)
        }
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.accessibilityIdentifier = "send_red_total amount"
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(42)
            maker.bottom.equalTo(-24)
            maker.center.equalToSuperview()
        }

        self.contentView.addSubview(unitLabel)
        unitLabel.font = UIFont.systemFont(ofSize: 16)
        unitLabel.text = BundleI18n.LarkFinance.Lark_Legacy_SendHongbaoMoneyUnit
        unitLabel.textColor = UIColor.ud.N900
        unitLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(titleLabel.snp.right).offset(4)
            maker.firstBaseline.equalTo(titleLabel)
        }

        self.contentView.addSubview(errorView)
        errorView.backgroundColor = UIColor.ud.R100
        errorView.snp.makeConstraints {
            $0.leading.trailing.top.equalToSuperview()
        }
        errorView.isHidden = true

        errorView.addSubview(errorLabel)
        errorLabel.font = .systemFont(ofSize: 14)
        errorLabel.textAlignment = .center
        errorLabel.textColor = redPacketRed
        errorLabel.numberOfLines = 2
        errorLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(8)
            $0.right.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-6)
        }
        errorLabel.isHidden = true
    }

    override func updateCellContent(_ result: RedPacketCheckResult) {
        if let sum = result.content.totalAmount {
            switch result.content.type {
            case .exclusive, .groupFix, .groupRandom, .p2P:
                self.titleLabel.text = String(format: "%.2f", Double(sum) / 100)
            case .commercial, .unknown:
                self.titleLabel.text = "0.00"
            case .b2CRandom, .b2CFix:
                self.titleLabel.text = "0.00"
            @unknown default:
                assertionFailure("unknown type")
                self.titleLabel.text = "0.00"
            }
        } else {
            self.titleLabel.text = "0.00"
        }
        updateErrorLabel()
    }

    func updateErrorLabel() {
        var displayError: SendRedPacketError?
        if let errors = result?.errors, !errors.isEmpty {
            if errors.count == 1 {
                displayError = errors.first
            } else {
                // 有两个错误时，优先展示第一个错误
                displayError = errors.first(where: { (err) -> Bool in
                    switch err {
                    case .money:
                        return true
                    case .number:
                        return false
                    }
                })
            }
        }
        if let displayError = displayError {
            errorLabel.text = displayError.description
            errorView.isHidden = false
            errorLabel.isHidden = false
        } else {
            errorView.isHidden = true
            errorLabel.isHidden = true
        }
    }
}
