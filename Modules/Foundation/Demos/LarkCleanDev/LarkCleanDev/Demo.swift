//
//  Demo.swift
//  LarkCleanDev
//
//  Created by 李昊哲 on 2023/7/3.
//  

import Foundation
import RxSwift
import RxCocoa
import EENavigator
import AnimatedTabBar
import LarkAccountInterface
import LarkAssembler
import LarkCleanAssembly
import LarkContainer
import LarkTab
import LarkUIKit
import LarkClean
import LarkStorage

let demoDomain = Domain.biz.infra.child("LarkCleanDev")

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
    LarkNaviBarDelegate
{
    private static let identifier = "DemoViewController"
    private static let items: [TableItem] = [
        .action("Prepare Data", prepareData),
        .page("Clean Benchmark", BenchmarkController.self),
        .page("Debug Tool", getLarkCleanDebugControllerType()),
    ]

    var titleText: BehaviorRelay<String> { .init(value: "Demo") }

    var isNaviBarEnabled: Bool { false }

    var isDrawerEnabled: Bool { false }

    var tab: Tab { DemoTab.tab }

    var controller: UIViewController { self }

    static var imageDir = refreshImageDir()
    static var stringDir = refreshStringDir()

    private static func refreshImageDir() -> IsoPath {
        let timeStamp = Int(Date().timeIntervalSince1970.rounded())
        let path: IsoPath = .in(space: .global, domain: Domain.biz.infra.child("LarkCleanDev"))
            .build(forType: .cache, relativePart: "Image/\(timeStamp)")
        try? path.createDirectoryIfNeeded()
        return path
    }

    private static func refreshStringDir() -> IsoPath {
        let timeStamp = Int(Date().timeIntervalSince1970.rounded())
        let path: IsoPath = .in(space: .global, domain: Domain.biz.infra.child("LarkCleanDev"))
            .build(forType: .cache, relativePart: "String/\(timeStamp)")
        try? path.createDirectoryIfNeeded()
        return path
    }

    private static func prepareData() {
        @Provider var passport: PassportService
        DispatchQueue.global().async {
            // prepare path data
            Self.imageDir = Self.refreshImageDir()
            Self.stringDir = Self.refreshStringDir()

            let imgData: UIImage
            if #available(iOS 13.0, *) {
                imgData = UIImage(systemName: "trash") ?? UIImage()
            } else {
                imgData = UIImage()
            }
            let str = "String"
            for i in 0..<1000 {
                try? imgData.write(to: Self.imageDir + "\(i)")
                try? str.write(to: Self.stringDir + "\(i)")
            }

            // prepare vkey data
            let userSpaces = passport.userList.map { Space.user(id: $0.userID) }
            let spaces = userSpaces + [.global]
            for space in spaces {
                let udkv = KVStores.udkv(space: space, domain: demoDomain)

                udkv.set(42, forKey: "int")
                udkv.set("answer", forKey: "str")
                udkv.synchronize()

                let mmkv = KVStores.mmkv(space: space, domain: demoDomain)
                mmkv.set(42, forKey: "int")
                mmkv.set("answer", forKey: "str")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.identifier)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Self.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = Self.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.identifier, for: indexPath)
        cell.textLabel?.text = item.title
        cell.accessoryType = item.accessoryType
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        switch Self.items[indexPath.row] {
        case .action(_, let action): action()
        case .page(_, let page):
            Navigator.shared.push(page.init(), from: self)
        }
    }

    private enum TableItem {
        case action(String, () -> Void)
        case page(String, UIViewController.Type)

        var title: String {
            switch self {
            case .action(let title, _), .page(let title, _):
                return title
            }
        }

        var accessoryType: UITableViewCell.AccessoryType {
            switch self {
            case .action: return .none
            case .page: return .disclosureIndicator
            }
        }
    }
}

extension CleanRegistry {
    @_silgen_name("Lark.LarkClean_CleanRegistry.LarkCleanDev")
    public static func registerDebug() {
        registerPaths(forGroup: "LarkCleanDev/Image") { _ in
            return [
                .abs(DemoViewController.imageDir.absoluteString)
            ]
        }

        registerPaths(forGroup: "LarkCleanDev/String") { _ in
            return [
                .abs(DemoViewController.stringDir.absoluteString)
            ]
        }

        registerVkeys(forGroup: "LarkCleanDev/UDKV") { ctx in
            let spaces = ctx.userList.map { Space.user(id: $0.userId) } + [.global]
            return spaces.map { space in
                let unified = CleanIndex.Vkey.Unified(space: space, domain: demoDomain, type: .udkv)
                return .unified(unified)
            }
        }

        registerVkeys(forGroup: "LarkCleanDev/MMKV") { ctx in
            let spaces = ctx.userList.map { Space.user(id: $0.userId) } + [.global]
            return spaces.map { space in
                let unified = CleanIndex.Vkey.Unified(space: space, domain: demoDomain, type: .mmkv)
                return .unified(unified)
            }
        }

        registerIndexes(forGroup: "LarkCleanDev/Setting") { ctx in
            return CleanRegistry.parseIndexes(
                with: [
                    "kv_store": [
                        [
                            "type": "udkv",
                            "space": "{uid}",
                            "domain": Domain.biz.infra.isolationId,
                        ],
                        [
                            "type": "udkv",
                            "space": "global",
                            "domain": Domain.biz.infra.child("LarkCleanDev").asComponents().map(\.isolationId).joined(separator: ".")
                        ],
                        [
                            "type": "mmkv",
                            "space": "{uid}",
                            "domain": Domain.biz.infra.isolationId,
                        ]
                    ]
                ],
                context: ctx
            )
        }
    }
}
