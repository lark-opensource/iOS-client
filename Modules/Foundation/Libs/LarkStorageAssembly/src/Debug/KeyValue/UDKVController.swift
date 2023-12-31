//
//  UDKVController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/16.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import EENavigator
import LarkStorage
import RxDataSources

struct UDKVItem: TitledItem, Hashable {
    var domain: String

    var title: String {
        get { domain.replacingOccurrences(of: "_", with: ".") }
    }

    func hash(into hasher: inout Hasher) {
        domain.hash(into: &hasher)
    }
}

struct UDKVSection: TitledSectionType {
    typealias Item = UDKVItem

    let space: String
    var items: [Item]

    let isCurrentUser: Bool
    var title: String { space }

    init(space: String, items: [Item]) {
        self.space = space
        self.items = items
        self.isCurrentUser = checkCurrentUser(space: space)
    }
}

extension UDKVSection {
    init(original: UDKVSection, items: [Item]) {
        self = original
        self.items = items
    }
}

final class UDKVController: SectionSearchTableController<UDKVSection, UITableViewCell> {
    static let identifier = "UDKVCell"
    override func configureCell(
        dataSource: TableViewSectionedDataSource<UDKVSection>,
        tableView: UITableView,
        indexPath: IndexPath,
        item: UDKVItem
    ) -> UITableViewCell {
        let cell = Self.dequeueReusableCell(tableView: tableView, withIdentifier: UDKVController.identifier, for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = item.domain
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "UDKV"
        navigationItem.hidesSearchBarWhenScrolling = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UDKVController.identifier)
        searchController.searchBar.placeholder = "按业务过滤..."
    }

    override func loadAllData() -> [UDKVSection] {
        var data = [UDKVSection]()
        let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        let rootPath = (libraryPath as NSString).appendingPathComponent("Preferences")

        (try? FileManager.default.contentsOfDirectory(atPath: rootPath))?.forEach { suiteName in
            guard let result = udRegex?.firstMatch(in: suiteName, range: makeNSRange(suiteName)) else {
                return
            }
            guard let userDefaults = UserDefaults(suiteName: suiteName) else {
                return
            }

            let items = loadDomainItems(from: userDefaults)
            guard !items.isEmpty else {
                return
            }

            let space = String(substring(suiteName, withNSRange: result.range(at: 1)))
            let section = UDKVSection(space: space, items: items)

            if section.isCurrentUser {
                data.insert(section, at: 0)
            } else {
                data.append(section)
            }
        }

        return data
    }

    override func didSelected(item: UDKVItem, section: UDKVSection) {
        let controller = UDKVDomainController(space: section.space, domain: item.domain)
        Navigator.shared.push(controller, from: self)
    }

    private func loadDomainItems(from userDefaults: UserDefaults) -> [UDKVItem] {
        var domains = Set<UDKVItem>()
        userDefaults.dictionaryRepresentation().forEach { key, _ in
            guard let result = keyRegex?.firstMatch(in: key, range: makeNSRange(key)) else {
                return
            }
            let domain = String(substring(key, withNSRange: result.range(at: 1)))
            domains.insert(UDKVItem(domain: domain))
        }
        return Array(domains).sorted(by: { $0.domain < $1.domain })
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
                configuration.text = sectionModel.space
                configuration.textProperties.font = .systemFont(ofSize: 18)
                configuration.textProperties.color = textColor
                configuration.textProperties.numberOfLines = 0
                view.contentConfiguration = configuration
            } else {
                view.textLabel?.text = sectionModel.space
                view.textLabel?.font = .systemFont(ofSize: 18)
                view.textLabel?.textColor = textColor
                view.textLabel?.numberOfLines = 0
            }
        }
    }
}
#endif
