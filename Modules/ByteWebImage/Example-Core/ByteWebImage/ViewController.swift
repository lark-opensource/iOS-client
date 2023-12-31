//
//  ViewController.swift
//  ByteWebImage
//
//  Created by xiongmin on 03/17/2021.
//  Copyright (c) 2021 xiongmin. All rights reserved.
//

import ByteWebImage
import UIKit

class ViewController: UIViewController {
    private var tableView: UITableView!

    private var imageView: UIImageView?
    private let queue = DispatchQueue(label: "com.test.serial")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tableView = UITableView()
        tableView.frame = view.frame
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        let clearItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(clean))
        self.navigationItem.rightBarButtonItem = clearItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("didReceiveMemoryWarning!!")
    }
    @objc
    func clean() {
        ImageCache.default.clearAll()
        print("清除缓存成功!!")
    }
}

func path(name: String, type: String?) -> String {
    return Bundle.main.path(forResource: name, ofType: type) ?? ""
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    var tableViewData: KeyValuePairs<String, KeyValuePairs<String, (() -> Void)>> { // KeyValuePairs keeps in order
        [
            "普通通过URL设置图片": [
                "本地图片": {
                    let imageController = ImageController()
                    let url = URL(fileURLWithPath: path(name: "helo", type: "jpg"))
                    imageController.url = url
                    self.navigationController?.pushViewController(imageController, animated: true)
                },
                "本地动图APNG": {
                    let imageController = AnimatedImageController()
                    let url = URL(fileURLWithPath: path(name: "disco", type: "png"))
                    imageController.url = url
                    self.navigationController?.pushViewController(imageController, animated: true)
                },
                "本地heic": {
                    let imageController = ImageController()
                    let url = URL(fileURLWithPath: path(name: "test_1200x800", type: "heic"))
                    imageController.url = url
                    self.navigationController?.pushViewController(imageController, animated: true)

                },
                "本地webp": {
                    let imageController = ImageController()
                    let url = URL(fileURLWithPath: path(name: "forest-868715", type: "webp"))
                    imageController.url = url
                    self.navigationController?.pushViewController(imageController, animated: true)
                },
                "本地webp动图": {
                    let imageController = AnimatedImageController()
                    let url = URL(fileURLWithPath: path(name: "one_loop@2x", type: "webp"))
                    imageController.url = url
                    self.navigationController?.pushViewController(imageController, animated: true)
                },
                "本地GIF图": {
                    let imageController = AnimatedImageController()
                    let url = URL(fileURLWithPath: path(name: "timg", type: "gif"))
                    imageController.url = url
                    self.navigationController?.pushViewController(imageController, animated: true)
                },
                "Base64图片": {
                    let imageController = ImageController()
                    let url = URL(string: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==")
                    imageController.url = url
                    self.navigationController?.pushViewController(imageController, animated: true)
                },
                "http网络图片": {
                    let imageController = ImageController()
                    let url = URL(string: "https://t7.baidu.com/it/u=1819248061,230866778&fm=193&f=GIF")
                    imageController.url = url
                    self.navigationController?.pushViewController(imageController, animated: true)
                }
            ],
            "超大图分片加载-TiledImageView": [
                "超大图分片加载": {
                    let path = Bundle.main.path(forResource: "ChinaMap", ofType: "jpg")!

                    let controller = TiledImageController(with: path, usePreview: false)
                    self.navigationController?.pushViewController(controller, animated: true)
                },
                "超大图-JPG": {
                    let path = Bundle.main.path(forResource: "HugeJPG", ofType: "jpg")!

                    let controller = TiledImageController(with: path, usePreview: false)
                    self.navigationController?.pushViewController(controller, animated: true)
                },
                "超大图-PNG": {
                    let path = Bundle.main.path(forResource: "HugePNG", ofType: "png")!

                    let controller = TiledImageController(with: path, usePreview: false)
                    self.navigationController?.pushViewController(controller, animated: true)
                },
                "超大图-WebP": {
                    let path = Bundle.main.path(forResource: "HugeWebP", ofType: "webp")!

                    let controller = TiledImageController(with: path, usePreview: false)
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            ],
            "超大图分片加载-HugeImageView": [
                "超大图分片加载": {
                    let path = Bundle.main.path(forResource: "ChinaMap", ofType: "jpg")!

                    let controller = TiledImageController(with: path, usePreview: true)
                    self.navigationController?.pushViewController(controller, animated: true)
                },
                "超大图-JPG": {
                    let path = Bundle.main.path(forResource: "HugeJPG", ofType: "jpg")!

                    let controller = TiledImageController(with: path, usePreview: true)
                    self.navigationController?.pushViewController(controller, animated: true)
                },
                "超大图-PNG": {
                    let path = Bundle.main.path(forResource: "HugePNG", ofType: "png")!

                    let controller = TiledImageController(with: path, usePreview: true)
                    self.navigationController?.pushViewController(controller, animated: true)
                },
                "超大图-WebP": {
                    let path = Bundle.main.path(forResource: "HugeWebP", ofType: "webp")!

                    let controller = TiledImageController(with: path, usePreview: true)
                    self.navigationController?.pushViewController(controller, animated: true)
                },
                "本地webp动图": {
                    let path = Bundle.main.path(forResource: "one_loop@2x", ofType: "webp")!
                    let controller = TiledImageController(with: path, usePreview: true)
                    self.navigationController?.pushViewController(controller, animated: true)
                },
            ]
        ]
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        tableViewData.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        tableViewData[section].key
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableViewData[section].value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = tableViewData[indexPath.section].value[indexPath.row].key
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableViewData[indexPath.section].value[indexPath.row].value()
    }
}
