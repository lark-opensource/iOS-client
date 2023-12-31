//
//  ViewController.swift
//  ByteWebImage
//
//  Created by xiongmin on 03/17/2021.
//  Copyright (c) 2021 xiongmin. All rights reserved.
//

import ByteWebImage
import RxSwift
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
        LarkImageService.shared.clearAllCache()
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
                },
                "rust网络图片": {
                    let imageController = ImageController()
                    let rustUrl = URL(string: "rust://image/img_v2_35d72427-6303-421a-92f3-d6995bbcb68g")
                    imageController.url = rustUrl
                    self.navigationController?.pushViewController(imageController, animated: true)
                }
            ],
            "通过LarkImageSource设置图片": [
                "LarkImageSource.default": {
                    let resource = LarkImageResource.default(key: "img_v2_f1cf3bbe-985f-48cd-af35-36b08bf9448g")
                    let resourceController = LarkResourceController()
                    resourceController.resource = resource
                    self.navigationController?.pushViewController(resourceController, animated: true)
                },
                "LarkImageSource.avatar": {
                    let avatarResource = LarkImageResource.avatar(key: "23b161b6-8015-49da-a7af-4834764d373g", entityID: "6843570050205564929", params: AvatarViewParams(sizeType: SizeType.size(48), format: .webp))
                    let resourceController = LarkResourceController()
                    resourceController.resource = avatarResource
                    self.navigationController?.pushViewController(resourceController, animated: true)
                },
                "LarkImageSource.sticker": {
                    let resourceController = LarkResourceController()
                    let directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/stickerSet"
                    let stickerResource = LarkImageResource.sticker(key: "img_16d50b8b-a18b-4f77-85e8-b89cc5cc1eeg_MIDDLE_WEBP", stickerSetID: "", downloadDirectory: directory)
                    resourceController.resource = stickerResource
                    self.navigationController?.pushViewController(resourceController, animated: true)
                },
                "LarkImageSource File协议": {
                    let filePath = "file://" + path(name: "helo", type: "jpg")
                    let resource = LarkImageResource.default(key: filePath)
                    let resourceController = LarkResourceController()
                    resourceController.resource = resource
                    self.navigationController?.pushViewController(resourceController, animated: true)
                },
                "LarkImageSource data(Base64)协议": {
                    let resource = LarkImageResource.default(key: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==")
                    let resourceController = LarkResourceController()
                    resourceController.resource = resource
                    self.navigationController?.pushViewController(resourceController, animated: true)
                },
                "LarkImageSource http(s)协议": {
                    let resource = LarkImageResource.default(key: "https://t7.baidu.com/it/u=1819248061,230866778&fm=193&f=GIF")
                    let resourceController = LarkResourceController()
                    resourceController.resource = resource
                    self.navigationController?.pushViewController(resourceController, animated: true)
                }
            ],
            "超大图分片加载": [
                "超大图分片加载": {
                    let path = Bundle.main.path(forResource: "ChinaMap", ofType: "jpg")!

                    let controller = TiledImageController(with: path, usePreview: true)
                    self.navigationController?.pushViewController(controller, animated: true)
                }
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
