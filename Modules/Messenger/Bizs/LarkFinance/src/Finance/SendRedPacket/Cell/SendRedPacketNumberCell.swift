//
//  SendRedPacketNumberCell.swift
//  Action
//
//  Created by lichen on 2018/10/29.
//

import Foundation
import LarkUIKit
import SnapKit
import RxCocoa
import RxSwift
import RichLabel
import UIKit
import UniverseDesignColor

final class SendRedPacketNumberCell: SendRedPacketFormCell {

    var numberChangeBlock: ((String?) -> Void)?

    var chatNumber: Int = 0 {
        didSet {
            let numberStr = BundleI18n.LarkFinance.Lark_Legacy_MemberCount(chatNumber)
            self.detailLabel.attributedText = NSAttributedString(
                string: numberStr,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): UIColor.ud.textPlaceholder
                ]
            )
            self.detailLabel.textColor = UIColor.ud.textPlaceholder
        }
    }

    override func setupCellContent() {
        super.setupCellContent()

        let placeHolderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.ud.textPlaceholder
        ]
        self.contentField.accessibilityIdentifier = "send_red_number"
        self.contentField.attributedPlaceholder = NSAttributedString(string: BundleI18n.LarkFinance.Lark_Legacy_EnterNumber, attributes: placeHolderAttributes)
        self.unitLabel.text = BundleI18n.LarkFinance.Lark_Legacy_Count
        self.titleLabel.text = BundleI18n.LarkFinance.Lark_Legacy_Quantity
        self.contentField.keyboardType = .numberPad
        self.contentField.rx.text.subscribe(onNext: { [weak self] (text) in
            self?.numberChangeBlock?(text)
        }).disposed(by: self.disposeBag)
    }

    override func updateCellContent(_ result: RedPacketCheckResult) {
        super.updateCellContent(result)
        if let totalNum = result.content.totalNum {
            self.contentField.text = "\(totalNum)"
        }
    }

    override func resultError() -> SendRedPacketError? {
        if let result = self.result, let error = result.errors.first(where: { (err) -> Bool in
            switch err {
            case .money:
                return false
            case .number:
                return true
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
            // 判断是不是整数
            let pointRange = (newString as NSString).range(of: ".")
            if pointRange.location != NSNotFound {
                return false
            }

            // 判断最长输入限制
            if newValue > 99_999 {
                return false
            }

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
