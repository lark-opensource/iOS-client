//
//  SensitivityTokenListViewController.swift
//  SecurityComplianceDebug
//
//  Created by yifan on 2022/12/1.
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
import LarkContainer
import LarkEMM

final class SensitivityTokenListViewController: UIViewController, UITextFieldDelegate {

    static weak var current: SensitivityTokenListViewController?

    private let cellId = "SensitivityTokenListTableViewCell"

    private var tokenConfigs: [DebugTokenConfig] = []

    private var originTokenConfigs: [DebugTokenConfig] = []

    private let tip: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "请输入Token，进行校验："
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()

    private let checkButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.primaryBlue)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle("校验", for: .normal)
        return button
    }()

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
    
    let userResolver: UserResolver

    init(resolver: UserResolver) {
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
        Self.current = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Token List"
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(tip)
        view.addSubview(textField)
        view.addSubview(tableView)
        view.addSubview(checkButton)
        checkButton.addTarget(self, action: #selector(checkToken), for: .touchUpInside)

        textField.delegate = self
        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(SCDebugViewCell.self, forCellReuseIdentifier: cellId)

        setConstriants()
        initTokenConfig()
        registerDebugInterceptor()
    }

    private func setConstriants() {
        tip.snp.makeConstraints {
            $0.top.equalToSuperview().offset(85)
            $0.left.equalToSuperview().offset(16)
            $0.width.equalTo(240)
            $0.height.equalTo(40)
        }

        checkButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(85)
            $0.left.equalTo(tip.snp.right).offset(20)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(40)
        }

        textField.snp.makeConstraints {
            $0.top.equalTo(tip.snp.bottom).offset(5)
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
extension SensitivityTokenListViewController {
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
        for config in originTokenConfigs
        where config.identifier.localizedCaseInsensitiveContains(textField.text ?? "") {
            newTokenConfigs.append(config)
        }
        tokenConfigs = newTokenConfigs
    }

    // 点击空白处收起键盘
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        textField.resignFirstResponder()
    }

    private func initTokenConfig() {
        originTokenConfigs = DebugEntry.getDebugConfigs()
        tokenConfigs = originTokenConfigs

        Logger.info("debug originTokenConfigs is \(originTokenConfigs)")
    }

    @objc
    private func checkToken() {
        let token = Token(textField.text ?? "")
        do {
            try DebugEntry.checkToken(forToken: token)
            let config = UDToastConfig(toastType: .info, text: "token exist", operation: nil)
            UDToast.showToast(with: config, on: view)
        } catch {
            if error.localizedDescription.contains("atomicInfoNotMatch") {
                let config = UDToastConfig(toastType: .info, text: "token exist", operation: nil)
                UDToast.showToast(with: config, on: view)
            } else {
                let config = UDToastConfig(toastType: .error, text: error.localizedDescription, operation: nil)
                UDToast.showToast(with: config, on: view)
            }
        }
    }
}

// MARK: dataSource & delegate for tableView
extension SensitivityTokenListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tokenConfigs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? SCDebugViewCell else {
            return UITableViewCell()
        }
        let tokenConfig = tokenConfigs[indexPath.row]
        let title = tokenConfig.identifier
        let switchIsOn = tokenConfig.status == .ENABLE
        cell.textLabel?.numberOfLines = 5
        cell.configModel(model: SCDebugModel(cellTitle: title, cellType: .switchButton, isSwitchButtonOn: switchIsOn, switchHandler: { isOn in
            let status: DebugTokenStatus = isOn ? .ENABLE : .DISABLE
            for i in 0..<self.originTokenConfigs.count
            where self.originTokenConfigs[i].identifier == self.tokenConfigs[indexPath.row].identifier {
                self.originTokenConfigs[i].status = status
                DebugEntry.setDebugConfigs(identifier: self.originTokenConfigs[i].identifier, status: status)
                break;
            }
            let text = title + "，证书" + status.rawValue
            let config = UDToastConfig(toastType: .info, text: text, operation: nil)
            UDToast.showToast(with: config, on: self.view)
        }))
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
            let cell = tableView.cellForRow(at: indexPath) as? SCDebugViewCell
            let config = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier))
            SCPasteboard.general(config).string = cell?.textLabel?.text
        }
    }
    #endif
}

// MARK: interceptor
extension SensitivityTokenListViewController {
    /// token禁用拦截器
    struct DebugInterceptor: Interceptor {

        struct DebugResultInfo: ResultInfo {
            let token: Token
            let code: Code
            let context: Context
        }

        func intercept(token: Token, context: Context) -> InterceptorResult {
            guard let shared = SensitivityTokenListViewController.current else { return .continue }
            for config in shared.originTokenConfigs where config.identifier == token.identifier && config.status == .DISABLE {
                return .break(DebugResultInfo(token: token, code: .statusDisabledForDebug, context: context))
            }
            return .continue
        }
    }

    private func registerDebugInterceptor() {
        SensitivityManager.shared.registerInterceptorInsertFront(DebugInterceptor())
    }
}
