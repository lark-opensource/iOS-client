//
//  FeedbackInputCell.swift
//  ByteView
//
//  Created by fakegourmet on 2022/8/30.
//

import Foundation
import UniverseDesignInput

extension SettingCellType {
    static let feedbackInputCell = SettingCellType("feedbackInputCell", cellType: FeedbackInputCell.self)
}

protocol FeedbackInputCellDelegate: AnyObject {
    func feedbackInputCellDidChangeText(_ cell: FeedbackInputCell, text: String)
}

final class FeedbackInputCell: BaseSettingCell, UDMultilineTextFieldDelegate {
    weak var delegate: FeedbackInputCellDelegate?

    private(set) lazy var textField: UDMultilineTextField = {
        var config = UDMultilineTextFieldUIConfig()
        config.isShowBorder = false
        config.isShowWordCount = true
        config.maximumTextLength = 200
        config.textMargins = .init(top: 12, left: 10, bottom: 0, right: 10)
        let textField = UDMultilineTextField(config: config)
        textField.delegate = self
        return textField
    }()

    override func setupViews() {
        super.setupViews()
        self.selectionStyle = .none
        contentView.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.greaterThanOrEqualTo(136)
        }
    }

    override func config(for row: SettingDisplayRow, indexPath: IndexPath) {
        textField.text = row.title
        textField.placeholder = row.subtitle
        super.config(for: row, indexPath: indexPath)
    }

    func calculateText(_ text: String) -> NSAttributedString? {
        nil
    }

    func textViewDidChange(_ textView: UITextView) {
        self.delegate?.feedbackInputCellDidChangeText(self, text: self.textField.text)
    }
}
