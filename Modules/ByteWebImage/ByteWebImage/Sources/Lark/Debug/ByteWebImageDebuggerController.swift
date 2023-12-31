//
//  ByteWebImageDebuggerController.swift
//  ByteWebImage
//
//  Created by Saafo on 2022/9/1.
//

import Foundation
import LarkDebugExtensionPoint
import UIKit
import LKCommonsLogging
import LKCommonsTracker

enum DebugUtils {
    static func register() {
        DebugRegistry.registerDebugItem(ByteWebImageDebugItem(), to: .debugTool)
    }
}

struct ByteWebImageDebugItem: DebugCellItem {
    var title: String { "ByteWebImage Debugger" }
    var type: DebugCellType { .disclosureIndicator }
    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        debugVC.navigationController?.pushViewController(ByteWebImageDebuggerController(), animated: true)
    }
}

// MARK: - ByteWebImageDebuggerController

class ByteWebImageDebuggerController: UIViewController {

    struct DebugItem: DebugCellItem {
        /// Title will appear at left of the cell.
        var title: String

        /// Detail will appear at right of the cell.
        var detail: String = ""

        /// Type property controls the right area apperance of the cell.
        var type: LarkDebugExtensionPoint.DebugCellType = .none

        /// Controls whether switch button is on. Only works when self.type equals .switchButton.
        var isSwitchButtonOn: Bool = false

        /// Called when switch view changes its value. Only works when self.type equals .switchButton.
        var switchValueDidChange: ((Bool) -> Void)?

        /// Whether item can perform table view cell action.
        /// DebugViewController forwards its table view conrresponding method to this method.
        var canPerformAction: ((Selector) -> Bool)?

        /// Perform the action
        /// DebugViewController forwards its table view conrresponding method to this method.
        var perfomAction: ((Selector) -> Void)?

        var didSelectItem: ((LarkDebugExtensionPoint.DebugCellItem, UIViewController) -> Void)?

        /// Called when the corresponding cell is selected.
        func didSelect(_ item: LarkDebugExtensionPoint.DebugCellItem, debugVC: UIViewController) {
            didSelectItem?(item, debugVC)
        }
    }

    lazy var tableView: UITableView = {
        if #available(iOS 13, *) {
            return UITableView(frame: .zero, style: .insetGrouped)
        } else {
            return UITableView(frame: .zero, style: .grouped)
        }
    }()

    private static let logger = Logger.log(ByteWebImageDebuggerController.self, category: "ByteWebImageDebuggerController")

    lazy var data: KeyValuePairs<String, [DebugItem]> = {[
        "开关(修改重启失效)": [
            DebugItem(title: "编解码使用独立线程", type: .switchButton,
                      isSwitchButtonOn: DispatchImageQueue.usePrivateImageQueue,
                      switchValueDidChange: { value in
                          DispatchImageQueue.usePrivateImageQueue = value
                          LarkImageService.Debug.clearMemoryCache()
                          Self.logger.info("usePrivateImageQueue debug change to: \(value)")
                      }),
            DebugItem(title: "模糊查找缓存", type: .switchButton,
                      isSwitchButtonOn: ImageManager.default.fuzzyCache,
                      switchValueDidChange: { value in
                          ImageManager.default.fuzzyCache = value
                          LarkImageService.Debug.clearMemoryCache()
                          Self.logger.info("fuzzyCache debug change to: \(value)")
                      }),
            DebugItem(title: "头像加载使用HEIC", type: .switchButton,
                      isSwitchButtonOn: LarkImageService.shared.dependency.avatarDownloadHeic,
                      switchValueDidChange: { value in
                          LarkImageService.shared.dependency.avatarDownloadHeic = value
                          LarkImageService.Debug.clearMemoryAndDiskCache()
                          LarkImageService.Debug.clearSDKCache() // SDK 可能缓存另一种格式的图片，需要清除本地缓存
                          Self.logger.info("avatarDownloadHeic debug change to: \(value)")
                      }),
            DebugItem(title: "图片预加载", type: .switchButton,
                      isSwitchButtonOn: LarkImageService.shared.dependency.imagePreloadConfig.preloadEnable,
                      switchValueDidChange:  { value in
                          LarkImageService.shared.dependency.imagePreloadConfig.preloadEnable = value
                          LarkImageService.Debug.clearMemoryAndDiskCache()
                          LarkImageService.Debug.clearSDKCache() // SDK 可能缓存另一种格式的图片，需要清除本地缓存
                          Self.logger.info("image preload debug change to: \(value)")
                      }),
            DebugItem(title: "禁用WebP部分解析", type: .switchButton,
                      isSwitchButtonOn: ImageConfiguration.forbiddenWebPPartial,
                      switchValueDidChange: { value in
                          ImageConfiguration.forbiddenWebPPartial = value
                          LarkImageService.Debug.clearMemoryCache()
                          Self.logger.info("forbiddenWebPPartial debug change to: \(value)")
                      })
        ],
        "调试工具": [
            DebugItem(title: "预览Key对应的图片", type: .disclosureIndicator, didSelectItem: { _, vc in
                vc.navigationController?.pushViewController(PreviewImageController(), animated: true)
            })
        ],
        "缓存清理": [
            DebugItem(title: "清除缓存调试器", type: .switchButton,
                      isSwitchButtonOn: ClearCacheViewManager.viewExisted(on: self.view.window ?? self.view),
                      switchValueDidChange: { [weak self] value in
                          guard let window = self?.view.window else { return }
                          if value {
                              ClearCacheViewManager.showView(on: window)
                          } else {
                              ClearCacheViewManager.hideView(on: window)
                          }
                      }),
            DebugItem(title: "清除所有内存缓存", type: .none, didSelectItem: { _, vc in
                LarkImageService.Debug.clearMemoryCache()
                Self.showToast("清除缓存成功", on: vc)
            }),
            DebugItem(title: "清除所有内存磁盘缓存", type: .none, didSelectItem: { _, vc in
                LarkImageService.Debug.clearMemoryAndDiskCache()
                Self.showToast("清除缓存成功", on: vc)
            }),
            DebugItem(title: "清除SDK图片缓存", type: .none, didSelectItem: { _, vc in
                let succeeded = LarkImageService.Debug.clearSDKCache()
                if succeeded {
                    Self.showToast("清除缓存成功", on: vc)
                } else {
                    Self.showToast("清除缓存失败", on: vc)
                }
            })
        ]
    ]}()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .dynamicBackground
        view.addSubview(tableView)
        title = ByteWebImageDebugItem().title
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.register(ByteWebImageDebugTableViewCell.self, forCellReuseIdentifier: "ByteWebImageDebugTableViewCell")
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension ByteWebImageDebuggerController {
    static func showToast(_ toast: String, on vc: UIViewController) {
        let oldTitle = vc.navigationItem.title
        vc.title = toast
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak vc] in
            vc?.title = oldTitle
        }
    }
}

// MARK: - Utils

// MARK: UITableViewDataSource UITableViewDelegate

extension ByteWebImageDebuggerController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return data[section].value.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return data[section].key
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "ByteWebImageDebugTableViewCell"
        ) as? ByteWebImageDebugTableViewCell else {
            return UITableViewCell()
        }

        cell.setItem(data[indexPath.section].value[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        let item = data[indexPath.section].value[indexPath.row]
        return item.canPerformAction != nil
    }

    func tableView(
        _ tableView: UITableView,
        canPerformAction action: Selector,
        forRowAt indexPath: IndexPath,
        withSender sender: Any?
    ) -> Bool {
        let item = data[indexPath.section].value[indexPath.row]
        return item.canPerformAction?(action) ?? false
    }

    func tableView(
        _ tableView: UITableView,
        performAction action: Selector,
        forRowAt indexPath: IndexPath,
        withSender sender: Any?
    ) {
        let item = data[indexPath.section].value[indexPath.row]
        item.perfomAction?(action)
    }
}

extension ByteWebImageDebuggerController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        let item = data[indexPath.section].value[indexPath.row]
        item.didSelect(item, debugVC: self)
    }
}

// MARK: ByteWebImageDebugTableViewCell

class ByteWebImageDebugTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var item: DebugCellItem?

    func setItem(_ item: DebugCellItem) {
        self.item = item
        textLabel?.text = item.title
        detailTextLabel?.text = item.detail

        switch item.type {
        case .none:
            accessoryType = .none
            selectionStyle = .none
            accessoryView = nil
        case .disclosureIndicator:
            accessoryType = .disclosureIndicator
            selectionStyle = .default
            accessoryView = nil
        case .switchButton:
            accessoryType = .none
            selectionStyle = .none
            let switchButton = UISwitch()
            switchButton.isOn = item.isSwitchButtonOn
            switchButton.addTarget(self, action: #selector(switchButtonDidClick), for: .valueChanged)
            accessoryView = switchButton
        }
    }

    @objc
    private func switchButtonDidClick() {
        let isOn = (accessoryView as? UISwitch)?.isOn ?? false
        item?.switchValueDidChange?(isOn)
    }
}

// MARK: Dynamic Color

extension UIColor {
    static var dynamicBackground: UIColor = {
        if #available(iOS 13, *) {
            return UIColor { trait in
                if trait.userInterfaceStyle == .light {
                    return .white
                } else {
                    return .black
                }
            }
        } else {
            return .white
        }
    }()
}
