//
//  CreateVoteOptionCell.swift
//  LarkVote
//
//  Created by Fan Hui on 2022/4/5.
//

import Foundation
import UIKit
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignColor
import RxSwift

final class CreateVoteOptionCell: CreateVoteBaseCell, UITextFieldDelegate {

    let disposeBag: DisposeBag = DisposeBag()
    let contentField: UITextField = UITextField()
    let optionBtn: UIButton = UIButton()
    var index: Int = 0
    var clickBlock: ((Int) -> Void)?
    var textChangeBlock: ((String?, Int) -> Void)?
    let separatorView: UIView = UIView()

    func setupCellContent() {
        self.contentView.addSubview(contentField)
        self.contentView.addSubview(optionBtn)
        self.contentView.addSubview(separatorView)
        contentField.attributedPlaceholder = NSAttributedString(
            string: BundleI18n.LarkVote.Lark_IM_Poll_CreatePoll_Options_Placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder])
        contentField.delegate = self
        self.contentField.snp.makeConstraints {
            $0.left.equalTo(50)
            $0.right.equalToSuperview().inset(16)
            $0.top.equalToSuperview()
            $0.height.equalTo(48)
        }
        self.separatorView.snp.makeConstraints {
            $0.left.equalTo(self.contentField.snp_leftMargin)
            $0.right.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
        self.separatorView.backgroundColor = UIColor.ud.color(31, 35, 41, 0.15)
        self.optionBtn.snp.makeConstraints {
            $0.left.equalTo(16)
            $0.top.equalToSuperview()
            $0.height.equalTo(48)
        }
        self.optionBtn.setImage(UDIcon.getIconByKey(.noFilled, iconColor: UIColor.ud.colorfulRed, size: CGSize(width: 22, height: 22)), for: .normal)
        self.optionBtn.setImage(UDIcon.getIconByKey(.noFilled, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: 22, height: 22)), for: .disabled)
    }

    public func updateCellBlock(clickBlock: ((Int) -> Void)?, textChangeBlock: ((String?, Int) -> Void)?) {
        self.clickBlock = clickBlock
        self.textChangeBlock = textChangeBlock
        self.optionBtn.rx.tap.subscribe(onNext: { [weak self] (idx) in
            if let clickBlock = clickBlock, let idx = self?.index {
                clickBlock(idx)
            }
        }).disposed(by: self.disposeBag)
        self.contentField.rx.controlEvent([.editingChanged])
            .asObservable().subscribe(onNext: { [weak self] _ in
            if let textChangeBlock = textChangeBlock, let idx = self?.index {
                textChangeBlock(self?.contentField.text, idx)
            }
        }).disposed(by: self.disposeBag)
    }

    public func updateCellContent(index: Int) {
        self.index = index
    }

    public func changeOptionBtnStatus(isEnabled: Bool) {
        self.optionBtn.isEnabled = isEnabled
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupCellContent()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        contentField.endEditing(true)
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        let textLength = text.utf16.count + string.utf16.count - range.length
        if textLength > optionMaximumCharacterLimit {
            guard let window = self.window else { return false }
            UDToast.showTips(with: BundleI18n.LarkVote.Lark_IM_Poll_MaximumCharacterLimit120_ErrorText(optionMaximumCharacterLimit), on: window)
            return false
        }
        return true
    }
}
