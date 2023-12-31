//
//  MailDebugViewController.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/10/31.
//

import Foundation
import LarkUIKit
import RxSwift

#if ALPHA || DEBUG

class DebugItem {
    enum DebugItemType: Int {
        case loadLocalTemplate
        case editorDebug
        case delayLoadTemplate
        case editorIP
        case dataDebug
    }
    enum ItemStyle {
        case detail(_ detail: String, type: DebugItemType)
        case switchButton(isOn: Bool, type: DebugItemType)
    }
    var title: String
    var style: ItemStyle
    var type: DebugItemType {
        switch style {
        case .detail(_, let type):
            return type
        case .switchButton(_, let type):
            return type
        }
    }

    init(title: String, style: ItemStyle) {
        self.title = title
        self.style = style
    }
}

class MailDebugViewController: MailBaseViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    var tableView: UITableView = .init(frame: .zero)
    private let defaultCellIdentifier = "defaultCellIdentifier"
    private let switchCellIdentifier = "switchCellIdentifier"
    static let kMailLoadLocalTemplate = "kMailLoadLocalTemplate"
    static let kMailEditorDebug = "kMailEditorDebug"
    static let kMailDelayLoadTemplate = "kMailDelayLoadTemplate"
    static let kMailEditorIP = "kMailEditorIP"
    static let kMailDataDebug = "kMailDataDebug"
    var editorIP = ""
    private let disposeBag = DisposeBag()

    var sectionItems: [(String, [DebugItem])] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        addCloseItem()
        self.title = "Lark邮件调试"
        setupViews()
    }

    private func setupViews() {
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        view.addSubview(tableView)

        loadData()
    }

    private func loadData() {
        let kvStore = MailKVStore(space: .global, mSpace: .global)
        let caller: (String, [DebugItem]) = (
            "调试开关",
            [
                DebugItem(
                    title: "邮件模板本地调试开关",
                    style: .switchButton(
                        isOn: kvStore.bool(forKey: MailDebugViewController.kMailLoadLocalTemplate),
                        type: .loadLocalTemplate
                    )
                ),
                DebugItem(title: "editor debug",
                          style: .switchButton(
                            isOn: kvStore.bool(forKey: MailDebugViewController.kMailEditorDebug),
                            type: .editorDebug)),
                DebugItem(title: "Delay load mail template",
                          style: .switchButton(
                            isOn: kvStore.bool(forKey: MailDebugViewController.kMailDelayLoadTemplate),
                            type: .delayLoadTemplate)),
                DebugItem(title: "Editor IP", style: .detail(kvStore.value(forKey: MailDebugViewController.kMailEditorIP) ?? "", type: .editorIP)),
                DebugItem(title: "Data Debug",
                          style: .switchButton(isOn: kvStore.bool(forKey: MailDebugViewController.kMailDataDebug), type: .dataDebug))
            ])

        sectionItems.append(caller)
    }
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionItems.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionItems[section].1.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sectionItems[indexPath.section].1[indexPath.row]
        var cell: UITableViewCell!
        switch item.style {
        case .detail(let detail, let type):
            cell = tableView.dequeueReusableCell(withIdentifier: defaultCellIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: defaultCellIdentifier)
            }
            if type == .editorIP {
                let kvStore = MailKVStore(space: .global, mSpace: .global)
                cell.detailTextLabel?.text = kvStore.value(forKey: MailDebugViewController.kMailEditorIP)
            } else {
                cell.detailTextLabel?.text = detail
            }
        case .switchButton(let isOn, let type):
            cell = tableView.dequeueReusableCell(withIdentifier: switchCellIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: switchCellIdentifier)
                let switchButton = UISwitch()
                switchButton.isOn = isOn
                switchButton.tag = type.rawValue
                switchButton.addTarget(self, action: #selector(didClickSwitchButton(sender:)), for: .valueChanged)
                cell.accessoryView = switchButton
                cell.selectionStyle = .none
            }
            if let itemSwitch = cell.accessoryView as? UISwitch {
                itemSwitch.isOn = isOn
            }
        }
        cell.textLabel?.text = item.title
        return cell
    }
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionItems[section].0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sectionItems[indexPath.section].1[indexPath.row]
        switch item.style {
        case .detail:
            showTextFieldAlterViewController(item: item)
        default:
            break
        }
    }
    // MARK: - UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        editorIP = textField.text ?? ""
    }

    func showTextFieldAlterViewController(item: DebugItem) {
        let kvStore = MailKVStore(space: .global, mSpace: .global)
        switch item.style {
        case .detail(_, let itemType):
            if itemType == .editorIP {
                let alert = UIAlertController(title: item.title,
                                              message: nil,
                                              preferredStyle: .alert)
                alert.addTextField { [weak self] textField in
                    textField.delegate = self
                    textField.placeholder = item.title
                    textField.text = kvStore.value(forKey: MailDebugViewController.kMailEditorIP) ?? ""
                }
                let ok = UIAlertAction(title: "确定", style: .default) { [weak self] (action) in
                    kvStore.set(self?.editorIP ?? "", forKey: MailDebugViewController.kMailEditorIP)
                }
                let cancle = UIAlertAction(title: "取消", style: .cancel)
                alert.addAction(cancle)
                alert.addAction(ok)
                present(alert, animated: true, completion: nil)
            }
        default:
            break
        }
    }

    @objc
    func didClickSwitchButton(sender: UISwitch) {
        let kvStore = MailKVStore(space: .global, mSpace: .global)
        switch sender.tag {
        case DebugItem.DebugItemType.loadLocalTemplate.rawValue:
            kvStore.set(sender.isOn, forKey: MailDebugViewController.kMailLoadLocalTemplate)
        case DebugItem.DebugItemType.editorDebug.rawValue:
            kvStore.set(sender.isOn, forKey: MailDebugViewController.kMailEditorDebug)
        case DebugItem.DebugItemType.delayLoadTemplate.rawValue:
            kvStore.set(sender.isOn, forKey: MailDebugViewController.kMailDelayLoadTemplate)
        case DebugItem.DebugItemType.dataDebug.rawValue:
            kvStore.set(sender.isOn, forKey: MailDebugViewController.kMailDataDebug)
        default:
            break
        }
    }
}

class MailDetailDataVC: MailBaseViewController {
    lazy var textView = {
        let view = UITextView()
        return view
    }()
    var detailData: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        addCloseItem()
        setupViews()
        self.title = "detail data"
        self.view.backgroundColor = .white
    }
    func setupViews() {
        self.view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(20)
            make.right.bottom.equalToSuperview().offset(-20)
        }
        textView.text = detailData
    }
}

#endif
