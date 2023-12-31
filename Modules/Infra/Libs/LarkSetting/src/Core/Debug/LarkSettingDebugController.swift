//
//  LarkSettingDebugController.swift
//  LarkSetting
//
//  Created by chensi(陈思) on 2021/12/10.
//

#if ALPHA

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa
import LarkFoundation

// swiftlint:disable no_space_in_method_call function_body_length

/// Setting调试界面
final class LarkSettingDebugController: UIViewController {
    private let userID: String

    private lazy var tableView: UITableView = {
        let v = UITableView(frame: .zero, style: .plain)
        v.keyboardDismissMode = .onDrag
        v.tableHeaderView = nil
        v.tableFooterView = nil
        v.rowHeight = 42
        v.delegate = self
        v.dataSource = self
        v.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        return v
    }()

    private lazy var searchBar: UISearchBar = {
        let v = UISearchBar()
        v.placeholder = "请输入搜索key"
        v.returnKeyType = .search
        v.delegate = self

        if #available(iOS 13.0, *) { v.searchTextField.customize() }
        return v
    }()

    private var allKeys: [String] { SettingStorage.allSettingKeys(with: userID) } // 所有的key列表

    private var displayKeys = [String]() // 当前在显示的key列表

    private var filter = "" // 过滤条件

    private var cellId = "cell"

    init(userID: String) {
        self.userID = userID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        reloadTableView(filter: filter)
    }

    private func setupUI() {
        title = "Settings调试"
        view.backgroundColor = .white
        let lbbi = UIBarButtonItem(title: "exit", style: .plain, target: self, action: #selector(onBackTap))
        navigationItem.leftBarButtonItem = lbbi
        let rbbi = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onAddTap))
        navigationItem.rightBarButtonItem = rbbi
        navigationItem.backBarButtonItem = .init()

        view.addSubview(searchBar)
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(44)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }

    private func reloadTableView(filter: String) {
        let filter = filter.lowercased()
        if filter.isEmpty {
            displayKeys = allKeys
        } else {
            displayKeys = allKeys.compactMap { $0.lowercased().fuzzyMatch(filter) ? $0 : nil }
        }
        tableView.reloadData()
    }

    @objc
    private func onBackTap() {
        dismiss(animated: false)
    }

    @objc
    private func onAddTap() {
        let refreshAction: (() -> Void) = { [weak self] in
            self?.reloadTableView(filter: self?.filter ?? "")
        }
        let actionSheet = UIAlertController(title: "新增Setting", message: nil, preferredStyle: .alert)
        actionSheet.addTextField { $0.placeholder = "请输入Key名称" }
        actionSheet.addAction(.init(title: "Bool", style: .default, handler: { [weak self, weak actionSheet] _ in
            let key = actionSheet?.textFields?.first?.text ?? ""
            self?.showValueDetail(key: key, value: .boolean(false), onDismiss: refreshAction)
        }))
        actionSheet.addAction(.init(title: "Number", style: .default, handler: { [weak self, weak actionSheet] _ in
            let key = actionSheet?.textFields?.first?.text ?? ""
            self?.showValueDetail(key: key, value: .number(.init(value: 0)), onDismiss: refreshAction)
        }))
        actionSheet.addAction(.init(title: "JSON", style: .default, handler: { [weak self, weak actionSheet] _ in
            let key = actionSheet?.textFields?.first?.text ?? ""
            self?.showValueDetail(key: key, value: .text("{\n\n}"), onDismiss: refreshAction)
        }))
        actionSheet.addAction(.init(title: "cancel", style: .destructive))
        present(actionSheet, animated: true)
    }

    private func showValueDetail(key: String, value: SettingsConfigValue, onDismiss: (() -> Void)? = nil) {
        guard !key.isEmpty else {
            UIAlertController.notice(text: "key为空", from: self)
            return
        }
        let userID = self.userID

        switch value {
        case .boolean(let bool):
            let actionSheet = UIAlertController(title: "", message: key, preferredStyle: .actionSheet)
            actionSheet.addAction(.init(title: bool ? "☉  true" : "   true", style: .default, handler: { _ in
                SettingStorage.updateSettingValue("\(true)", with: userID, and: key)
                onDismiss?()
            }))
            actionSheet.addAction(.init(title: bool ? "  false" : "☉ false", style: .default, handler: { _ in
                SettingStorage.updateSettingValue("\(false)", with: userID, and: key)
                onDismiss?()
            }))
            actionSheet.addAction(.init(title: "cancel", style: .destructive))
            present(actionSheet, animated: true)
        case .number(let number):
            let actionSheet = UIAlertController(title: key, message: nil, preferredStyle: .alert)
            actionSheet.addTextField {
                $0.keyboardType = .decimalPad
                $0.text = "\(number)"
            }
            actionSheet.addAction(.init(title: "confirm", style: .default, handler: { [weak self, weak actionSheet] _ in
                guard let self = self else { return }
                let input = actionSheet?.textFields?.first?.text ?? ""
                if let doubleValue = Double(input) {
                    SettingStorage.updateSettingValue("\(doubleValue)", with: userID, and: key)
                    onDismiss?()
                } else if let intValue = Int(input) {
                    SettingStorage.updateSettingValue("\(intValue)", with: userID, and: key)
                    onDismiss?()
                } else { UIAlertController.notice(text: "请输入合法数字", from: self) }
            }))
            actionSheet.addAction(.init(title: "cancel", style: .cancel))
            present(actionSheet, animated: true)
        case .text(let string):
            let vc = SettingsValueDetailVC()
            vc.setText(string)
            vc.title = key
            vc.confirmCompletion = { [weak vc] in
                SettingStorage.updateSettingValue($0, with: userID, and: key)
                vc?.navigationController?.popViewController(animated: true)
                onDismiss?()
            }
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension LarkSettingDebugController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filter = searchText
        reloadTableView(filter: filter)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        filter = searchBar.text ?? ""
        reloadTableView(filter: filter)
    }
}

extension LarkSettingDebugController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)
    -> UITableViewCell.EditingStyle { .delete }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        let key = displayKeys[indexPath.row]
        SettingStorage.deleteSettingKey(with: userID, and: key)
        reloadTableView(filter: filter)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        do {
            let key = displayKeys[indexPath.row]
            let result = try SettingStorage.getSettingValue(with: userID, and: key)
            if let value = SettingsConfigValue(value: result) { showValueDetail(key: key, value: value) }
        } catch {}
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { displayKeys.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        let keyName = displayKeys[indexPath.row]
        cell.textLabel?.text = keyName
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

private enum SettingsConfigValue {
    case boolean(Bool)
    case number(NSNumber)
    case text(String)

    init?(value: Any?) {
        guard let value = value else { return nil }
        switch value {
        case let value as Bool:
            self = .boolean(value)
        case let value as Int:
            self = .number(.init(value: value))
        case let value as Double:
            self = .number(.init(value: value))
        case let value as String:
            self = .text(value)
        case is [String], is [String: Any]:
            let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys, .fragmentsAllowed]
            let data = try? JSONSerialization.data(withJSONObject: value, options: options)
            let string = String(data: data ?? .init(), encoding: .utf8)
            self = .text(string ?? "")
        default:
            return nil
        }
    }
}

private final class SettingsValueDetailVC: UIViewController {
    var confirmCompletion: ((String) -> Void)?

    private let disposeBag = DisposeBag()

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.keyboardDismissMode = .onDrag
        tv.font = .systemFont(ofSize: 15)
        tv.layer.cornerRadius = 6
        tv.layer.borderColor = UIColor.lightGray.cgColor
        tv.layer.borderWidth = 1
        tv.customize()
        return tv
    }()

    private lazy var searchBar: UISearchBar = {
        let v = UISearchBar()
        v.placeholder = "搜索字符..."
        v.returnKeyType = .search
        v.delegate = self
        if #available(iOS 13.0, *) { v.searchTextField.customize() }
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = .init(title: "confirm", style: .plain,
                                                  target: self, action: #selector(onConfirm))

        view.addSubview(searchBar)
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(44)
        }

        view.addSubview(textView)
        textView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(16)
            $0.left.right.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        textView.becomeFirstResponder()

        let notiCenter = NotificationCenter.default
        let obs1 = notiCenter.rx.notification(UIResponder.keyboardWillShowNotification).map { ($0, true) }
        let obs2 = notiCenter.rx.notification(UIResponder.keyboardWillHideNotification).map { ($0, false) }
        Observable.merge(obs1, obs2).subscribe(onNext: { [weak self] in self?.handleKeyboard($0, isShow: $1) })
            .disposed(by: disposeBag)
    }

    func setText(_ text: String?) {
        textView.text = text
    }

    @objc
    private func onConfirm() {
        let input = textView.text ?? ""
        if input.hasPrefix("[") || input.hasPrefix("{") { // [String] 或 [String: Any]，校验一下
            let obj = try? JSONSerialization.jsonObject(with: input.data(using: .utf8) ?? .init(),
                                                        options: .fragmentsAllowed)
            if let obj = obj, JSONSerialization.isValidJSONObject(obj) {
                confirmCompletion?(input)
            } else {
                UIAlertController.notice(text: "JSON格式有误", from: self)
            }
        } else { // String，不校验
            confirmCompletion?(input)
        }
    }

    private func handleKeyboard(_ noti: Notification, isShow: Bool) {
        let height = (noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0
        let bottomInset = isShow ? height : 16
        textView.snp.updateConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(bottomInset)
        }
    }

    private func reloadText(_ highLightRanges: [NSRange]) {
        textView.textStorage.removeAttribute(.backgroundColor,
                                             range: .init(location: 0, length: textView.textStorage.length))
        highLightRanges.forEach {
            textView.textStorage.addAttributes([.backgroundColor: UIColor.yellow], range: $0)
        }
    }
}

extension SettingsValueDetailVC: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let filterRanges = (textView.text ?? "").ranges(of: searchText)
        reloadText(filterRanges)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        let filterRanges = (textView.text ?? "").ranges(of: searchBar.text ?? "")
        reloadText(filterRanges)
    }
}

private extension UIAlertController {
    static func notice(text: String?, from vc: UIViewController) {
        let alert = UIAlertController(title: "", message: text, preferredStyle: .alert)
        vc.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { alert.dismiss(animated: true) }
    }
}

private extension String {
    func ranges(of occurrence: String) -> [NSRange] {
        var result = [NSRange]()
        var position = startIndex
        while let tempRange = range(of: occurrence, range: position..<endIndex) {
            let i = distance(from: startIndex, to: tempRange.lowerBound)
            result.append(.init(location: i, length: occurrence.count))
            let offset = occurrence.distance(from: occurrence.startIndex, to: occurrence.endIndex) - 1
            guard let after = index(tempRange.lowerBound, offsetBy: offset, limitedBy: endIndex) else {
                break
            }
            position = index(after: after)
        }
        return result
    }
}

#endif
