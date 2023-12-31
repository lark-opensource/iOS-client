//
//  DebugViewController.swift
//  LarkDebug
//
//  Created by CharlieSu on 11/17/19.
//
import Foundation
#if !LARK_NO_DEBUG
import UIKit
import LarkDebugExtensionPoint

final class DebugViewController: UIViewController {

    let tableView = UITableView(frame: .zero, style: .grouped)

    let data: [(SectionType, [DebugCellItem])] = SectionType.allCases.compactMap { (sectionType) in
        if let items = DebugCellItemRegistries[sectionType], !items.isEmpty {
            return (sectionType, items.map { $0() })
        } else {
            return nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addCloseItem()
        self.title = "高级调试"

        tableView.register(DebugTableViewCell.self, forCellReuseIdentifier: "DebugTableViewCell")
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

private extension DebugViewController {
    @discardableResult
    func addCloseItem() -> UIBarButtonItem {
        let barItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(backItemTapped))
        self.navigationItem.leftBarButtonItem = barItem
        return barItem
    }

    @objc
    func backItemTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource
extension DebugViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].1.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "DebugTableViewCell"
        ) as? DebugTableViewCell else {
            return UITableViewCell()
        }
        cell.detailTextLabel?.accessibilityIdentifier =
            "debugViewCellDetailTextLabel section:\(indexPath.section) row: \(indexPath.row)"
        cell.setItem(data[indexPath.section].1[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        let item = data[indexPath.section].1[indexPath.row]
        return item.canPerformAction != nil
    }

    func tableView(
        _ tableView: UITableView,
        canPerformAction action: Selector,
        forRowAt indexPath: IndexPath,
        withSender sender: Any?
    ) -> Bool {
        let item = data[indexPath.section].1[indexPath.row]
        return item.canPerformAction?(action) ?? false
    }

    func tableView(
        _ tableView: UITableView,
        performAction action: Selector,
        forRowAt indexPath: IndexPath,
        withSender sender: Any?
    ) {
        let item = data[indexPath.section].1[indexPath.row]
        item.perfomAction?(action)
    }
}

// MARK: - UITableViewDelegate
extension DebugViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return data[section].0.name
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        let item = data[indexPath.section].1[indexPath.row]
        item.didSelect(item, debugVC: self)
    }
}
#endif
