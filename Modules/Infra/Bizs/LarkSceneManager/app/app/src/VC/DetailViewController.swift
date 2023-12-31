//
//  DetailViewController.swift
//  SceneDemo
//
//  Created by 李晨 on 2021/1/3.
//

import Foundation
import UIKit
import LarkSceneManager

class DetailViewController: BaseViewController {

    var data: Item

    var dispose: NSObjectProtocol?
    var dispose2: NSObjectProtocol?

    let titleField: UITextField = UITextField()

    let detailField: UITextField = UITextField()

    let timeLabel: UILabel = UILabel()

    init(data: Item) {
        self.data = data
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Detail"

        self.view.addSubview(titleField)
        titleField.placeholder = "Title"
        titleField.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(10)
            maker.top.equalTo(100)
        }

        self.view.addSubview(detailField)
        detailField.placeholder = "Detail"
        detailField.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(10)
            maker.top.equalTo(titleField.snp.bottom).offset(100)
        }

        self.view.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(10)
            maker.top.equalTo(detailField.snp.bottom).offset(40)
        }

        update()

        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Delete", style: .done, target: self, action: #selector(clickDelete)),
            UIBarButtonItem(title: "Update", style: .done, target: self, action: #selector(clickUpdate)),
            UIBarButtonItem(title: "Scene", style: .done, target: self, action: #selector(clickScene))
        ]

        dispose = NotificationCenter.default.addObserver(forName: DataStore.Noti.DataUpdate, object: nil, queue: nil) { [weak self] (noti) in
            if let data = noti.object as? Item, data.id == self?.data.id {
                self?.data = data
                self?.update()
            }
        }

        dispose2 = NotificationCenter.default.addObserver(forName: DataStore.Noti.DataDelete, object: nil, queue: nil) { [weak self] (noti) in
            if let data = noti.object as? Item, data.id == self?.data.id {
                let alert = UIAlertController(title: "Deleted", message: nil, preferredStyle: .alert)
                alert.addAction(.init(title: "OK", style: .cancel, handler: { (_) in
                    guard let self = self else { return }
                    if #available(iOS 13.0, *) {
                        let type = self.view.window?.windowScene?.userActivity?.activityType
                        if type == SceneInfo.Key.detail.rawValue, let scene = self.view.window?.windowScene {
                            SceneManager.shared.deactive(from: scene)
                            return
                        }
                    }
                    Navigator.pop()
                }))
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }

    func update() {
        self.titleField.text = self.data.title
        self.detailField.text = self.data.detail
        self.timeLabel.text = "\(Date(timeIntervalSince1970: data.date))"
    }

    @objc
    func clickDelete() {
        DataStore.delete(data: data)
        if #available(iOS 13.0, *) {
            let type = self.view.window?.windowScene?.userActivity?.activityType
            if type == SceneInfo.Key.detail.rawValue, let scene = self.view.window?.windowScene {
                SceneManager.shared.deactive(from: scene)
                return
            }
        }
        Navigator.pop()
    }

    @objc
    func clickUpdate() {
        if let title = titleField.text,
           !title.isEmpty,
           let detail = detailField.text,
           !detail.isEmpty {
            var d = self.data
            d.title = title
            d.detail = detail
            DataStore.update(data: d)
        } else {
            let alert = UIAlertController(title: "不能为空", message: nil, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    @objc
    func clickScene() {
        if !SceneManager.shared.supportsMultipleScenes {
            let alert = UIAlertController(title: "Not Support", message: nil, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        let scene = Scene(key: SceneInfo.Key.detail.rawValue, id: data.id, title: self.data.title)
        if #available(iOS 13.0, *) {
            SceneManager.shared.active(scene: scene, from: self.view.window?.currentScene(), callback: nil)
        }
    }
}
