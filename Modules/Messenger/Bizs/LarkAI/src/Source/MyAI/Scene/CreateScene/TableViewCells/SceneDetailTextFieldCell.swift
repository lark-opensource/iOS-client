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

final class SceneDetailTextFieldCell: UITableViewCell, SceneDetailCell {
    static let identifier: String = "SceneDetailTextFieldCell"
    typealias VM = SceneDetailTextFieldCellViewModel

    var status: VM.Status = .plain {
        didSet {
            if isInGrouped && status != .error {
                self.layer.borderWidth = 0
            } else {
                self.layer.borderWidth = 1
            }
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

    private lazy var textField: UITextField = {
        let view = UITextField()
        view.textColor = UIColor.ud.textTitle
        view.font = UIFont.systemFont(ofSize: 16)
        view.delegate = self
        view.contentVerticalAlignment = .center
        view.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return view
    }()

    @objc
    func textFieldDidChange() {
        updateText?(textField.text ?? "")
        if getLength(forText: textField.text) > limit {
            self.status = .error
            return
        }
        self.status = .focus
    }

    var textChangeAction: (() -> Void)?
    private lazy var deleteButton: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.deleteColorful, size: CGSize(width: 20, height: 20))
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(removeCell)))
        view.isUserInteractionEnabled = true
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none // 去掉点击高亮效果
        self.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)

        let container = UIView()
        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        container.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(12)
            make.width.height.equalTo(20)
        }
        container.addSubview(textField)
        textField.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(13)
            make.bottom.equalToSuperview().offset(-13)
            make.left.equalTo(deleteButton.snp.right).offset(12)
            make.right.equalToSuperview().offset(-12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCell(vm: VM) {
        let attributes = [NSAttributedString.Key.foregroundColor: UDColor.textPlaceholder]
        textField.attributedPlaceholder = NSAttributedString(string: vm.placeHolder,
                                                              attributes: attributes)
        textField.text = vm.inputText
        updateText = { text in
            vm.inputText = text
        }
        if !vm.canRemove {
            textField.snp.remakeConstraints { make in
                make.height.greaterThanOrEqualTo(22)
                make.top.equalToSuperview().offset(13)
                make.bottom.equalToSuperview().offset(-13)
                make.left.equalToSuperview().offset(12)
                make.right.equalToSuperview().offset(-12)
            }
            self.layer.borderWidth = 1
        } else {
            textField.snp.remakeConstraints { make in
                make.height.greaterThanOrEqualTo(22)
                make.top.equalToSuperview().offset(13)
                make.bottom.equalToSuperview().offset(-13)
                make.left.equalTo(deleteButton.snp.right).offset(12)
                make.right.equalToSuperview().offset(-12)
            }
        }
        limit = vm.limit
        removeCellAction = vm.removeSelf
        isInGrouped = vm.canRemove
        deleteButton.isHidden = !vm.canRemove
        if vm.needShowError && (vm.trimmedinputText.isEmpty || vm.inputText.count > limit) {
            self.status = .error
        } else {
            self.status = .plain
        }
    }

    var isInGrouped: Bool = false
    var removeCellAction: (() -> Void)?
    @objc
    func removeCell() {
        removeCellAction?()
    }

    var updateText: ((String) -> Void)?
}

extension SceneDetailTextFieldCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateText?(textField.text ?? "")
        if let text = textField.text, getLength(forText: text) > limit || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.status = .error
            return
        }
        self.status = .plain
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if getLength(forText: textField.text) > limit {
            self.status = .error
            return
        }
        self.status = .focus
    }
    // 按照特定字符计数规则，获取字符串长度
    private func getLength(forText text: String?) -> Int {
        guard let text = text else { return 0 }
        return text.count
    }
}
