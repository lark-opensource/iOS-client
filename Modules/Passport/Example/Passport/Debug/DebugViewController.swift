//
//  DebugViewController.swift
//  LarkAccountDev
//
//  Created by Miaoqi Wang on 2021/3/8.
//

import UIKit
import LarkDebugExtensionPoint
import OfflineResourceManager

class DebugViewController: ListViewController {

    init() {
        super.init(items: [])

        DebugRegistry.registerDebugItem(ResourceDebugItem(), to: .debugTool)

        let debugItems = DebugCellItemRegistries.map { (itemDict) -> [Item] in
            return itemDict.value.map({ (provider) -> Item in
                let item = provider()
                switch item.type {
                case .disclosureIndicator, .none:
                    return Item(title: item.title, subtitle: item.detail, imageUrl: nil) {
                        item.didSelect(item, debugVC: self)
                    }
                case .switchButton:
                    return Item(
                        title: item.title,
                        subtitle: item.detail + "Current：\(item.isSwitchButtonOn ? "On" : "Off")",
                        imageUrl: nil
                    ) {
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

struct ResourceDebugItem: DebugCellItem {
    var title: String = "Disable Offline Resource"
    var type: DebugCellType { return .switchButton }

    private static var switchOn: Bool = false

    var isSwitchButtonOn: Bool {
        return Self.switchOn
    }

    var switchValueDidChange: ((Bool) -> Void)? = { (on) in
        OfflineResourceManager.debugResourceDisable(on)
        Self.switchOn = on
    }
}
