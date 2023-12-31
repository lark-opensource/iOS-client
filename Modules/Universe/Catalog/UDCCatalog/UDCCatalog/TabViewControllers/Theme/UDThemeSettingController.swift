//
//  UDThemeSettingController.swift
//  UDCCatalog
//
//  Created by bytedance on 2021/3/28.
//  Copyright © 2021 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignTheme

class UDThemeSettingController: UIViewController {

    let chatList = Chat.getExamples()
    let messageList = Message.getExamples()

    private var container: UDThemeSettingView {
        if let view = self.view as? UDThemeSettingView {
            return view
        } else {
            let view = UDThemeSettingView()
            self.view = view
            return view
        }
    }

    override func loadView() {
        view = UDThemeSettingView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "主题预览"
        setupViews()
        container.darkModeControl.addTarget(self, action: #selector(didChangeDarkMode(_:)), for: .valueChanged)

        if #available(iOS 13.0, *) {
            container.darkModeControl.selectedSegmentIndex =
                UDThemeManager.userInterfaceStyle.rawValue
        } else {
            container.darkModeControl.isHidden = true
        }
    }

    private func setupViews() {
        container.messageView.dataSource = self
        container.chatView.dataSource = self
        container.messageView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        container.chatView.register(ChatCell.self, forCellReuseIdentifier: "ChatCell")
    }

    @objc
    private func didChangeDarkMode(_ sender: UISegmentedControl) {
        if #available(iOS 13.0, *) {
            let style = UIUserInterfaceStyle(rawValue: sender.selectedSegmentIndex)!
            UDThemeManager.setUserInterfaceStyle(style)
        }
    }

    private func updateTabels() {
        container.chatView.reloadData()
        container.messageView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === container.chatView {
            return chatList.count
        } else {
            return messageList.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === container.chatView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell") as? ChatCell ?? ChatCell()
            cell.selectionStyle = .none
            cell.configure(with: chatList[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") as? MessageCell ?? MessageCell()
            let continuous = indexPath.row != 0 && messageList[indexPath.row - 1].id == messageList[indexPath.row].id
            cell.configure(with: messageList[indexPath.row], continuous: continuous)
            return cell
        }
    }
}

extension UDThemeSettingController: UITableViewDataSource {}
