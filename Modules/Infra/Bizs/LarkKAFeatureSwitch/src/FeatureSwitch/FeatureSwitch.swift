//
//  FeatureSwitch.swift
//  LarkAppConfig
//
//  Created by kongkaikai on 2020/1/9.
//

import UIKit
import Foundation
import LarkReleaseConfig
import LarkDebugExtensionPoint
import LarkDynamicResource
import LarkSetting
import LKCommonsLogging
import LarkFoundation

/// API for KA disable some function
public final class FeatureSwitch {
    /// shared
    public static let share = FeatureSwitch()
    static let logger = Logger.log(FeatureSwitch.self, category: "FeatureSwitch")

    private var boolConfig: [SwitchKey: Bool] = [:]
    private var config: [ConfigKey: [String]] = [:]

    private init() {
        guard ReleaseConfig.isKA else { return }

        do {
            let dictionary = try SettingManager.shared.setting(with: [String: FeatureSwitchValue].self, key: UserSettingKey.make(userKeyLiteral: "feature_switch_client"))
            ConfigKey.allCases.forEach { (key) in
                dictionary[key.rawValue]?.array.flatMap { config[key] = $0 }
            }
        } catch let error {
            Self.logger.error("从默认配置中反序列化FS value失败", error: error)
        }
        DebugRegistry.registerDebugItem(FSDebug(), to: .debugTool)
    }

    @available(*, deprecated, message: "该函数已废弃，建议直接使用LarkSetting读取。fs配置<开关bool值>相关的数据已迁移到fg平台，详细请看：https://bytedance.feishu.cn/docs/doccnhLxHJRY6jSeK5olsNZu9rg#VLIXFB")
    public func bool(for key: SwitchKey) -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key.rawValue))
    }

    @available(*, deprecated, message: "该函数已废弃，建议直接使用LarkSetting读取。fs配置<开关bool值>相关的数据已迁移到fg平台，详细请看：https://bytedance.feishu.cn/docs/doccnhLxHJRY6jSeK5olsNZu9rg#VLIXFB")
    public func boolLocal(for key: SwitchKey) -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key.rawValue))
    }

    /// 返回字符串数组表示当前Key对应的配置，可能为空数组
    /// Saas 环境总是返回空数组: []
    ///
    /// - Parameter key: key for feature
    public func config(for key: ConfigKey) -> [String] {
        if let featureConfig = DynamicResourceManager.shared.getFeatureConfig(key: key.rawValue) {
            return [featureConfig]
        }
        return config[key] ?? []
    }
}

struct FeatureSwitchValue: Decodable {
    var bool: Bool?
    var array: [String]?
    init(from decoder: Decoder) throws {
        if let bool = try? decoder.singleValueContainer().decode(Bool.self) {
            self.bool = bool
        } else if let string = try? decoder.singleValueContainer().decode(String.self) {
            self.array = [string]
        } else {
            array = try decoder.singleValueContainer().decode(Array<String>.self)
        }
    }
}

// MARK: - 以下是DEBUG代码
fileprivate extension FeatureSwitch {
    // For debug change value.
    struct FSDebug: DebugCellItem {
        var title: String { "FeatureSwitch For KA" }

        func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
            let navigation = UINavigationController(rootViewController: DebugController())
            navigation.modalPresentationStyle = .fullScreen
            debugVC.present(navigation, animated: true, completion: nil)
        }
    }

    /// debug cell
    final class DebugCell: UITableViewCell {
        var switchKey: SwitchKey? {
            didSet {
                guard let key = switchKey else { return }
                configKey = nil
                textLabel?.text = "key: \(key.rawValue);"
                detailTextLabel?.text = "value: \(FeatureSwitch.share.bool(for: key))"
                detailTextLabel?.numberOfLines = 1
            }
        }

        var configKey: ConfigKey? {
            didSet {
                guard let key = configKey else { return }
                switchKey = nil
                let config = FeatureSwitch.share.config(for: key)
                textLabel?.text = "key: \(key.rawValue)"
                detailTextLabel?.text = "\(config.isEmpty ? "Empty" : "- \(config.joined(separator: "\n- "))")"
                detailTextLabel?.numberOfLines = max(1, config.count)
            }
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            switchKey = nil
            configKey = nil
            textLabel?.text = nil
        }
    }

    final class DebugController: UIViewController {
        private var table = UITableView()
        private var search = UISearchBar()

        private var boolSection: [SwitchKey] = []
        private var arraySection: [ConfigKey] = []

        override func viewDidLoad() {
            super.viewDidLoad()
            self.view.addSubview(table)

            table.register(DebugCell.self, forCellReuseIdentifier: "reuse")
            table.dataSource = self
            table.delegate = self
            table.rowHeight = UITableView.automaticDimension
            table.contentInsetAdjustmentBehavior = .automatic
            table.estimatedRowHeight = 100

            search.placeholder = "请输入搜索内容"
            search.delegate = self
            search.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 45)

            table.tableHeaderView = search

            searchBar(search, textDidChange: "")

            title = "KA-FS-点击对应Cell修改对应配置"
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(cancel)
            )
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            self.table.frame = self.view.bounds
        }

        @objc
        private func cancel() {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension FeatureSwitch.DebugController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let cell = tableView.cellForRow(at: indexPath) as? FeatureSwitch.DebugCell else { return }

        if let key = cell.switchKey {
            FeatureSwitch.share.boolConfig[key] = !FeatureSwitch.share.bool(for: key)
            cell.switchKey = key
        } else if let key = cell.configKey {
            let controller = FeatureSwitch.ModifyArrayConfigController(key: key, onSave: {
                cell.configKey = key
                tableView.reloadRows(at: [indexPath], with: .automatic)
            })
            let navigaton = UINavigationController(rootViewController: controller)
            navigaton.modalPresentationStyle = .fullScreen
            self.present(navigaton, animated: true, completion: nil)
        }
    }
}

// MARK: - UITableViewDataSource
extension FeatureSwitch.DebugController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Bool"
        case 1: return "Array"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return boolSection.count
        case 1: return arraySection.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuse", for: indexPath)

        if let cell = cell as? FeatureSwitch.DebugCell {
            switch indexPath.section {
            case 0: if _fastPath(indexPath.row < boolSection.count) {
                cell.switchKey = boolSection[indexPath.row]
            }
            case 1: if _fastPath(indexPath.row < arraySection.count) {
                cell.configKey = arraySection[indexPath.row]
            }
            default: return cell
            }
        }

        return cell
    }
}

// MARK: - UISearchBarDelegate
extension FeatureSwitch.DebugController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchText = searchText.lowercased()
        if searchText.isEmpty {
            boolSection = FeatureSwitch.SwitchKey.allCases
            arraySection = FeatureSwitch.ConfigKey.allCases
        } else {
            boolSection = FeatureSwitch.SwitchKey.allCases.compactMap { $0.rawValue.fuzzyMatch(searchText) ? $0 : nil }
            arraySection = FeatureSwitch.ConfigKey.allCases.compactMap { $0.rawValue.fuzzyMatch(searchText) ? $0 : nil }
        }
        table.reloadData()
    }
}

// MARK: - Array Config Editor
fileprivate extension FeatureSwitch {
    final class ModifyArrayConfigController: UIViewController {
        private var textView = UITextView()
        private var label = UILabel()
        private var key: ConfigKey
        private var onSave: (() -> Void)?

        init(key: ConfigKey, onSave: (() -> Void)? = nil) {
            self.key = key
            self.onSave = onSave
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            self.view.addSubview(textView)
            self.view.backgroundColor = .white

            self.view.addSubview(label)
            label.alpha = 0.2
            label.isUserInteractionEnabled = false
            label.text = "使用换行输入多个\nEnter more than one with newline."
            label.numberOfLines = 2
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 20)

            textView.text = FeatureSwitch.share.config(for: key).joined(separator: "\n")

            let item: (UIBarButtonItem.SystemItem, Selector?) -> UIBarButtonItem? = { [weak self] (type, selector) in
                guard let self = self else { return nil }
                return .init(barButtonSystemItem: type, target: self, action: selector)
            }

            self.title = "\(key.rawValue)"
            self.navigationItem.leftBarButtonItem = item(.cancel, #selector(cancel))
            self.navigationItem.rightBarButtonItem = item(.save, #selector(save))
        }

        @objc
        private func cancel() {
            self.dismiss(animated: true, completion: nil)
        }

        @objc
        private func save() {
            textView.endEditing(true)
            FeatureSwitch.share.config[key] = textView.text
                .trimmingCharacters(in: .whitespaces)
                .components(separatedBy: "\n")
                .filter({ !$0.isEmpty })
            self.dismiss(animated: true, completion: nil)
            self.onSave?()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            textView.frame = view.bounds
            label.frame = view.bounds
        }
    }
}

extension FeatureGatingManager.Key {
    public init(switch: FeatureSwitch.SwitchKey) {
        self.init(stringLiteral: `switch`.rawValue)
    }
}
