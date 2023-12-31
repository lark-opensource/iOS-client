//
//  TeamInputCell.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/4.
//

import UIKit
import Foundation
import RxRelay
import RxSwift

typealias TextFieldTask = (String, @escaping (Bool, String?) -> Void) -> Void

// MARK: - 输入 - viewModel
final class TeamInputCellViewModel: TeamCellViewModelProtocol {
    var type: TeamCellType
    var cellIdentifier: String
    var style: TeamCellSeparaterStyle
    var maxCharLength: Int
    var title: NSAttributedString
    var text: String?
    var placeholder: String
    var tapHandler: TeamCellTapHandler?
    var errorToast: String
    var reloadWithAnimation: (Bool) -> Void
    private(set) var rightItemEnableRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    var rightItemEnableOb: Observable<Bool> { rightItemEnableRelay.asObservable() }
    let inputEnabled: Bool
    let content: String?
    var textFieldDidEndEditingTask: TextFieldTask?

    init(type: TeamCellType,
         cellIdentifier: String,
         style: TeamCellSeparaterStyle,
         title: NSAttributedString,
         maxCharLength: Int,
         placeholder: String,
         errorToast: String,
         inputEnabled: Bool = true,
         content: String? = nil,
         reloadWithAnimation: @escaping (Bool) -> Void,
         tapHandler: TeamCellTapHandler? = nil,
         textFieldDidEndEditingTask: TextFieldTask? = nil) {
        self.type = type
        self.title = title
        self.cellIdentifier = cellIdentifier
        self.style = style
        self.maxCharLength = maxCharLength
        self.placeholder = placeholder
        self.errorToast = errorToast
        self.reloadWithAnimation = reloadWithAnimation
        self.tapHandler = tapHandler
        self.inputEnabled = inputEnabled
        self.content = content
        self.textFieldDidEndEditingTask = textFieldDidEndEditingTask
    }

    func updateContent(_ text: String?) {
        self.text = text
        rightItemEnableRelay.accept(text?.checked(maxChatLength: maxCharLength) ?? false)
    }

    // 失焦时校验
    func check(text: String?, callBack: @escaping ((Bool, String?) -> Void)) {
        guard let text = text, text.isChecked else {
            callBack(false, errorToast)
            return
        }
        textFieldDidEndEditingTask?(text) { isAvalible, errorToast in
            DispatchQueue.main.async {
                callBack(isAvalible, errorToast)
            }
        }
    }
}

extension String {
    func preHandle() -> String {
        // 去掉字符串首尾多余的空格
        var temp = self.trimmingCharacters(in: .whitespacesAndNewlines)
        // 去掉字符串中的换行
        temp = self.replacingOccurrences(of: "\n", with: " ", options: .literal, range: nil)
        temp = temp.replacingOccurrences(of: "\r", with: " ", options: .literal, range: nil)
        return temp
    }

    var removeCharSpace: String {
        var temp = preHandle()
        let matchs = temp.components(separatedBy: " ").filter({ !$0.isEmpty })
        guard !matchs.isEmpty else { return "" }
        return matchs.joined(separator: " ")
    }

    var isChecked: Bool {
        return !removeCharSpace.isEmpty
    }

    func checked(maxChatLength: Int) -> Bool {
        return isChecked && (count <= maxChatLength)
    }
}

// MARK: - 输入 - cell
final class TeamInputCell: TeamBaseCell, UITextFieldDelegate {
    private var textFiledIsBecomeFirstResponder = false

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    private(set) var textField: UITextField = {
        let textField = UITextField()
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.font = .systemFont(ofSize: 16)
        return textField
    }()

    // 错误提示
    private var errorDescription: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.colorfulRed
        label.isUserInteractionEnabled = true
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        contentView.addSubview(titleLabel)
        contentView.addSubview(textField)
        contentView.addSubview(errorDescription)

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(13)
            make.right.equalTo(-16)
        }

        textField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        textField.delegate = self
        textField.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.right.equalTo(-16)
            make.height.equalTo(22)
        }

        errorDescription.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(textField)
            make.top.equalTo(textField.snp.bottom).offset(16)
            make.height.equalTo(0)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func cellForRowTask() {
        if !textField.isFirstResponder, !textFiledIsBecomeFirstResponder {
            textField.becomeFirstResponder()
            textFiledIsBecomeFirstResponder.toggle()
        }
    }

    override func setCellInfo() {
        guard let item = item as? TeamInputCellViewModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        textField.isEnabled = item.inputEnabled
        if let content = item.content {
            textField.text = content
        }
        titleLabel.attributedText = item.title
        textField.attributedPlaceholder = NSAttributedString(string: item.placeholder,
                                                             attributes: [.font: UIFont.ud.body0,
                                                                          .foregroundColor: UIColor.ud.textPlaceholder])
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = item as? TeamInputCellViewModel {
            item.tapHandler?(self)
        }
        super.setSelected(selected, animated: animated)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        // 聚焦时隐藏Error提示
        showErrorMessage(isShow: false)
    }

    @objc
    func textDidChange(_ textField: UITextField) {
        guard let item = item as? TeamInputCellViewModel else { return }
        if let text = textField.text, text.count > item.maxCharLength {
            textField.text = String(text.prefix(item.maxCharLength))
        }
        item.updateContent(textField.text)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let item = item as? TeamInputCellViewModel else { return }
        item.check(text: textField.text, callBack: { [weak self] isAvalible, errorToast in
            self?.showErrorMessage(isShow: !isAvalible, errorToast: errorToast)
        })
    }
}

extension TeamInputCell {

    private func showErrorMessage(isShow: Bool, errorToast: String? = nil) {
        if let errorText = errorToast, !errorText.isEmpty, isShow {
            errorDescription.text = errorToast
            errorDescription.snp.remakeConstraints { (make) in
                make.leading.trailing.equalTo(textField)
                make.top.equalTo(textField.snp.bottom).offset(6)
                make.bottom.equalToSuperview().offset(-13)
            }
        } else {
            errorDescription.text = ""
            errorDescription.snp.remakeConstraints { (make) in
                make.leading.trailing.equalTo(textField)
                make.top.equalTo(textField.snp.bottom).offset(16)
                make.height.equalTo(0)
                make.bottom.equalToSuperview()
            }
        }
        guard let item = item as? TeamDescriptionInputViewModel else { return }
        item.reloadWithAnimation(true)
    }
}
