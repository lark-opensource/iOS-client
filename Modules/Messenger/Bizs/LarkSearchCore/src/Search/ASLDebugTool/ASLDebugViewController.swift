//
//  ASLDebugViewController.swift
//  LarkSearchCore
//
//  Created by chenziyue on 2021/12/13.
//

import Foundation
import UIKit
import LarkDebugExtensionPoint
import LarkStorage
import LarkContainer

extension ASLDebugItem {
    final class ASLDebugViewController: UITableViewController {
        let userResolver: UserResolver
        var data: [ASLDebugCellItem]
        init(userResolver: UserResolver) {
            self.userResolver = userResolver
            self.data = [ LynxLocalItem(), ASLTextFieldItem(), ContextIdItem(), ASLFGItem(userResolver: userResolver) ]
            super.init(style: .grouped)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        override func viewDidLoad() {
            super.viewDidLoad()
            tableView.register(ASLDebugTableViewCell.self, forCellReuseIdentifier: ASLDebugTableViewCell.lu.reuseIdentifier)
        }
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return data.count
        }
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: ASLDebugTableViewCell.lu.reuseIdentifier,
                for: indexPath
            ) as? ASLDebugTableViewCell {
                cell.setItem(data[indexPath.row])
                return cell
            } else {
                return UITableViewCell()
            }
        }
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            guard tableView.cellForRow(at: indexPath) != nil else { return }

            var item = data[indexPath.row]
            if item.title == "Hosts:" && ASLDebugItem.isLynxDebugOn { // 针对本地Lynx Debug的一些配置
                let alertController = UIAlertController(title: "Host",
                                    message: "请输入host", preferredStyle: .alert)
                alertController.addTextField { (textField: UITextField!) -> Void in
                    textField.placeholder = "host"
                }
                let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                let okAction = UIAlertAction(title: "好的", style: .default, handler: { [weak self] _ in
                    let host: String = alertController.textFields?.first?.text ?? ""
                    if !host.isEmpty {
                        self?.data[indexPath.row].detail = host
                        let store = KVStores.SearchDebug.globalStore
                        store[KVKeys.SearchDebug.lynxHostKey] = host
                        self?.tableView.reloadRows(at: [indexPath], with: .none)
                    }
                })
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
            if item.type != .switchButton {
                item.didSelect(item, debugVC: self)
            }
        }
    }
}
