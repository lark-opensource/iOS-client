//
//  ExtensionNotificationDetailViewController.swift
//  LarkExtensionAssembly
//
//  Created by yaoqihao on 2022/7/1.
//

import UserNotifications
import UIKit
import BootManager
import Foundation
import LarkUIKit
import LarkNotificationServiceExtension
import AppContainer
import NotificationUserInfo
import EENavigator

final class ExtensionNotificationDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var extra: [String: Any] = [:]
    var dataSource: [(String, Any)] = []

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "推送详情页"

        view.addSubview(tableView)
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

        tableView.register(NotificationLabelTableViewCell.self, forCellReuseIdentifier: "NotificationLabelTableViewCell")
    }

    func updateUI(extra: [String: Any]) {
        self.extra = extra
        self.dataSource = extra.enumerated().map({ (item) -> (String, Any) in
            return (item.element.key, item.element.value)
        })

        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count + 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.row == 0 {
            var cell: NotificationDebugTableViewCell
            if #available(iOSApplicationExtension 15.0, *) {
                cell = NotificationDebugTableViewIntentCell()
            } else {
                cell = NotificationDebugTableViewNormalCell()
            }

            let title = extra["apns.title"] as? String ?? ""
            let body = extra["apns.body"] as? String ?? ""

            guard let extra = LarkNSEExtra(dict: extra) else {
                return UITableViewCell()
            }

            cell.updateUI(title: title, body: body, extra: extra)
            return cell
        } else {
            let index = indexPath.row - 1
            let cell = NotificationLabelTableViewCell()
            let item = dataSource[index]
            cell.updateUI(title: item.0, detail: "\(item.1)")
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row == 0 else {
            return
        }

        let content = UNMutableNotificationContent()
        content.userInfo = extra

        let request = UNNotificationRequest(identifier: "", content: content, trigger: nil)

        guard let extra = LarkNSEExtra.getExtraDict(from: extra),
              let processor = extra.contentProcessor else {
            return
        }

        var userInfoExtra = processor.transformNotificationExtra(with: content)
        if let userid = extra.userId,
            let orginUrl = userInfoExtra?.content.url {
            userInfoExtra?.content.url = "//client/tenant/switch?userId=\(String(describing: userid))&&redirect=\(orginUrl)"
        }
        let userInfo = UserInfo(sid: extra.Sid, alert: nil, extra: userInfoExtra).toDict()

        let notificationCustom = Notification(isRemote: false, userInfo: userInfo)
        self.handle(notificationCustom)
    }

    private func handle(_ notification: AppContainer.Notification) {

        guard let userInfo = UserInfo(dict: notification.userInfo as? [String: Any] ?? [:]) else {
            return
        }

        if let urlString = userInfo.extra?.content.url, !urlString.isEmpty, let url = URL(string: urlString) {
            if let mainSceneWindow = Navigator.shared.mainSceneWindow {
                URLInterceptorManager.shared.handle(url, from: mainSceneWindow)
            }
        }
    }
}
