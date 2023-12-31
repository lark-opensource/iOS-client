//
//  CreateViewController.swift
//  SceneDemo
//
//  Created by 李晨 on 2021/1/3.
//

import Foundation
import UIKit
import LarkSceneManager

class CreateViewController: BaseViewController {

    let titleField: UITextField = UITextField()
    let detailField: UITextField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Create"

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

        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Create", style: .done, target: self, action: #selector(clickCreate)),
            UIBarButtonItem(title: "Scene", style: .done, target: self, action: #selector(clickScene))
        ]
    }

    @objc
    func clickCreate() {
        if let title = titleField.text,
           !title.isEmpty,
           let detail = detailField.text,
           !detail.isEmpty {
            DataStore.create(title: title, detail: detail)
            if #available(iOS 13.0, *) {
                let type = self.view.window?.windowScene?.userActivity?.activityType
                if type == SceneInfo.Key.create.rawValue, let scene = self.view.window?.windowScene {
                    SceneManager.shared.deactive(from: scene)
                    return
                }
            }
            Navigator.dismiss()
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

        let scene = Scene(key: SceneInfo.Key.create.rawValue, id: "", title: "Create")
        if #available(iOS 13.0, *) {
            SceneManager.shared.active(scene: scene, from: self.view.window?.windowScene, callback: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.presentingViewController != nil {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Dismiss", style: .done, target: self,
                                                                    action: #selector(clickDismiss))
        }
    }

    @objc
    func clickDismiss() {
        Navigator.dismiss()
    }
}
