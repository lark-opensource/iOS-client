//
//  ExtensionNotificationDebug.swift
//  LarkExtensionAssembly
//
//  Created by yaoqihao on 2022/6/29.
//

import Foundation
import LarkDebugExtensionPoint
import EENavigator
import LarkUIKit
import UniverseDesignIcon
import LarkNotificationServiceExtension
import NotificationUserInfo
import UIKit

// Debug 工具代码，无需进行统一存储规则检查
// lint:disable lark_storage_check

struct NotificationDebugItem: DebugCellItem {
    var title: String { return "获取推送内容" }

    var type: DebugCellType { return .disclosureIndicator }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Navigator.shared.push(NotificationDebugViewController(), from: debugVC)
    }
}

final class NotificationDebugViewController: UIViewController, CircleMenuDelegate, UITableViewDelegate, UITableViewDataSource {

    var items: [(icon: UIImage, color: UIColor)] = []
    var dataSource: [[String: Any]] = []

    lazy var menu: CircleMenu = {
        let menu = CircleMenu(
            frame: CGRect(x: 0, y: 0, width: 50, height: 50),
            normalIcon: UDIcon.appDefaultFilled.withColor(UIColor.ud.iconN2),
            selectedIcon: UDIcon.appDefaultFilled.withColor(UIColor.ud.iconN2),
            buttonsCount: 2,
            duration: 1,
            distance: 80)

        menu.backgroundColor = UIColor.ud.G400
        menu.subButtonsRadius = 20
        return menu
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "推送Debug"

        self.updateItems()

        menu.delegate = self
        menu.layer.cornerRadius = menu.frame.size.width / 2.0
        view.addSubview(tableView)
        view.addSubview(menu)
        menu.snp.remakeConstraints { make in
            make.width.height.equalTo(50)
            make.centerX.equalTo(self.view.snp.right)
            make.bottom.equalToSuperview().offset(-80)
        }

        self.view.backgroundColor = UIColor.ud.bgFloatBase
        tableView.backgroundColor = .clear

        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
        tableView.dataSource = self
        tableView.delegate = self
        if #available(iOSApplicationExtension 15.0, *) {
            tableView.register(NotificationDebugTableViewIntentCell.self, forCellReuseIdentifier: "NotificationDebugTableViewIntentCell")
        } else {
            tableView.register(NotificationDebugTableViewNormalCell.self, forCellReuseIdentifier: "NotificationDebugTableViewNormalCell")
        }

        updateDataSource()
    }

    private func updateItems() {
        let isOpen = NotificationDebugCache.isEnabled

        if !isOpen {
            items = [(UDIcon.bitableLockOutlined.withColor(UIColor.ud.iconN2) ?? UIImage(), UIColor.ud.R400)]
        } else {
            items = [(UDIcon.banFilled.withColor(UIColor.ud.iconN2) ?? UIImage(), UIColor.ud.R400),
                    (UDIcon.refreshOutlined.withColor(UIColor.ud.iconN2) ?? UIImage(), UIColor.ud.B400),
                    (UDIcon.addBoldOutlined.withColor(UIColor.ud.iconN2) ?? UIImage(), UIColor.ud.Y400)]
        }

        menu.buttonsCount = items.count
    }

    private func updateDataSource() {
        guard let dataSource = NotificationDebugCache.receivedContents else {
            self.dataSource = []
            tableView.reloadData()
            return
        }

        self.dataSource = dataSource
        tableView.reloadData()
        NotificationDebugCache.receivedContents = nil
    }

    func circleMenu(_: CircleMenu, willDisplay button: UIButton, atIndex: Int) {
        button.backgroundColor = items[atIndex].color

        button.setImage(items[atIndex].icon, for: .normal)

        // set highlited image
        let highlightedImage = items[atIndex].icon.withRenderingMode(.alwaysTemplate)
        button.setImage(highlightedImage, for: .highlighted)
    }

    func circleMenu(_: CircleMenu, buttonDidSelected _: UIButton, atIndex: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            UIView.animate(withDuration: 0.5) {
                self.menu.snp.remakeConstraints { make in
                    make.width.height.equalTo(50)
                    make.centerX.equalTo(self.view.snp.right)
                    make.bottom.equalToSuperview().offset(-80)
                }
            }
        }

        if atIndex == 0 {
            NotificationDebugCache.isEnabled = !NotificationDebugCache.isEnabled

            updateItems()
        } else if atIndex == 1 {
            updateDataSource()
        } else if atIndex == 2 {
            Navigator.shared.present(ExtensionNotificationAPNSViewController(), wrap: LkNavigationController.self, from: self)
        }
    }

    func menuCollapsed(_ circleMenu: CircleMenu) {
        UIView.animate(withDuration: 0.5) {
            self.menu.snp.remakeConstraints { make in
                make.width.height.equalTo(50)
                make.centerX.equalTo(self.view.snp.right)
                make.bottom.equalToSuperview().offset(-80)
            }
        }
    }

    func menuOpened(_ circleMenu: CircleMenu) {
        UIView.animate(withDuration: 0.5) {
            self.menu.snp.remakeConstraints { make in
                make.width.height.equalTo(50)
                make.right.equalToSuperview().offset(-80)
                make.bottom.equalToSuperview().offset(-80)
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let data = dataSource[indexPath.row]

        var cell: NotificationDebugTableViewCell
        if #available(iOSApplicationExtension 15.0, *) {
            cell = NotificationDebugTableViewIntentCell()
        } else {
            cell = NotificationDebugTableViewNormalCell()
        }

        let title = data["apns.title"] as? String ?? ""
        let body = data["apns.body"] as? String ?? ""

        guard let extra = LarkNSEExtra(dict: data) else {
            return UITableViewCell()
        }

        cell.updateUI(title: title, body: body, extra: extra)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        let data = dataSource[indexPath.row]

        let vc = ExtensionNotificationDetailViewController()
        vc.updateUI(extra: data)

        Navigator.shared.push(vc, from: self)
    }
}
