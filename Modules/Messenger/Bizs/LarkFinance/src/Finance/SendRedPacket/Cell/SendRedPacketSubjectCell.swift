//
//  SendRedPacketSubjectCell.swift
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

final class SendRedPacketSubjectCell: SendRedPacketBaseCell, UITextFieldDelegate {

    var subjectChangeBlock: ((String) -> Void)?
    var maxCount: Int = 50

    fileprivate let subjectField: UITextField = UITextField()
    fileprivate let bgView: UIView = UIView()
    fileprivate let placeHolderAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 16),
        .foregroundColor: UIColor.ud.textPlaceholder
    ]

    override func setupCellContent() {
        self.contentView.addSubview(self.bgView)
        bgView.backgroundColor = UIColor.ud.bgBody
        bgView.layer.cornerRadius = 10
        bgView.layer.masksToBounds = true
        self.bgView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview()
        }

        self.bgView.addSubview(self.subjectField)
        self.subjectField.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.height.equalTo(48)
        }
        subjectField.textAlignment = .left
        subjectField.font = UIFont.systemFont(ofSize: 16)
        subjectField.textColor = UIColor.ud.N900
        subjectField.accessibilityIdentifier = "send_red_subject"

        subjectField.rx.text.subscribe(onNext: { [weak self] (text) in
            self?.subjectChangeBlock?(text ?? "")
        }).disposed(by: self.disposeBag)

        subjectField.delegate = self
    }

    func setCellContent(placeholder: String,
                        textFieldText: String) {
        subjectField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: placeHolderAttributes)
        subjectField.text = textFieldText
    }

    override func updateCellContent(_ result: RedPacketCheckResult) {
        if subjectField.text != result.content.subject {
            subjectField.text = result.content.subject
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text ?? ""
        let nsText = text as NSString
        let newString = nsText.replacingCharacters(in: range, with: string)
        if newString.count > self.maxCount {
            return false
        }
        return true
    }
}
