//
//  SystemUDKVController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/10.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import EENavigator
import RxDataSources

struct SystemUDKVItem: TitledItem, Equatable {
    var key: String
    var value: Any

    var title: String {
        get { key }
        set { key = newValue }
    }

    static func == (lhs: SystemUDKVItem, rhs: SystemUDKVItem) -> Bool {
        lhs.key == rhs.key
    }
}

struct SystemUDKVSection: TitledSectionType {
    typealias Item = SystemUDKVItem

    let title: String
    let isSpace: Bool
    let userDefaults: UserDefaults
    var items: [Item]

    let isCurrentUser: Bool

    init(title: String, items: [Item], isSpace: Bool, userDefaults: UserDefaults) {
        self.title = title
        self.items = items
        self.isSpace = isSpace
        self.userDefaults = userDefaults
        self.isCurrentUser = isSpace && checkCurrentUser(space: title)
    }
}

extension SystemUDKVSection {
    init(original: SystemUDKVSection, items: [Item]) {
        self = original
        self.items = items
    }
}

final class SystemUDKVController: SectionSearchTableController<SystemUDKVSection, UITableViewCell> {
    private static let identifier = "SystemUDKVController"

    override func configureCell(
        dataSource: TableViewSectionedDataSource<SystemUDKVSection>,
        tableView: UITableView,
        indexPath: IndexPath,
        item: SystemUDKVItem
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.identifier
        ) ?? UITableViewCell(style: .subtitle, reuseIdentifier: Self.identifier)

        if #available(iOS 14.0, *) {
            var configuration = cell.defaultContentConfiguration()
            configuration.text = item.key
            configuration.secondaryText = String(describing: item.value)
            cell.contentConfiguration = configuration
        } else {
            cell.textLabel?.text = item.key
            cell.detailTextLabel?.text = String(describing: item.value)
        }
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "标准UserDefaults"
        searchController.searchBar.placeholder = "按Key过滤..."
    }

    override func didSelected(item: SystemUDKVItem, section: SystemUDKVSection) {
        let newItem = UDKVDomainItem(key: item.key, actualKey: item.key, value: item.value)
        let controller = UDKVEditorController(userDefaults: section.userDefaults, item: newItem)
        Navigator.shared.push(controller, from: self)
    }

    override func loadAllData() -> [SystemUDKVSection] {
        var data = [SystemUDKVSection]()
        let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        let rootPath = (libraryPath as NSString).appendingPathComponent("Preferences")

        (try? FileManager.default.contentsOfDirectory(atPath: rootPath))?.forEach { suiteName in
            guard let userDefaults = UserDefaults(suiteName: suiteName) else {
                return
            }

            let isSpace: Bool
            let title: String
            if let result = udRegex?.firstMatch(in: suiteName, range: makeNSRange(suiteName)) {
                isSpace = true
                title = String(substring(suiteName, withNSRange: result.range(at: 1)))
            } else {
                isSpace = false
                title = (suiteName as NSString).deletingPathExtension
            }

            let items = loadKeyValues(from: userDefaults)
            let section = SystemUDKVSection(
                title: title, items: items, isSpace: isSpace, userDefaults: userDefaults
            )

            if section.isCurrentUser {
                data.insert(section, at: 0)
            } else {
                data.append(section)
            }
        }

        return data
    }

    private func loadKeyValues(from userDefaults: UserDefaults) -> [SystemUDKVItem] {
        Array(userDefaults.dictionaryRepresentation().lazy.filter { key, _ in
            // 如果正则匹配成功说明符合规范，不需要显示
            keyRegex?.firstMatch(in: key, range: makeNSRange(key)) == nil
        }.map { key, value in
            SystemUDKVItem(key: key, value: value)
        }).sorted(by: { $0.key < $1.key })
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        super.tableView(tableView, willDisplayHeaderView: view, forSection: section)
        if let view = view as? UITableViewHeaderFooterView {
            let sectionModel = dataSource[section]
            let textColor: UIColor
            if sectionModel.isCurrentUser {
                textColor = UIColor(red: 0.16, green: 0.38, blue: 0.86, alpha: 1.00)
            } else {
                textColor = UIColor.gray
            }


            if #available(iOS 14.0, *) {
                var configuration = view.contentConfiguration as? UIListContentConfiguration ?? view.defaultContentConfiguration()
                configuration.text = sectionModel.title
                configuration.textProperties.font = .systemFont(ofSize: 18)
                configuration.textProperties.color = textColor
                configuration.textProperties.numberOfLines = 0
                view.contentConfiguration = configuration
            } else {
                view.textLabel?.font = .systemFont(ofSize: 18)
                view.textLabel?.textColor = textColor
                view.textLabel?.numberOfLines = 0
            }
        }
    }
}
#endif
