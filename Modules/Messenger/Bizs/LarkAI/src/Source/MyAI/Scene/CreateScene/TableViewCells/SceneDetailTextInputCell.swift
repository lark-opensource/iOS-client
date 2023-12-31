//
//  SceneDetailTextInputCell.swift
//  LarkAI
//
//  Created by Zigeng on 2023/10/10.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignInput
import UniverseDesignColor
import LarkFeatureGating
import EditTextView

final class SceneDetailInputCell: UITableViewCell, SceneDetailCell {
    static let identifier: String = "SceneDetailInputCell"
    typealias VM = SceneDetailInputCellViewModel

    var status: VM.Status = .plain {
        didSet {
            statusUpdate?(status)
            switch status {
            case .plain:
                self.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)
            case .error:
                self.ud.setLayerBorderColor(UIColor.ud.functionDangerContentDefault)
            case .focus:
                self.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)
//                self.ud.setLayerBorderColor(UIColor.ud.primaryContentDefault)
            }
        }
    }
    var statusUpdate: ((VM.Status) -> Void)?

    var limit: Int = 0
    private lazy var textView: UDMultilineTextField = {
        var config = UDMultilineTextFieldUIConfig(isShowBorder: false,
                                                  textColor: UIColor.ud.textTitle,
                                                  font: .systemFont(ofSize: 16))
        let textView = UDMultilineTextField(config: config)
        textView.input.delegate = self
        return textView
    }()

    /// 内容剩余可输入长度
    private lazy var inputCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    /// 内容限制长度
    private lazy var limitLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none // 去掉点击高亮效果
        self.layer.borderWidth = 1
        self.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)

        let container = UIView()
        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(132)
        }
        container.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.width.equalToSuperview()
            make.height.equalTo(96)
        }
        container.addSubview(inputCountLabel)
        container.addSubview(limitLabel)

        /// 剩余可输入长度
        inputCountLabel.snp.makeConstraints { make in
            make.height.equalTo(14)
            make.top.equalTo(textView.snp.bottom)
            make.bottom.equalToSuperview().offset(-8)
        }
        limitLabel.snp.makeConstraints { make in
            make.centerY.height.equalTo(inputCountLabel)
            make.left.equalTo(inputCountLabel.snp.right)
            make.right.equalToSuperview().offset(-12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCell(vm: VM) {
        textView.placeholder = vm.placeHolder
        textView.text = vm.inputText
        updateText = { text in
            vm.inputText = text
        }
        limit = vm.limit
        limitLabel.text = "/\(limit)"
        updateTextCount()
        if vm.needShowError && (vm.trimmedinputText.isEmpty || vm.inputText.count > limit) {
            self.status = .error
        } else {
            self.status = .plain
        }
    }

    var updateText: ((String) -> Void)?
}

extension SceneDetailInputCell: UITextViewDelegate {
    func updateState() {
        if let text = textView.text, getLength(forText: text) > limit {
                self.status = .error
                return
        }
        self.status = .focus
    }

    func textViewDidChange(_ textView: UITextView) {
        updateText?(textView.text)
        updateTextCount()
        updateState()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if let text = textView.text, getLength(forText: text) > limit {
                self.status = .error
                return
        }
        self.status = .focus
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        updateText?(textView.text)
        if let text = textView.text, getLength(forText: text) > limit || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.status = .error
                return
        }
        self.status = .plain
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        /// 端上限制字符数时，如果进行撤销操作可能导致 range 越界，此时继续返回 true 会造成 crash
        if NSMaxRange(range) > textView.text.utf16.count {
            return false
        }
        return true
    }

    // 按照特定字符计数规则，获取字符串长度
    private func getLength(forText text: String) -> Int {
        // 单字节的 UTF-8（英文、半角符号）算 1 个字符，其余的（中文、Emoji等）暂时也算 1 个字符
        return text.count
    }

    private func updateTextCount() {
        var textCount: Int = 0
        if let text = textView.text {
            textCount = getLength(forText: text)
        }
        inputCountLabel.text = "\(textCount)"
        inputCountLabel.textColor = textCount > limit ? .ud.functionDangerContentDefault : .ud.textPlaceholder
    }
}
