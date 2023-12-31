//
//  TangramDemoViewController.swift
//  TangramUIComponentDev
//
//  Created by 袁平 on 2021/4/22.
//

import Foundation
import UIKit
import UniverseDesignColor
import LarkZoomable

class TangramDemoViewController: UIViewController {
    typealias OnTap = () -> Void
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = 62
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    var dataSource: [(title: String, onTap: OnTap)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        bindObserver()
        setupNaviBar()
        setupTableView()
    }

    func bindObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Zoom.didChangeNotification, object: nil)
    }

    func setupTableView() {
        view.addSubview(tableView)
        tableView.frame = view.frame

        dataSource = [
            ("HeaderView", { self.push(DemoHeaderViewController()) }),
            ("SpinButton", { self.push(DemoSpinButtonViewController()) }),
            ("TagList", { self.push(DemoTagListViewController()) }),
            ("AvatarList", { self.push(DemoAvatarListViewController()) }),
            ("VideoCover", { self.push(DemoVideoCoverViewController()) }),
            ("ImageView", { self.push(DemoImageViewController()) })
        ]
    }

    func setupNaviBar() {
        let fontSetting = UIBarButtonItem(title: "Font", style: .plain, target: self, action: #selector(pushSetting))
        fontSetting.tag = 1
        navigationItem.rightBarButtonItems = [fontSetting]

        let themeSetting = UIBarButtonItem(title: "Theme", style: .plain, target: self, action: #selector(pushSetting))
        themeSetting.tag = 2
        navigationItem.rightBarButtonItems = [fontSetting, themeSetting]
    }

    @objc
    func pushSetting(_ sender: UIBarButtonItem) {
        if sender.tag == 1 {
            push(FontSettingViewController())
        } else if sender.tag == 2 {
            if #available(iOS 13.0, *) {
                push(ThemeSettingViewController())
            }
        }
    }

    func push(_ vc: UIViewController) {
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc
    func reload() {
        self.tableView.reloadData()
    }
}

extension TangramDemoViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        dataSource[indexPath.row].onTap()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = dataSource[indexPath.row].title
        cell.textLabel?.font = UIFont.ud.body2
        return cell
    }
}
