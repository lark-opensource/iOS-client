//
//  SetLabelNameInputCell.swift
//  LarkSpaceKit
//
//  Created by zhangxingcheng on 2021/7/27.
//

import Foundation
import UIKit
import RxSwift
import SnapKit
import LarkUIKit
import UniverseDesignColor

enum SetInputContentStatus {
    // 编辑栏为空
    case editEmpty
    // 编辑栏不为空
    case editWithContent
}

class SetLabelNameInputCell: UITableViewCell {

    typealias EditInputStatusBlock = (_ setInputContentStatus: SetInputContentStatus) -> Void

    /**（0）编辑状态block*/
    var editInputStatusBlock: EditInputStatusBlock?

    /**（1）TextView*/
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.clipsToBounds = true
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = UDColor.N900
        textView.backgroundColor = UDColor.bgBody
        return textView
    }()

    /**（2）限制Label*/
    private var limitLabel: UILabel = UILabel()
    /**（3）提示Label*/
    private var tipsView: UIView = UIView()
    /**（4）提示Label*/
    private var tipsLabel: UILabel = UILabel()
    /**（5）限制12*/
    private let limitNum: Int = 12

    var inputModel: SetLabelNameInputModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.backgroundColor = UDColor.bgBody

        self.contentView.addSubview(self.textView)
        self.textView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.height.equalTo(96)
        }

        self.contentView.addSubview(self.limitLabel)
        self.limitLabel.textColor = UDColor.N500
        self.limitLabel.text = "0/\(self.limitNum)"
        self.limitLabel.font = UIFont.systemFont(ofSize: 12)
        self.limitLabel.textAlignment = .right
        self.limitLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.textView.snp.bottom).offset(2)
            make.right.equalToSuperview().offset(-16)
            make.width.equalTo(100)
            make.height.equalTo(18)
        }

        self.contentView.addSubview(self.tipsView)
        self.tipsView.backgroundColor = UDColor.bgBase
        self.tipsView.snp.makeConstraints { (make) in
            make.top.equalTo(self.limitLabel.snp.bottom).offset(8)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(24)
        }

        self.tipsView.addSubview(self.tipsLabel)
        self.tipsLabel.backgroundColor = UDColor.bgBase
        self.tipsLabel.textColor = UDColor.functionDangerContentDefault
        self.tipsLabel.text = BundleI18n.CCMMod.Lark_Groups_TabNameErrorMsg
        self.tipsLabel.font = UIFont.ud.body1
        self.tipsLabel.textAlignment = .left
        self.tipsLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(4)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.height.equalTo(18)
        }
        self.tipsLabel.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setCellModel(_ inputModel: SetLabelNameInputModel) {
        self.inputModel = inputModel
        if inputModel.textViewInputString.count > self.limitNum {
            textView.text = String(inputModel.textViewInputString.prefix(self.limitNum))
            textView.text.append("...")
            self.tipsLabel.isHidden = false
        } else {
            self.textView.text = inputModel.textViewInputString
            self.tipsLabel.isHidden = true
        }
        self.textViewDidChange(self.textView)
    }
}

extension SetLabelNameInputCell: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        // /获取高亮部分
        let selectedRange = textView.markedTextRange
        let pos = textView.position(from: textView.beginningOfDocument, offset: 0)

        /// 如果在变化中是高亮部分在变，就不要计算字符了
        if (selectedRange != nil) && (pos != nil) {
            return
        }

        if textView.text.count > 30 {
            textView.text = String(textView.text.prefix(30))
        }

        if textView.text.count > self.limitNum {
            let limitMutAttributeString = NSMutableAttributedString(
                string: "\(textView.text.count)/\(self.limitNum)",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.ud.N500
                ])
            limitMutAttributeString.setAttributes(
                [NSAttributedString.Key.foregroundColor: UDColor.colorfulRed],
                range: NSRange(location: 0, length: 2)
            )
            limitMutAttributeString.setAttributes(
                [NSAttributedString.Key.foregroundColor: UDColor.N500],
                range: NSRange(location: 2, length: limitMutAttributeString.string.count - 2)
            )
            self.limitLabel.attributedText = limitMutAttributeString
        } else {
            let limitMutAttributeString = NSMutableAttributedString(
                string: "\(textView.text.count)/\(self.limitNum)",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.ud.N500
                ])
            limitMutAttributeString.setAttributes(
                [NSAttributedString.Key.foregroundColor: UDColor.N500],
                range: NSRange(location: 0, length: limitMutAttributeString.string.count)
            )
            self.limitLabel.attributedText = limitMutAttributeString
        }

        if self.editInputStatusBlock != nil {
            if textView.text.isEmpty {
                self.editInputStatusBlock?(.editEmpty)
            } else {
                self.editInputStatusBlock?(.editWithContent)
            }
        }

        if self.inputModel != nil {
            if textView.text.count > self.limitNum {
                self.inputModel?.textViewInputString = String(textView.text.prefix(self.limitNum))
                self.inputModel?.textViewInputString.append("...")
                self.tipsLabel.isHidden = false
            } else {
                self.inputModel?.textViewInputString = textView.text
                self.tipsLabel.isHidden = true
            }
        }
    }
}
