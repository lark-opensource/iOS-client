//
//  UDKVDomainController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/4.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import RxSwift
import EENavigator
import RxDataSources

final class UDKVDomainController: SearchTableController<UDKVDomainItem> {
    let spaceName: String
    let domainName: String
    let userDefaults: UserDefaults?

    override var shouldRegisterCell: Bool { false }

    init(space: String, domain: String) {
        spaceName = space
        domainName = domain

        let suiteName = "lark_storage.\(spaceName)"
        self.userDefaults = UserDefaults(suiteName: suiteName)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = domainName
        searchPlaceholder = "输入过滤文本..."
    }

    override func didSelected(item: UDKVDomainItem, cell: UITableViewCell) {
        if item.bool() != nil {
            if let switcher = cell.accessoryView as? UISwitch {
                switcher.setOn(!switcher.isOn, animated: true)
            }
        } else {
            guard let userDefaults = self.userDefaults else { return }
            let controller = UDKVEditorController(userDefaults: userDefaults, item: item)
            // TODO: 这里本来想用present的形式，但是发现不会触发self的生命周期，不知道为什么
            //  如果这个改回present了，就把MMKVDomainController,以及OldMMKV,OldUDKV中也改为present
            Navigator.shared.push(controller, from: self)
        }
    }

    override func didRemoved(item: UDKVDomainItem, cell: UITableViewCell) {
        self.userDefaults?.removeObject(forKey: item.actualKey)
    }

    override func configureCell(
        dataSource: TableViewSectionedDataSource<Section>,
        tableView: UITableView,
        indexPath: IndexPath,
        item: Section.Item
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: identiferSearchTableController
        ) ?? UITableViewCell(style: .value1, reuseIdentifier: identiferSearchTableController)

        let secondaryText: String

        if let bool = item.bool() {
            let switcher = UISwitch()
            switcher.isOn = bool
            switcher.tag = indexPath.row
            switcher.addTarget(self, action: #selector(switcherValueChanged), for: .valueChanged)
            cell.accessoryView = switcher
            secondaryText = ""
        } else {
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
            secondaryText = item.description
        }

        if #available(iOS 14.0, *) {
            var configuration = cell.defaultContentConfiguration()
            configuration.text = item.key
            configuration.secondaryText = secondaryText
            configuration.secondaryTextProperties.numberOfLines = 2
            cell.contentConfiguration = configuration
        } else {
            cell.textLabel?.text = item.key
            cell.detailTextLabel?.text = secondaryText
            cell.detailTextLabel?.numberOfLines = 2
        }

        return cell
    }

    override func loadAllData() -> [UDKVDomainItem] {
        guard let userDefaults = userDefaults else {
            return []
        }
        
        return userDefaults.dictionaryRepresentation().compactMap { (key, value) -> UDKVDomainItem? in
            let range = NSRange(location: 0, length: key.count)
            guard let result = keyRegex?.firstMatch(in: key, range: range) else { return nil }
            hasDataSubject.onNext(true)
            let domain = String(substring(key, withNSRange: result.range(at: 1)))
            let virtualKey = String(substring(key, withNSRange: result.range(at: 2)))
            guard domain == domainName else { return nil }
            return UDKVDomainItem(key: virtualKey, actualKey: key, value: value)
        }.sorted(by: { $0.key < $1.key })
    }

    @objc
    private func switcherValueChanged(switcher: UISwitch) {
        let indexPath = IndexPath(row: switcher.tag, section: 0)
        if let item = try? dataSource.model(at: indexPath) as? UDKVDomainItem {
            userDefaults?.set(switcher.isOn, forKey: item.actualKey)
        }
    }
}
#endif
