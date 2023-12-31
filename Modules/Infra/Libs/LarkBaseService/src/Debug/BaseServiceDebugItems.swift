//
//  BaseServiceDebugMenu.swift
//  LarkBaseService
//
//  Created by Miaoqi Wang on 2019/12/26.
//

import UIKit
import Foundation
import LarkDebug
import EENavigator
#if ALPHA
// Debug 库头文件有编译问题，暂时屏蔽
// import IESGeckoKitDebug
#endif
import LarkDebugExtensionPoint
import OfflineResourceManager
import Heimdallr
import LKCommonsLogging

struct DynamicDebugItem: DebugCellItem {

    var title: String { return "动态化调试" }
    var type: DebugCellType { return .disclosureIndicator }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Navigator.shared.push(MenuViewController(), from: debugVC) // Global
    }
    static var settingDisable: Bool = false
    static var resourceDiable: Bool = false
}

struct MemoryGraphDebugItem: DebugCellItem {
    static let logger = Logger.log(MemoryGraphDebugItem.self, category: "Application.Debug")
    var title: String { return "上传MemoryGraph" }
    var type: DebugCellType { return .disclosureIndicator }
    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        HMDMemoryGraphGenerator.shared().manualGenerateImmediateUpload(true) { (error) in
            if error != nil {
                MemoryGraphDebugItem.logger.error("upload Memory graph failed: \(String(describing: error))")
            }
        }
    }
}

extension DynamicDebugItem {
    struct ResourceDebugItem: DebugCellItem {
        var title: String = "Disable Offline Resource"
        var type: DebugCellType { return .switchButton }

        var isSwitchButtonOn: Bool {
            return DynamicDebugItem.resourceDiable
        }

        var switchValueDidChange: ((Bool) -> Void)? = { (on) in
            OfflineResourceManager.debugResourceDisable(on)
            DynamicDebugItem.resourceDiable = on
        }
    }

    struct SettingsDebugItem: DebugCellItem {
        var title: String = "Disable URL Map Settings"
        var type: DebugCellType { return .switchButton }

        var isSwitchButtonOn: Bool {
            return DynamicDebugItem.settingDisable
        }

        var switchValueDidChange: ((Bool) -> Void)? = { (on) in
            URLMapHandler.debugSettingsDisable(on)
            DynamicDebugItem.settingDisable = on
        }
    }

    struct GeckoDebugItem: DebugCellItem {
        var title: String { return "Gecko Setting" }
        var type: DebugCellType { return .disclosureIndicator }

        func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
            #if ALPHA
            // Debug 库头文件有编译问题，暂时屏蔽
            // IESGurdDebugEntry.presentDebugView(by: debugVC)
            #endif
        }
    }

    final class MenuViewController: UITableViewController {

        let data: [DebugCellItem] = [
            SettingsDebugItem(),
            ResourceDebugItem(),
            GeckoDebugItem()
        ]

        override func viewDidLoad() {
            super.viewDidLoad()
            tableView.register(DebugTableViewCell.self, forCellReuseIdentifier: DebugTableViewCell.lu.reuseIdentifier)
        }

        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return data.count
        }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: DebugTableViewCell.lu.reuseIdentifier,
                for: indexPath
            ) as? DebugTableViewCell {
                cell.setItem(data[indexPath.row])
                return cell
            } else {
                return UITableViewCell()
            }
        }

        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            guard tableView.cellForRow(at: indexPath) != nil else { return }

            let item = data[indexPath.row]
            if item.type != .switchButton {
                item.didSelect(item, debugVC: self)
            }
        }
    }
}

final class DebugTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var item: DebugCellItem?

    func setItem(_ item: DebugCellItem) {
        self.item = item
        textLabel?.text = item.title
        detailTextLabel?.text = item.detail

        switch item.type {
        case .none:
            accessoryType = .none
            selectionStyle = .none
            accessoryView = nil
        case .disclosureIndicator:
            accessoryType = .disclosureIndicator
            selectionStyle = .default
            accessoryView = nil
        case .switchButton:
            accessoryType = .none
            selectionStyle = .none

            let switchButton = UISwitch()
            switchButton.isOn = item.isSwitchButtonOn
            switchButton.addTarget(self, action: #selector(switchButtonDidClick), for: .valueChanged)
            accessoryView = switchButton
        @unknown default:
            #if DEBUG
            assert(false, "new value")
            #else
            break
            #endif
        }
    }

    @objc
    private func switchButtonDidClick() {
        let isOn = (accessoryView as? UISwitch)?.isOn ?? false
        item?.switchValueDidChange?(isOn)
    }
}
