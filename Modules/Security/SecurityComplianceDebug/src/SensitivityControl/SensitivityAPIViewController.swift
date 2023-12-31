//
//  SensitivityAPIViewController.swift
//  SecurityComplianceDebug
//
//  Created by yifan on 2022/11/28.
//

import UIKit
import UniverseDesignButton
import SnapKit
import LarkSecurityComplianceInfra
import CoreLocation

final class SensitivityAPIViewController: UIViewController {

    private let cellId = "SensitivityAPITableViewCell"

    private let items = SensitivityAPIData().build()

    private var delayTime: Int {
        return Int(textField.text ?? "0") ?? 0
    }

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableHeaderView = nil
        tableView.tableFooterView = nil
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()

    private let delayTip: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "请设置API延时执行的秒数："
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()

    private let invokeTip: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "请点击下方单元格，以执行对应的方法调用！"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = .systemBlue
        return label
    }()

    private let textField: UITextField = {
        let field = UITextField(frame: .zero)
        field.borderStyle = UITextField.BorderStyle.roundedRect
        field.keyboardType = UIKeyboardType.asciiCapable
        return field
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "API List"
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(textField)
        view.addSubview(delayTip)
        view.addSubview(invokeTip)
        view.addSubview(tableView)

        tableView.delegate = self
        tableView.dataSource = self
        textField.delegate = self

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        textField.placeholder = String(delayTime)

        setConstraints()

    }

    private func setConstraints() {
        delayTip.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.width.equalTo(200)
            $0.top.equalToSuperview().offset(85)
            $0.height.equalTo(40)
        }

        textField.snp.makeConstraints {
            $0.left.equalTo(delayTip.snp.right)
            $0.right.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(85)
            $0.height.equalTo(40)
        }

        invokeTip.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.top.equalTo(delayTip.snp.bottom)
            $0.height.equalTo(40)
        }

        tableView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(invokeTip.snp.bottom)
        }
    }
}

// MARK: delegate for textField
extension SensitivityAPIViewController: UITextFieldDelegate {
    // 点击回车收起键盘
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // 点击空白处收起键盘
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        textField.resignFirstResponder()
    }

    // 限制只能输入数字
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let length = string.lengthOfBytes(using: String.Encoding.utf8)
        for index in 0..<length {
            let char = (string as NSString).character(at: index)
            if char < 48 || char > 57 {
                return false
            }
        }
        return true
    }
}

// MARK: dataSource & delegate for tableView
extension SensitivityAPIViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return items[section].type
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].apiDatas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cell.textLabel?.text = items[indexPath.section].apiDatas[indexPath.row].title
        cell.textLabel?.numberOfLines = 3
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else {
            Logger.error("Array out of bounds")
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        items[indexPath.section].apiDatas[indexPath.row].action(delayTime, self.view)
    }
}
