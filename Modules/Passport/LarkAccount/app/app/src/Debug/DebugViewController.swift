//
//  DebugViewController.swift
//  LarkAccountDev
//
//  Created by Miaoqi Wang on 2021/3/8.
//

import UIKit
import LarkDebugExtensionPoint

class DebugViewController: ListViewController {

    init() {
        super.init(items: [])
        let debugItems = DebugCellItemRegistries.map { (itemDict) -> [Item] in
            return itemDict.value.map({ (provider) -> Item in
                let item = provider()
                switch item.type {
                case .disclosureIndicator, .none:
                    return Item(title: item.title, subtitle: item.detail, imageUrl: nil) { (_) in
                        item.didSelect(item, debugVC: self)
                    }
                case .switchButton:
                    return Item(
                        title: item.title,
                        subtitle: item.detail + "Current：\(item.isSwitchButtonOn ? "On" : "Off")",
                        imageUrl: nil
                    ) { (_) in
                        item.switchValueDidChange?(!item.isSwitchButtonOn)
                        self.dismiss(animated: true, completion: nil) // 关闭 重新打开刷新数据。。
                    }
                }
            })
        }
        self.items = debugItems
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Debug Menu"
    }
}
