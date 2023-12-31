//
//  ViewController.swift
//  LarkResourceDev
//
//  Created by 李晨 on 2020/2/23.
//

import Foundation
import UIKit
import LarkResource

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var tableView = UITableView()

    var items: [ResourceKey] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.frame = UIScreen.main.bounds
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "123")

        let baseKey1 = BaseKey(key: "BK_sample_key_0/MK_sample_key_1", extensionType: .image)
        let baseKey2 = BaseKey(key: "BK_sample_key_0/MK_sample_key_2", extensionType: .image)
        let baseKey3 = BaseKey(key: "BK_sample_key_0/MK_sample_key_3", extensionType: .image)
        let baseKey4 = BaseKey(key: "BK_sample_key_0/MK_sample_key_4", extensionType: .image)
        let baseKey5 = BaseKey(key: "BK_sample_key_0/MK_sample_key_5", extensionType: .image)
        items = [
            ResourceKey(baseKey: baseKey1, env: Env(theme: "light", language: "zh")),
            ResourceKey(baseKey: baseKey1, env: Env(theme: "light", language: "en")),
            ResourceKey(baseKey: baseKey1, env: Env(theme: "light", language: "ja")),
            ResourceKey(baseKey: baseKey2, env: Env(theme: "dark", language: "zh")),
            ResourceKey(baseKey: baseKey3, env: Env(theme: "custom", language: "en")),
            ResourceKey(baseKey: baseKey4, env: Env(theme: "light", language: "en")),
            ResourceKey(baseKey: baseKey5, env: Env(theme: "light", language: "en"))
        ]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "123", for: indexPath)
        if indexPath.row % 2 == 0 {
            DispatchQueue.global().async {
                let image: UIImage? = ResourceManager.resource(key: self.items[indexPath.row])
                DispatchQueue.main.async {
                    cell.imageView?.image = image
                }
            }
        } else {
            let image: UIImage? = ResourceManager.resource(key: self.items[indexPath.row])
            cell.imageView?.image = image
        }

        cell.textLabel?.text = items[indexPath.row].baseKey.key + " " + items[indexPath.row].env.language + " " +
            items[indexPath.row].env.theme
        return cell
    }
}
