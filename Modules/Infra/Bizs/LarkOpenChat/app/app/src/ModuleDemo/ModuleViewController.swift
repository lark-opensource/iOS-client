//
//  ModuleViewController.swift
//  LarkOpenChatDev
//
//  Created by 李勇 on 2020/12/9.
//

import Foundation
import UIKit
import LarkOpenChat
import Swinject

class ModuleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let dataSource: [String] = ["ChatBannerModule"]
    private var bannerModuleDidRegister: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "ModuleViewController"
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = UITableViewCell(style: .default, reuseIdentifier: nil)

        tableViewCell.textLabel?.text = self.dataSource[indexPath.row]

        return tableViewCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.row {
        /// ChatBannerModule，工程搜索"ChatBannerModule-"可查看所有关键代码
        case 0:
            if !self.bannerModuleDidRegister {
                self.bannerModuleDidRegister = true
                // ChatBannerModule-0：register ChatBannerSubModule
                ChatBannerModule.register(ChatMeetingBannerModule.self)
                ChatBannerModule.register(ChatCalendarBannerModule.self)
                // should first show Calendar Banner
                ChatBannerModule.priorities([ChatCalendarBannerModule.self])
            }

            // ChatBannerModule-1：load ChatBannerModule
            let context = ChatModuleContext(parent: Container())
            ChatBannerModule.onLoad(context: context.bannerContext)
            let vc = ChatBannerModuleController(context: context)
            context.container.register(ChatOpenService.self) { [unowned vc] (_) -> ChatOpenService in
                return vc
            }
            ChatBannerModule.registGlobalServices(container: context.container)
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
