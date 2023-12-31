//
//  SensitivityLocalTokenViewController.swift
//  SecurityComplianceDebug
//
//  Created by yifan on 2023/4/6.
//

import UIKit
import UniverseDesignToast
import UniverseDesignMenu
import UniverseDesignButton
import UniverseDesignFont
import SnapKit
import EENavigator
import LarkSensitivityControl
import LarkSecurityComplianceInfra
import LarkEMM

final class SensitivityLocalTokenViewController: UIViewController, UITextFieldDelegate {

    private let cellId = "SensitivityLocalTokenTableViewCell"

    private var localTokenConfig: [DebugTokenConfig] = []
    private var originTokenConfig: [DebugTokenConfig] = []

    private let textField: UITextField = {
        let field = UITextField(frame: .zero)
        field.borderStyle = UITextField.BorderStyle.roundedRect
        field.keyboardType = UIKeyboardType.asciiCapable
        field.placeholder = "Token过滤，回车结束！"
        return field
    }()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableHeaderView = nil
        tableView.tableFooterView = nil
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Local Token List"
        view.backgroundColor = UIColor.ud.bgBody
        
        view.addSubview(textField)
        view.addSubview(tableView)

        textField.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)

        setConstriants()
        initTokenConfig()
    }

    private func setConstriants() {
        textField.snp.makeConstraints {
            $0.top.equalToSuperview().offset(85)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(40)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(textField.snp.bottom)
            $0.left.right.bottom.equalToSuperview()
        }
    }
}

// MARK: viewModel
extension SensitivityLocalTokenViewController {
    // 回车后重置typeButton的内容
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // 收起键盘
        textField.resignFirstResponder()
        tokenFilter()
        tableView.reloadData()
        return true
    }

    private func tokenFilter() {
        var newTokenConfigs: [DebugTokenConfig] = []
        for config in originTokenConfig
        where config.identifier.localizedCaseInsensitiveContains(textField.text ?? "") {
            newTokenConfigs.append(config)
        }
        localTokenConfig = newTokenConfigs
    }

    // 点击空白处收起键盘
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        textField.resignFirstResponder()
    }

    private func initTokenConfig() {
        localTokenConfig = DebugEntry.getloadBuiltData()
        originTokenConfig = localTokenConfig
        Logger.info("debug localTokenConfig is \(localTokenConfig)")
    }
}

// MARK: dataSource & delegate for tableView
extension SensitivityLocalTokenViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return localTokenConfig.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        let tokenConfig = localTokenConfig[indexPath.row]
        cell.textLabel?.text = tokenConfig.identifier
        cell.textLabel?.numberOfLines = 5
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else {
            Logger.error("Array out of bounds")
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)    // 取消选中
    }

    #if !os(visionOS)
    // 显示菜单
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // 开启文本菜单功能，指定可以使用复制功能
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_ :)) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }

    // 将当前行内容赋给剪切板
    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if action == #selector(copy(_ :)) {
            let cell = tableView.cellForRow(at: indexPath)
            let config = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier))
            SCPasteboard.general(config).string = cell?.textLabel?.text
        }
    }
    #endif
}

