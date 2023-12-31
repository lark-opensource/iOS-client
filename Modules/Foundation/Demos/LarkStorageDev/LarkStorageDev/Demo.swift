//
//  Demo.swift
//  LarkStorageDev
//
//  Created by 7Up on 2022/10/31.
//

import UIKit
import Foundation
import Swinject
import LarkContainer
import LarkTab
import LarkUIKit
import EENavigator
import LarkAssembler
import AnimatedTabBar
import RxCocoa
import LarkStorage
import LarkStorageAssembly

class DemoAssembly: LarkAssemblyInterface {
    init() { }

    func registRouter(container: Container) {
        Navigator.shared.registerRoute_(plainPattern: DemoTab.tab.urlString, priority: .high) { (_, res) in
            let vc = DemoViewController()
            res.end(resource: LkNavigationController(rootViewController: vc))
        }
    }

    func registTabRegistry(container: Container) {
        (DemoTab.tab, { (_: [URLQueryItem]?) -> TabRepresentable in
            DemoTab()
        })
    }
}

final class DemoTab: TabRepresentable {
    static var tab: Tab { .feed }
    var tab: Tab { Self.tab }
}

final class DemoViewController: UITableViewController,
    TabRootViewController,
    LarkNaviBarDataSource,
    LarkNaviBarDelegate {
    var titleText: BehaviorRelay<String> { .init(value: "Demo") }

    var isNaviBarEnabled: Bool { false }

    var isDrawerEnabled: Bool { false }

    var tab: Tab { DemoTab.tab }

    var controller: UIViewController { self }

    override func viewDidLoad() {
        super.viewDidLoad()

        let controller = LarkStorageDebugController()
        self.addChild(controller)
        self.view.addSubview(controller.view)
        controller.didMove(toParent: self)
        
        let userId = KVStores.getCurrentUserId?() ?? "User_123"
        let store1 = KVStores.udkv(space: .user(id: userId), domain: Domain.biz.setting)
        let store2 = KVStores.udkv(space: .user(id: userId), domain: Domain.biz.feed)
        let store3 = KVStores.udkv(space: .user(id: userId), domain: Domain.biz.ccm)
        store1["int"] = 1
        store1["bool"] = true
        store1["str"] = "hello"
        store1["data"] = [1, 2, 3]
        store2["yes"] = 1
        store2["long"] = String(repeating: "abcde", count: 500)
        store2["cool"] = 2.0
        store3["nice"] = [1:1, 2:2]
        store3["hhh"] = "cool"
        
        let store4 = KVStores.mmkv(space: .global, domain: Domain.biz.setting)
        let store5 = KVStores.mmkv(space: .global, domain: Domain.biz.ka)
        let store6 = KVStores.mmkv(space: .global, domain: Domain.biz.ccm)
        
        store4["key1"] = "value1"
        store5["key2"] = "value2"
        store6["key3"] = "value3"

        let dir1 = IsoPath.in(space: .global, domain: Domain.biz.messenger).build(.temporary)
        let dir2 = dir1 + "OCRImage"
        try? dir1.createDirectoryIfNeeded()
        try? dir2.createDirectoryIfNeeded()
        try? IsoPath.in(space: .user(id: userId), domain: Domain.biz.setting)
            .build(.temporary).createDirectoryIfNeeded()
        try? IsoPath.in(space: .user(id: userId), domain: Domain.biz.feed)
            .build(.library).createDirectoryIfNeeded()
        try? IsoPath.in(space: .user(id: userId), domain: Domain.biz.ccm)
            .build(.document).createDirectoryIfNeeded()
        try? IsoPath.in(space: .user(id: userId), domain: Domain.biz.ka)
            .build(.cache).createDirectoryIfNeeded()
        
        let file1 = dir1 + "test.txt"
        let file2 = dir2 + "hhh.txt"
        
        try? file1.createFileIfNeeded()
        try? file2.createFileIfNeeded()
        
        try? "Test".write(to: file1)
        try? "File2".write(to: file2)
    }
}
