//
//  SystemMMKVController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/10.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import MMKV
import EENavigator
import RxDataSources

struct SystemMMKVItem: TitledItem {
    var key: String

    var title: String { get { key } set { key = newValue } }
}

struct SystemMMKVSection: TitledSectionType {
    typealias Item = SystemMMKVItem

    let title: String
    let isSpace: Bool
    let mmkv: MMKV
    var items: [Item]

    let isCurrentUser: Bool

    init(title: String, items: [Item], isSpace: Bool, mmkv: MMKV) {
        self.title = title
        self.items = items
        self.isSpace = isSpace
        self.mmkv = mmkv
        self.isCurrentUser = isSpace && checkCurrentUser(space: title)
    }
}

extension SystemMMKVSection {
    init(original: SystemMMKVSection, items: [Item]) {
        self = original
        self.items = items
    }
}

final class SystemMMKVController: SectionSearchTableController<SystemMMKVSection, UITableViewCell> {
    private static let identifier = "SystemMMKVController"

    override func configureCell(
        dataSource: TableViewSectionedDataSource<SystemMMKVSection>,
        tableView: UITableView,
        indexPath: IndexPath,
        item: SystemMMKVItem
    ) -> UITableViewCell {
        let cell = Self.dequeueReusableCell(tableView: tableView, withIdentifier: Self.identifier, for: indexPath)
        cell.textLabel?.text = item.key
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "标准MMKV"
        searchController.searchBar.placeholder = "按Key过滤..."
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.identifier)
    }

    override func didSelected(item: SystemMMKVItem, section: SystemMMKVSection) {
        let newItem = MMKVDomainItem(key: item.key, actualKey: item.key)
        let controller = MMKVEditorController(mmkv: section.mmkv, item: newItem)
        Navigator.shared.push(controller, from: self)
    }

    override func reloadData() {
        dispatchQueue.async { [weak self] in
            guard let self = self else { return }

            var data = [SystemMMKVSection]()
            let rootPath = NSHomeDirectory()
            let manager = FileManager.default

            (try? manager.subpathsOfDirectory(atPath: rootPath))?.forEach { subpath in
                guard subpath.hasSuffix(".crc") else { return }
                let subpath = subpath as NSString
                let directory = (rootPath as NSString).appendingPathComponent(subpath.deletingLastPathComponent)
                let mmapID = (subpath.lastPathComponent as NSString).deletingPathExtension

                guard let mmkv = MMKV(mmapID: mmapID, rootPath: directory) else {
                    return
                }

                let isSpace: Bool
                let title: String
                if let result = mmRegex?.firstMatch(in: mmapID, range: makeNSRange(mmapID)) {
                    isSpace = true
                    title = String(substring(mmapID, withNSRange: result.range(at: 1)))
                } else {
                    isSpace = false
                    title = mmapID
                }

                let items = self.loadKeyValues(from: mmkv)
                guard !items.isEmpty else { return }

                let section = SystemMMKVSection(title: title, items: items, isSpace: isSpace, mmkv: mmkv)
                if section.isCurrentUser {
                    data.insert(section, at: 0)
                } else {
                    data.append(section)
                }

                self.dataSubject.onNext(data)
            }
        }
    }

    private func loadKeyValues(from mmkv: MMKV) -> [SystemMMKVItem] {
        Array(mmkv.allKeys().lazy.compactMap { key in
            key as? String
        }.filter { key in
            // 如果正则匹配成功说明符合规范，不需要显示
            keyRegex?.firstMatch(in: key, range: makeNSRange(key)) == nil
        }.map { key in
            SystemMMKVItem(key: key)
        }).sorted(by: { $0.key < $1.key })
    }

    override func tableView(
        _ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int
    ) {
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
                var configuration = (
                    view.contentConfiguration as? UIListContentConfiguration
                ) ?? view.defaultContentConfiguration()
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
