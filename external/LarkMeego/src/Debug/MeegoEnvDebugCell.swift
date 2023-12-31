//
//  MeegoEnvDebugCell.swift
//  LarkMeego
//
//  Created by shizhengyu on 2022/3/9.
//

import Foundation
import UIKit
import SnapKit
import EENavigator

// MeegoEnvDebugInteractType.display
class MeegoEnvDebugDisplayCell: MeegoEnvDebugBaseCell {
    private let displayLabel = UILabel()

    override func update(_ content: String) {
        displayLabel.text = content
    }

    override func layoutPageSubviews() {
        super.layoutPageSubviews()

        displayLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        displayLabel.textColor = UIColor.darkGray
        displayLabel.textAlignment = .right
        contentView.addSubview(displayLabel)
        displayLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(12)
            make.left.equalTo(contentView.snp.centerX).offset(22)
            make.top.bottom.equalToSuperview()
        }
    }
}

// MeegoEnvDebugInteractType.textEdit
class MeegoEnvDebugTextEditCell: MeegoEnvDebugBaseCell {
    var listen: ((String) -> Void)?
    private let editLabel = UILabel()

    override func update(_ content: String) {
        editLabel.text = content
    }

    override func layoutPageSubviews() {
        super.layoutPageSubviews()

        editLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        editLabel.textColor = UIColor.darkGray
        editLabel.textAlignment = .right
        editLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(tapAction))
        editLabel.addGestureRecognizer(tap)
        contentView.addSubview(editLabel)
        editLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(12)
            make.left.equalTo(contentView.snp.centerX).offset(22)
            make.top.bottom.equalToSuperview()
        }
    }

    @objc func tapAction() {
        let alert = UIAlertController(title: "更新值", message: "请输入最新的值", preferredStyle: .alert)
        alert.addTextField { [weak self] textField in
            guard let `self` = self else { return }
            textField.text = self.content
        }
        let action = UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            let new = alert.textFields?.first?.text ?? ""
            self?.content = new
            self?.listen?(new)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        alert.addAction(action)
        alert.addAction(cancelAction)
        Navigator.shared.mainSceneTopMost?.present(alert, animated: true, completion: nil)
    }
}

// MeegoEnvDebugInteractType.switch
class MeegoEnvDebugSwitchCell: MeegoEnvDebugBaseCell {
    var listen: ((Bool) -> Void)?
    private let switchButton = UISwitch()

    override func update(_ content: String) {
        if content == "1" || content.lowercased() == "yes" || content.lowercased() == "true" {
            switchButton.setOn(true, animated: false)
        } else if content == "0" || content.lowercased() == "no" || content.lowercased() == "false" {
            switchButton.setOn(false, animated: false)
        }
    }

    override func layoutPageSubviews() {
        super.layoutPageSubviews()

        switchButton.addTarget(self, action: #selector(switchAction), for: .valueChanged)
        contentView.addSubview(switchButton)
        switchButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        envNameLabel.snp.remakeConstraints { make in
            make.right.equalTo(switchButton.snp.left).offset(-12)
            make.left.equalToSuperview().offset(12)
            make.top.bottom.equalToSuperview()
        }
    }

    @objc func switchAction() {
        listen?(switchButton.isOn)
    }
}

// MeegoEnvDebugInteractType.operation
class MeegoEnvDebugOperationCell: MeegoEnvDebugBaseCell {
    var listen: (() -> Void)?
    private let operationButton = UIButton()

    override func update(_ content: String) {
        operationButton.setTitle(content, for: .normal)
    }

    override func layoutPageSubviews() {
        super.layoutPageSubviews()

        operationButton.addTarget(self, action: #selector(operationAction), for: .touchUpInside)
        operationButton.backgroundColor = UIColor.blue
        operationButton.setTitleColor(UIColor.white, for: .normal)
        operationButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        operationButton.layer.cornerRadius = 8.0
        operationButton.layer.masksToBounds = true
        operationButton.setTitle("执行", for: .normal)
        contentView.addSubview(operationButton)
        operationButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(12)
            make.width.equalTo(60)
            make.height.equalTo(32)
            make.centerY.equalToSuperview()
        }
        envNameLabel.snp.remakeConstraints { make in
            make.right.equalTo(operationButton.snp.left).offset(-12)
            make.left.equalToSuperview().offset(12)
            make.top.bottom.equalToSuperview()
        }
    }

    @objc func operationAction() {
        listen?()
    }
}

class MeegoEnvDebugBaseCell: UITableViewCell {
    var envName: String = "" {
        didSet {
            envNameLabel.text = self.envName
        }
    }
    var content: String = "" {
        didSet {
            update(self.content)
        }
    }

    let envNameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ content: String) {}

    func layoutPageSubviews() {
        envNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        envNameLabel.textAlignment = .left
        envNameLabel.textColor = UIColor.black
        contentView.addSubview(envNameLabel)
        envNameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.right.equalTo(contentView.snp.centerX).offset(20)
            make.top.bottom.equalToSuperview()
        }
    }
}
