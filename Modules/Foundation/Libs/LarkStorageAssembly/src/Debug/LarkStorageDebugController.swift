//
//  LarkStorageDebugController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/10/31.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import EENavigator
import LarkStorage
import LarkAlertController

private protocol DestructiveAlert {
    static var title: String { get }
    static var cancelText: String { get }
    static var confirmText: String { get }
    static var description: String { get }
    static func confirmHandler()
}

private extension DestructiveAlert {
    static var cancelText: String { "取消" }
    static var confirmText: String { "确定" }
    static var description: String { "确定要\(title)？" }
}

private final class ClearMigrationMarks: DestructiveAlert {
    static let title = "清除所有迁移标记"
    static func confirmHandler() {
        Domains.Business.allCases.forEach { domain in
            KVStores.clearMigrationMarks(forDomain: domain)
        }
    }
}

private final class ClearAllForCurrentUser: DestructiveAlert {
    static let title = "清除当前用户的UDKV数据"
    static func confirmHandler() {
        KVStores.clearAllForCurrentUser(type: .udkv)
    }
}

private final class ClearAllForGlobal: DestructiveAlert {
    static let title = "清除用户无关的UDKV数据"
    static func confirmHandler() {
        KVStores.clearAll(forSpace: .global, type: .udkv)
    }
}

private final class ClearStandardUserDefaults: DestructiveAlert {
    static let title = "清除标准的UserDefaults数据"
    static func confirmHandler() {
        KVUtils.clearStandardUserDefaults(excludeKeys: [], sync: false)
    }
}

private final class ClearLaunchGuideUserDefaults: DestructiveAlert {
    static let title = "清除LaunchGuide的UserDefaults数据"
    static func confirmHandler() {
        let store = KVStores.udkv(
            space: .global,
            domain: Domain.biz.core.child("LaunchGuide")
        )
        store.clearAll()
        store.synchronize()
    }
}

//private final class ClearSandbox: DestructiveAlert {
//    static let title = "清除Sandbox的文件"
//    static func confirmHandler() {
//        let documentPath = getRootPath(type: .document)
//        let sandboxPath = (documentPath as NSString).appendingPathComponent(globalPrefix)
//        let manager = FileManager.default
//        try? manager.removeItem(atPath: sandboxPath)
//    }
//}

private final class ResetLark: DestructiveAlert {
    static let title = "重置Lark"
    static let description = "确定要重置Lark？\n(重置后,需要杀掉应用后重新登录)"
    static func confirmHandler() {
        // TODO: 考虑清除UserSpaceService的文件夹
//        if let userDirURL = self.userSpace.currentUserDirectory {
//            try? Path(userDirURL.path).deleteFile()
//        }

        // Remove All UserDefaults
        let libraryPath = getRootPath(type: .library)
        let preferencePath = (libraryPath as NSString).appendingPathComponent("Preferences")
        let manager = FileManager.default
        (try? manager.contentsOfDirectory(atPath: preferencePath))?.forEach {
            let path = (preferencePath as NSString).appendingPathComponent($0)
            try? manager.removeItem(atPath: path)
        }

        // Remove All MMKV
        let mmkvPath = (libraryPath as NSString).appendingPathComponent("MMKV")
        (try? manager.contentsOfDirectory(atPath: mmkvPath))?.forEach {
            let path = (mmkvPath as NSString).appendingPathComponent($0)
            try? manager.removeItem(atPath: path)
        }

        // TODO: 考虑清除Sandbox的文件
        // Remove LarkStorage/Sandbox
//        let documentPath = getRootPath(type: .document)
//        let sandboxPath = (documentPath as NSString).appendingPathComponent(globalPrefix)
//        try? manager.removeItem(atPath: sandboxPath)

        // Remove rust auth client storage data
        let rustPath = AbsPath.document + "sdk_storage"
        try? rustPath.notStrictly.removeItem()
    }
}

public func LarkStorageDebugController() -> UIViewController {
    _LarkStorageDebugController()
}

final class _LarkStorageDebugController: UITableViewController {
    private static let cellID = "cell"
    private static let sections: [(String, [TableItem])] = [
        ("统一存储 KeyValue", [
            .page("UDKV", UDKVController.self),
            .page("MMKV", MMKVController.self),
        ]),
        ("统一存储 Sandbox", [
            .page("查看", SandboxController.self),
            .page("加解密", CryptoController.self)
        ]),
        ("系统 KeyValue", [
            .page("UserDefaults", SystemUDKVController.self),
            .page("UserDefaults(AppGroup)", SharedUDKVController.self),
            .page("MMKV", SystemMMKVController.self),
        ]),
//        ("系统 Container", [
//            .pager("Container", SystemContainerControllerProvider),
//            .pager("AppGroup", SharedContainerControllerProvider),
//        ]),
        ("其它", [
            .alert(ClearMigrationMarks.self),
            .alert(ClearAllForCurrentUser.self),
            .alert(ClearAllForGlobal.self),
            .alert(ClearStandardUserDefaults.self),
            .alert(ClearLaunchGuideUserDefaults.self),
//            .alert(ClearSandbox.self),
            .alert(ResetLark.self),
        ])
    ]

    init() {
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellID)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Self.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Self.sections[section].1.count
    }

    override func tableView(
        _ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int
    ) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.font = .systemFont(ofSize: 18)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Self.sections[section].0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = Self.item(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellID, for: indexPath)
        cell.textLabel?.text = item.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        switch Self.item(at: indexPath) {
        case .page(_, let Controller):
            Navigator.shared.push(Controller.init(), from: self)
        case .pager(_, let provider):
            Navigator.shared.push(provider(), from: self)
        case .alert(let alert):
            let alertController = LarkAlertController()
            alertController.addSecondaryButton(text: alert.cancelText)
            alertController.setTitle(text: alert.description)
            alertController.addDestructiveButton(text: alert.confirmText, dismissCompletion: alert.confirmHandler)
            Navigator.shared.present(alertController, from: self)
        }
    }

    private static func item(at indexPath: IndexPath) -> TableItem {
        sections[indexPath.section].1[indexPath.row]
    }

    private enum TableItem {
        case page(String, UIViewController.Type)
        case pager(String, () -> UIViewController)
        case alert(DestructiveAlert.Type)

        var title: String {
            switch self {
            case .page(let title, _), .pager(let title, _): return title
            case .alert(let alert): return alert.title
            }
        }
    }
}
#endif
