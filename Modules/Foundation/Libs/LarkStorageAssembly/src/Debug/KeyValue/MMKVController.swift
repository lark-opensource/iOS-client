//
//  MMKVController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/16.
//

#if !LARK_NO_DEBUG
import MMKV
import UIKit
import Foundation
import EENavigator
import RxDataSources

struct MMKVItem: TitledItem, Hashable {
    var domain: String

    var title: String {
        get { domain }
        set { domain = newValue }
    }

    func hash(into hasher: inout Hasher) {
        domain.hash(into: &hasher)
    }
}

struct MMKVSection: TitledSectionType {
    typealias Item = MMKVItem

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

extension MMKVSection {
    init(original: MMKVSection, items: [Item]) {
        self = original
        self.items = items
    }
}

final class MMKVController: SectionSearchTableController<MMKVSection, UITableViewCell> {
    static let identifier = "MMKVCell"

    override func configureCell(
        dataSource: TableViewSectionedDataSource<MMKVSection>,
        tableView: UITableView,
        indexPath: IndexPath,
        item: MMKVItem
    ) -> UITableViewCell {
        let cell = Self.dequeueReusableCell(
            tableView: tableView, withIdentifier: MMKVController.identifier, for: indexPath
        )
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = item.domain
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "MMKV"
        navigationItem.hidesSearchBarWhenScrolling = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: MMKVController.identifier)
        searchController.searchBar.placeholder = "按业务过滤..."
    }

    override func loadAllData() -> [MMKVSection] {
        var data = [MMKVSection]()
        let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        let rootPath = (libraryPath as NSString).appendingPathComponent("MMKV")

        (try? FileManager.default.contentsOfDirectory(atPath: rootPath))?.forEach { mmapID in
            guard !mmapID.hasSuffix(".crc") else { return }
            guard let result = mmRegex?.firstMatch(in: mmapID, range: makeNSRange(mmapID)) else {
                return
            }
            guard let mmkv = MMKV(mmapID: mmapID, rootPath: rootPath) else {
                return
            }

            let items = loadDomainItems(from: mmkv)
            guard !items.isEmpty else {
                return
            }

            let space = String(substring(mmapID, withNSRange: result.range(at: 1)))
            let section = MMKVSection(space: space, items: items)

            if section.isCurrentUser {
                data.insert(section, at: 0)
            } else {
                data.append(section)
            }
        }

        return data
    }

    override func didSelected(item: MMKVItem, section: MMKVSection) {
        let controller = MMKVDomainController(space: section.space, domain: item.domain)
        Navigator.shared.push(controller, from: self)
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

    private func loadDomainItems(from mmkv: MMKV) -> [MMKVItem] {
        var items = Set<MMKVItem>()
        mmkv.allKeys().forEach { key in
            guard let key = key as? String else {
                return
            }
            guard let result = keyRegex?.firstMatch(in: key, range: makeNSRange(key)) else {
                return
            }

            let domain = String(substring(key, withNSRange: result.range(at: 1)))
            items.insert(MMKVItem(domain: domain))
        }
        return Array(items).sorted(by: { $0.domain < $1.domain })
    }
}
#endif

