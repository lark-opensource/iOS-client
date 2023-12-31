//
//  SandboxController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/16.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import RxSwift
import EENavigator
import LarkStorage
import RxDataSources

final class SandboxController: SectionSearchTableController<SandboxSection, SandboxTableViewCell> {
    static let identifier = "SandboxController"

    override func configureCell(
        dataSource: TableViewSectionedDataSource<SandboxSection>,
        tableView: UITableView,
        indexPath: IndexPath,
        item: SandboxItem
    ) -> SandboxTableViewCell {
        let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: Self.identifier)
        let cell = (dequeuedCell as? SandboxTableViewCell) ?? SandboxTableViewCell(
            style: .default,
            reuseIdentifier: SandboxController.identifier
        )
        cell.delegate = self

        let section = dataSource.sectionModels[indexPath.section]
        cell.section = section
        cell.item = item
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Sandbox"
        tableView.register(SandboxTableViewCell.self, forCellReuseIdentifier: Self.identifier)
        navigationItem.hidesSearchBarWhenScrolling = true
        searchController.searchBar.placeholder = "按业务过滤..."
    }

    override func loadAllData() -> [SandboxSection] {
        var data = [SandboxSection]()
        [.temporary, .cache, .document, .library].forEach {
            updateItemsInRoot(type: $0, data: &data)
        }
        return data
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        super.tableView(tableView, willDisplayHeaderView: view, forSection: section)
        if let view = view as? UITableViewHeaderFooterView {
            let sectionModel = dataSource[section]
            let textFont = UIFont.systemFont(ofSize: 18)
            let textColor: UIColor
            if sectionModel.isCurrentUser {
                textColor = UIColor(red: 0.16, green: 0.38, blue: 0.86, alpha: 1.00)
            } else {
                textColor = UIColor.gray
            }
            
            if #available(iOS 14.0, *) {
                var configuration = view.contentConfiguration as? UIListContentConfiguration ?? view.defaultContentConfiguration()
                configuration.text = sectionModel.space
                configuration.textProperties.font = textFont
                configuration.textProperties.color = textColor
                configuration.textProperties.numberOfLines = 0
                view.contentConfiguration = configuration
            } else {
                view.textLabel?.text = sectionModel.space
                view.textLabel?.font = textFont
                view.textLabel?.textColor = textColor
                view.textLabel?.numberOfLines = 0
            }
        }
    }

    private func updateItemsInRoot(type: RootPathType.Normal, data: inout [SandboxSection]) {
        let rootPath = (getRootPath(type: type) as NSString).appendingPathComponent(globalPrefix)

        guard let spaceFileNames = try? FileManager.default.contentsOfDirectory(atPath: rootPath) else {
            return
        }

        spaceFileNames.forEach { spaceFileName in
            guard spaceFileName.hasPrefix(spacePrefix) else { return }

            let spaceName = String(spaceFileName.dropFirst(spacePrefix.count))
            let spacePath = (rootPath as NSString).appendingPathComponent(spaceFileName)
            let domainNames = loadDomainNames(path: spacePath)
            guard !domainNames.isEmpty else { return }

            if let index = data.firstIndex(where: { $0.space == spaceName }) {
                updateInSection(type: type, domainNames: domainNames, section: &data[index])
            } else {
                var section = SandboxSection(space: spaceName, items: [])
                updateInSection(type: type, domainNames: domainNames, section: &section)
                data.append(section)
            }
        }
    }

    private func updateInSection(type: RootPathType.Normal, domainNames: [String], section: inout SandboxSection) {
        for domainName in domainNames {
            if let index = section.items.firstIndex(where: { $0.domain == domainName }) {
                section.items[index].roots.append(type)
            } else {
                let item = SandboxItem(domain: domainName, roots: [type])
                section.items.append(item)
            }
        }
    }

    private func loadDomainNames(path spacePath: String) -> [String] {
        guard let domainFileNames = try? FileManager.default.contentsOfDirectory(atPath: spacePath) else {
            return []
        }

        return domainFileNames.compactMap { domainFileName in
            guard domainFileName.hasPrefix(domainPrefix) else {
                return nil
            }

            return String(domainFileName.dropFirst(domainPrefix.count))
        }
    }
}

extension SandboxController: SandboxCellDelegate {
    func onTapCellItem(section: SandboxSection, item: SandboxItem, root: LarkStorage.RootPathType.Normal) {
        let path = getRootPath(type: root)
        let controller = SandboxFilesController(
            name: item.domain,
            root: path,
            space: section.space,
            domain: item.domain,
            relative: ""
        )
        Navigator.shared.push(controller, from: self)
    }

    func onTapDeleteButton(section: SandboxSection, item: SandboxItem) {
        let controller = UIAlertController(title: "提示", message: "是否删除该业务所有文件？", preferredStyle: .alert)
        controller.addAction(UIAlertAction(
            title: "取消",
            style: .cancel,
            handler: nil
        ))
        controller.addAction(UIAlertAction(
            title: "删除",
            style: .destructive,
            handler: { [weak self] _ in
                [.temporary, .cache, .document, .library].forEach { (root: RootPathType.Normal) in
                    let rootPath = getRootPath(type: root)
                    let path = NSString.path(withComponents: [
                        rootPath, globalPrefix, "\(spacePrefix)\(section.space)", "\(domainPrefix)\(item.domain)"
                    ])
                    try? FileManager.default.removeItem(atPath: path)
                }

                self?.reloadData()
            }
        ))
        present(controller, animated: true)
    }
}
#endif
