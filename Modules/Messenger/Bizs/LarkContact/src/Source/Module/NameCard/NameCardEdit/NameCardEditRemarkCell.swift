//
//  NameCardEditRemarkCell.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/4/19.
//

import Foundation
import UIKit
import UniverseDesignInput

final class NameCardEditRemarkCell: UITableViewCell, UITextViewDelegate, NameCardEditCellProtocol {
    static let identifier: String = "NameCardEditRemarkCell"
    weak var delegate: NameCardEditCellDelegate?

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    private var textBgView: UIView = UIView()

    private var textView: UITextView = {
        let textView = UITextView()
        textView.textColor = UIColor.ud.textTitle
        textView.returnKeyType = .done
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = UIColor.ud.bgBody
        return textView
    }()

    private var errorDesc: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.functionDangerContentDefault
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    private var placeHolder: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.LarkContact.Lark_Contacts_ContactCardPleaseEnter
        label.font = .systemFont(ofSize: 16)
        label.contentMode = .top
        return label
    }()

    private var wordNumberLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = .systemFont(ofSize: 12)
        label.text = "0/1000"
        return label
    }()

    var cellVM: NameCardEditItemViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        contentView.addSubview(textBgView)
        textBgView.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.height.equalTo(120)
            make.top.equalTo(titleLabel.snp.bottom)
        }

        textBgView.addSubview(wordNumberLabel)
        wordNumberLabel.setContentHuggingPriority(.defaultHigh, for: .vertical) // 抗拉伸
        wordNumberLabel.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-8)
        }

        textView.delegate = self
        textBgView.addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel.snp.leading).offset(-textView.textContainer.lineFragmentPadding)
            make.trailing.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(4)
            make.bottom.equalTo(wordNumberLabel.snp_topMargin).offset(-10)
        }

        textView.addSubview(placeHolder)
        placeHolder.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(textView.textContainerInset.top)
            make.leading.equalTo(titleLabel.snp.leading)
        }

        contentView.addSubview(errorDesc)
        errorDesc.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(textBgView.snp.bottom).offset(8)
            make.bottom.equalToSuperview()
        }
    }

    func setCellViewModel(_ cellVM: NameCardEditItemViewModel) {
        self.cellVM = cellVM
        titleLabel.text = cellVM.title
        textView.text = cellVM.content
        errorDesc.text = cellVM.errorDesc
        wordNumberLabel.text = "\(textView.text.count)/\(cellVM.maxCharLength)"
        placeHolder.isHidden = !textView.text.isEmpty
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        delegate?.becomeFirstResponser(textView, cellVM)
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        guard let vm = cellVM else { return }
        if textView.text.count > vm.maxCharLength {
            textView.text = String(textView.text.prefix(vm.maxCharLength))
        }
        wordNumberLabel.text = "\(textView.text.count)/\((vm.maxCharLength))"
        cellVM?.updateContent(textView.text)
        delegate?.textDidChange(cellVM)
        placeHolder.isHidden = !textView.text.isEmpty
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
