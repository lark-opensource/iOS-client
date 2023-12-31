//
//  CreateVoteTitleCell.swift
//  LarkVote
//
//  Created by Fan Hui on 2022/4/5.
//

import Foundation
import RxSwift
import UIKit
import UniverseDesignToast

final class CreateVoteTopicCell: CreateVoteBaseCell, UITextFieldDelegate {

    let disposeBag: DisposeBag = DisposeBag()
    var textChangeBlock: ((String?) -> Void)?
    let contentField: UITextField = UITextField()

    func setupCellContent() {
        self.contentView.addSubview(contentField)
        contentField.attributedPlaceholder = NSAttributedString(
            string: BundleI18n.LarkVote.Lark_IM_Poll_CreatePoll_PollTitle_Placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder])
        contentField.delegate = self
        self.contentField.snp.makeConstraints {
            $0.left.equalTo(16)
            $0.right.equalToSuperview().inset(16)
            $0.top.equalToSuperview()
            $0.height.equalTo(54)
        }
    }

    public func updateCellBlock(textChangeBlock: ((String?) -> Void)?) {
        self.textChangeBlock = textChangeBlock
        self.contentField.rx.text.subscribe(onNext: { (text) in
            if let textChangeBlock = textChangeBlock {
                textChangeBlock(text)
            }
        }).disposed(by: self.disposeBag)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupCellContent()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        let textLength = text.utf16.count + string.utf16.count - range.length
        if textLength > topicMaximumCharacterLimit {
            guard let window = self.window else { return false }
            UDToast.showTips(with: BundleI18n.LarkVote.Lark_IM_Poll_MaximumCharacterLimit60_ErrorText(topicMaximumCharacterLimit), on: window)
            return false
        }
        return true
    }
}
