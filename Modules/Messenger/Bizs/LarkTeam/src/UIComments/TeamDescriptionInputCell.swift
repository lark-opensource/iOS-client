//
//  TeamDescriptionInputCell.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/8/10.
//

import UIKit
import Foundation
import RxRelay
import RxSwift
import UniverseDesignInput

// MARK: - 团队描述输入 - viewModel
final class TeamDescriptionInputViewModel: TeamCellViewModelProtocol {
    var type: TeamCellType
    var cellIdentifier: String
    var style: TeamCellSeparaterStyle
    var maxCharLength: Int
    var title: NSAttributedString
    var text: String?
    var placeholder: String
    var errorToast: String?
    var tapHandler: TeamCellTapHandler?
    var reloadWithAnimation: (Bool) -> Void
    private(set) var rightItemEnableRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    var rightItemEnableOb: Observable<Bool> { rightItemEnableRelay.asObservable() }
    var textFieldDidEndEditingTask: TextFieldTask?

    init(type: TeamCellType,
         cellIdentifier: String,
         style: TeamCellSeparaterStyle,
         title: NSAttributedString,
         maxCharLength: Int,
         placeholder: String,
         errorToast: String?,
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
        self.textFieldDidEndEditingTask = textFieldDidEndEditingTask
    }

    func updateContent(_ text: String?) {
        self.text = text
        rightItemEnableRelay.accept(text?.checked(maxChatLength: maxCharLength) ?? false)
    }
}

// MARK: - 团队描述输入 - cell
final class TeamDescriptionInputCell: TeamBaseCell, UDMultilineTextFieldDelegate {
    private let disposeBag = DisposeBag()
    private var inputTextViewMaxH: CGFloat = 57

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    private(set) lazy var inputTextView: UDMultilineTextField = {
        let inputTextView = UDMultilineTextField()
        inputTextView.config.font = UIFont.systemFont(ofSize: 16)
        inputTextView.config.textMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return inputTextView
    }()

    private(set) var countLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.font = .systemFont(ofSize: 12)
        return label
    }()

    // 错误提示
    private var errorDescription: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.colorfulRed
        label.isUserInteractionEnabled = true
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        contentView.addSubview(titleLabel)
        contentView.addSubview(inputTextView)
        contentView.addSubview(countLabel)
        contentView.addSubview(errorDescription)

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(13)
            make.right.equalTo(-16)
        }

        inputTextView.delegate = self
        inputTextView.snp.makeConstraints { (make) in
            make.left.equalTo(12)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.height.equalTo(inputTextViewMaxH)
            make.right.equalTo(-16)
        }

        countLabel.snp.makeConstraints { (make) in
            make.top.equalTo(inputTextView.snp.bottom).offset(2)
            make.right.equalTo(-16)
            make.height.equalTo(0)
        }

        errorDescription.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(countLabel.snp.bottom).offset(16)
            make.bottom.equalToSuperview()
        }
    }

    override func setCellInfo() {
        guard let item = item as? TeamDescriptionInputViewModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.attributedText = item.title
        inputTextView.placeholder = item.placeholder
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = item as? TeamDescriptionInputViewModel {
            item.tapHandler?(self)
        }
        super.setSelected(selected, animated: animated)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        // 聚焦时隐藏Error提示
        showErrorMessage(isShow: false)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        guard let item = item as? TeamDescriptionInputViewModel else { return }
        showErrorMessage(isShow: !(textView.text?.isChecked ?? false), errorToast: item.errorToast)
    }

    func textViewDidChange(_ textView: UITextView) {
        guard let item = item as? TeamDescriptionInputViewModel else { return }
        item.updateContent(textView.text)
        if let text = textView.text, text.count > item.maxCharLength {
            let attr = NSMutableAttributedString(string: "\(text.count)",
                                                 attributes: [.foregroundColor: UIColor.ud.colorfulRed])
            attr.append(NSAttributedString(string: "/\(item.maxCharLength)",
                                           attributes: [.foregroundColor: UIColor.ud.N500]))
            self.setCountLabel(textCount: attr, tryHidden: false)
        } else {
            self.setCountLabel(tryHidden: true)
        }
    }

    private func showErrorMessage(isShow: Bool, errorToast: String? = nil) {
        if let errorText = errorToast, !errorText.isEmpty, isShow {
            errorDescription.text = errorText
            errorDescription.snp.remakeConstraints { (make) in
                make.leading.trailing.equalTo(titleLabel)
                make.top.equalTo(countLabel.snp.bottom).offset(6)
                make.bottom.equalToSuperview().offset(-13)
            }
        } else {
            errorDescription.text = ""
            errorDescription.snp.remakeConstraints { (make) in
                make.leading.trailing.equalTo(titleLabel)
                make.top.equalTo(countLabel.snp.bottom).offset(16)
                make.height.equalTo(0)
                make.bottom.equalToSuperview()
            }
        }
        guard let item = item as? TeamDescriptionInputViewModel else { return }
        item.reloadWithAnimation(true)
    }

    func setCountLabel(textCount: NSAttributedString? = nil,
                       tryHidden: Bool) {
        if let text = textCount {
            countLabel.attributedText = textCount
        }
        if tryHidden != countLabel.isHidden {
            countLabel.isHidden = tryHidden
            countLabel.snp.updateConstraints { make in
                make.height.equalTo(tryHidden ? 0 : 18)
            }
            (item as? TeamDescriptionInputViewModel)?.reloadWithAnimation(false)
        }
    }
}
