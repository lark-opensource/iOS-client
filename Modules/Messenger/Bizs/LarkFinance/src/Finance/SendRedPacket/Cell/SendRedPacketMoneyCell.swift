//
//  SendRedPacketMoneyCell.swift
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

final class SendRedPacketMoneyCell: SendRedPacketFormCell {

    var moneyChangeBlock: ((String?) -> Void)?

    override func setupCellContent() {
        super.setupCellContent()

        let placeHolderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.ud.textPlaceholder
        ]
        self.contentField.attributedPlaceholder = NSAttributedString(string: "0.00", attributes: placeHolderAttributes)
        self.unitLabel.text = BundleI18n.LarkFinance.Lark_Legacy_SendHongbaoMoneyUnit
        self.titleLabel.text = BundleI18n.LarkFinance.Lark_Legacy_SendHongbaoAmountEach
        self.contentField.keyboardType = .numbersAndPunctuation
        self.contentField.accessibilityIdentifier = "send_red_money"
        self.contentField.rx.text.subscribe(onNext: { [weak self] (text) in
            guard let `self` = self else { return }

            if let text = text, text == "." {
                self.contentField.text = "0."
                let newPosition = self.contentField.endOfDocument
                self.contentField.selectedTextRange = self.contentField.textRange(from: newPosition, to: newPosition)
            } else {
                self.moneyChangeBlock?(text)
            }
        }).disposed(by: self.disposeBag)
    }

    override func updateCellContent(_ result: RedPacketCheckResult) {
        super.updateCellContent(result)

        switch result.content.type {
        case .p2P:
            self.titleLabel.text = BundleI18n.LarkFinance.Lark_Legacy_TotalAmount
            if let totalAmount = result.content.totalAmount {
                let value = Double(totalAmount) / 100
                if let text = self.contentField.text, let currentValue = Double(text), currentValue == value {
                } else {
                    self.contentField.text = String(format: "%.2f", value)
                }
            } else {
                self.contentField.text = nil
            }
        case .groupRandom:
            self.titleLabel.text = BundleI18n.LarkFinance.Lark_Legacy_TotalAmount

            if let totalAmount = result.content.totalAmount {
                let value = Double(totalAmount) / 100
                if let text = self.contentField.text, let currentValue = Double(text), currentValue == value {
                } else {
                    self.contentField.text = String(format: "%.2f", value)
                }
            } else {
                self.contentField.text = nil
            }
        case .groupFix:
            self.titleLabel.text = BundleI18n.LarkFinance.Lark_Legacy_SendHongbaoAmountEach

            if let singleAmount = result.content.singleAmount {
                let value = Double(singleAmount) / 100
                if let text = self.contentField.text, let currentValue = Double(text), currentValue == value {
                } else {
                    self.contentField.text = String(format: "%.2f", value)
                }
            } else {
                self.contentField.text = nil
            }
        case .exclusive:
            self.titleLabel.text = BundleI18n.LarkFinance.Lark_Legacy_SendHongbaoAmountEach
            if let singleAmount = result.content.singleAmount {
                let value = Double(singleAmount) / 100
                if let text = self.contentField.text, let currentValue = Double(text), currentValue == value {
                } else {
                    self.contentField.text = String(format: "%.2f", value)
                }
            } else {
                self.contentField.text = nil
            }
        case .unknown, .commercial:
            break
        case .b2CRandom, .b2CFix:
            break
        @unknown default:
            assert(false, "new value")
            break
        }
    }

    override func resultError() -> SendRedPacketError? {
        if let result = self.result, let error = result.errors.first(where: { (err) -> Bool in
            switch err {
            case .money:
                return true
            case .number:
                return false
            }
        }) {
            return error
        } else {
            return nil
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 删除
        if string.isEmpty { return true }

        // 新的字符串
        let text = textField.text ?? ""
        let nsText = text as NSString
        let newString = nsText.replacingCharacters(in: range, with: string)

        if let newValue = Double(newString) {
            let pointRange = (newString as NSString).range(of: ".")

            // 判断 . 后最多俩位小数
            if pointRange.location != NSNotFound {
                if newString.count - 1 - pointRange.location > 2 {
                    return false
                }
            }

            // 判断最长输入限制
            if newValue > 999_999.99 {
                return false
            }

            return true
        } else if newString == "." {
            return true
        } else {
            return false
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}
