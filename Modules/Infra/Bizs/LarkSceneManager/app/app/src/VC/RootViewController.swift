//
//  RootViewController.swift
//  SceneDemo
//
//  Created by 李晨 on 2021/1/2.
//

import Foundation
import UIKit
import LarkSceneManager
import LarkKeyCommandKit

class RootViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDragDelegate {

    let tableView = UITableView()

    var dispose: NSObjectProtocol?

    var datas: [Item] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Root"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 80
        tableView.dragDelegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        self.datas = DataStore.fetch()

        dispose = NotificationCenter.default.addObserver(forName: DataStore.Noti.DataChange, object: nil, queue: nil) { [weak self] (noti) in
            if let datas = noti.object as? [Item] {
                self?.datas = datas
            }
        }

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .done, target: self,
                                                                 action: #selector(clickCreate))
        self.navigationItem.rightBarButtonItems?.append(UIBarButtonItem(title: "Switcher", style: .plain, target: self,
                                                                        action: #selector(pushSwitcherVC)))

        updateLeftItems()
//        pushSwitcherVC()
        KeyCommandKit.shared.register(keyBinding: KeyCommandBaseInfo(input: ",", modifierFlags: .command, discoverabilityTitle: "test").binding {
            self.clickAlert()
        })
    }

    @objc
    func pushSwitcherVC() {
        self.navigationController?.pushViewController(SwitcherTestVC(), animated: true)
    }

    func updateLeftItems() {
        var items = [
            UIBarButtonItem(title: "Alert", style: .done, target: self, action: #selector(clickAlert))
        ]

        if SceneManager.shared.supportsMultipleScenes {
            items.append(UIBarButtonItem(title: "Support", style: .done, target: self,
                                         action: #selector(clickSupport)))
        } else {
            items.append(UIBarButtonItem(title: "NoSupport", style: .done, target: self,
                                         action: #selector(clickSupport)))
        }

        self.navigationItem.leftBarButtonItems = items
    }

    @objc
    func clickCreate() {
        let create = CreateViewController()
        let navi = UINavigationController(rootViewController: create)
        navi.modalPresentationStyle = .formSheet
        Navigator.present(vc: navi)
    }

    /// 点击是否支持全屏，下次生效
    @objc
    func clickSupport() {
        let alert = UIAlertController(title: "修复多窗口支持", message: "修改多窗口支持 fg，下次启动生效", preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .cancel, handler: { (_) in
            if SceneManager.shared.supportsMultipleScenes {
                SceneManager.shared.update(supportsMultipleScenes: false)
            } else {
                SceneManager.shared.update(supportsMultipleScenes: true)
            }
            self.updateLeftItems()
        }))
        self.present(alert, animated: true, completion: nil)
    }

    /// 点击是否显示 alert
    @objc
    func clickAlert() {
        let alert = UIAlertController(title: "Alert", message: "添加一个全局 alert，alert 会监听 scene 变化，会在一个激活中 scene 上进行展示", preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .cancel, handler: { (_) in
            AlertManager.shared.open = true
        }))
        self.present(alert, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = self.datas[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data.title
        cell.detailTextLabel?.text = data.detail
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let data = self.datas[indexPath.row]
        let vc = DetailViewController(data: data)
        Navigator.push(vc: vc)
    }

    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {

        /// 支持拖拽
        /// 需要在 info.plist中注册 NSUserActivityTypes
        let data = self.datas[indexPath.row]
//        let activity = NSUserActivity.init(activityType: Scene.Key.detail.rawValue)
        let scene = Scene(key: SceneInfo.Key.detail.rawValue, id: data.id)
        let activity = SceneTransformer.transform(scene: scene)
        activity.userInfo = ["id": data.id]
        let itemProvider = NSItemProvider()
        itemProvider.registerObject(activity, visibility: .all)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }
}

