//
//  SetBoardcastCells.swift
//  Moment
//
//  Created by zc09v on 2021/3/10.
//

import UIKit
import Foundation
import LarkUIKit
import EditTextView

final class SetBoardcastWithTextCell: UITableViewCell {
    static let indentify: String = "SetBoardcastWithTextCellIndentify"
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.ud.N900
        label.numberOfLines = 1
        return label
    }()

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        label.numberOfLines = 1
        return label
    }()

    private let arrowImageView: UIImageView = {
        let arrowImageView = UIImageView()
        arrowImageView.image = Resources.rightArrow
        return arrowImageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(contentLabel)
        self.contentView.addSubview(arrowImageView)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-20)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualTo(arrowImageView.snp.left).offset(-12)
            make.bottom.equalToSuperview().offset(-10)
        }
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(contentLabel.snp.centerY)
            make.right.equalToSuperview().offset(-20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, content: String, contentTextColor: UIColor) {
        self.titleLabel.text = title
        self.contentLabel.text = content
        self.contentLabel.textColor = contentTextColor
    }
}

protocol SetBoardcastWithInputCellDelegate: AnyObject {
    func textReachLimit(maxLength: Int)
    func current(text: String)
}

final class SetBoardcastWithInputCell: UITableViewCell {
    static let indentify: String = "SetBoardcastWithInputCell"
    private let maxLength = 30
    weak var delegate: SetBoardcastWithInputCellDelegate?

    lazy var inputBecomeFirstResponder: () -> Void = {
        return { [weak self] in
            self?.baseTextField.becomeFirstResponder()
        }
    }()

    lazy var inputResignFirstResponder: () -> Void = {
        return { [weak self] in
            self?.baseTextField.resignFirstResponder()
        }
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.ud.N900
        label.numberOfLines = 1
        return label
    }()

    lazy var baseTextField: BaseTextField = {
        let baseTextField = BaseTextField()
        baseTextField.textAlignment = .left
        baseTextField.font = UIFont.systemFont(ofSize: 16)
        baseTextField.textColor = UIColor.ud.N900
        baseTextField.clearButtonMode = .whileEditing
        baseTextField.attributedPlaceholder = NSAttributedString(string: BundleI18n.Moment.Lark_Community_MaximumCharacters("\(maxLength)"),
                                                                 attributes: [.foregroundColor: UIColor.ud.N500])
        baseTextField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        return baseTextField
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(baseTextField)

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-20)
        }
        baseTextField.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, content: String) {
        self.titleLabel.text = title
        self.baseTextField.text = content
    }

    func cut(_ text: String) -> (Bool, String) {
        var lengthExceed = false
        if text.count > self.maxLength {
            lengthExceed = true
        }
        return (lengthExceed, lengthExceed ? text.substring(to: self.maxLength) : text)
    }

    @objc
    fileprivate func editingChanged() {
        guard let text = baseTextField.text else {
            return
        }
        //如果正在输入联想，不做限制
        if let markedRange = baseTextField.markedTextRange,
           baseTextField.offset(from: markedRange.start, to: markedRange.end) != 0 {
            return
        }
        let (lengthExceed, result) = cut(text)
        if lengthExceed {
            self.baseTextField.text = result
            self.delegate?.textReachLimit(maxLength: self.maxLength)
            self.delegate?.current(text: result)
        } else {
            self.delegate?.current(text: result)
        }
    }
}
