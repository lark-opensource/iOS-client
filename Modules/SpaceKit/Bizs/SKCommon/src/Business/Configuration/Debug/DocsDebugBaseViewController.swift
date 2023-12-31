//
//  DocsDebugBaseViewController.swift
//  Docs
//
//  Created by nine on 2018/11/7.
//  Copyright © 2018 Bytedance. All rights reserved.
//

import UIKit
import EENavigator
import SKUIKit
import UniverseDesignToast
import UniverseDesignDialog
import LarkEMM
import SKInfra

public enum DebugCellTitle: String {
    case specialPkgInfo = "手动指定包详情[点击]"
    case grayscalePkgInfo = "mina灰度包详情[点击]"
    case geckoPkgInfo = "热更包详情[点击]"
    case removeLocalFullPkgResource = "点击清除本地完整包"
    case removeLocalGrayscalePkgResource = "点击清除本地灰度包"
    case forceUseSimplePkg = "是否强制使用精简包(最高优先级)"
#if BETA || ALPHA || DEBUG
    case cleanDriveCache = "清除 Drive 缓存"
    case driveLocalPreview = "Drive本地预览"
    case cleanWikiDb = "清除 Wiki 数据库"
    case larkFGDebug = "LarkFG 调试"
//    case minaFGDebug = "Mina 配置平台调试"
    case nativeEditorSheetJSServer = "Sheet JS Server"
    case nativeEditorPreloadJSServer = "Preload JS Server"
    case lynxJSURL = "lynx proxy"
    case lynxDevtoolOpen = "lynx devtool连接"
    case lynxPkgCustom = "custom lynx pkg version"
    case showLynxPkgInfo = "display current lynx pkg info"
    case cipherDelete = "模拟在线文档企业密钥删除"
    case killAllWebViewProcess = "关闭所有WebView进程"
    case clearWKWebViewCache = "清理WebView缓存"
#endif
    #if BETA || ALPHA || DEBUG
    case openInlineAI = "AI浮窗测试"
    case inlineAIResSetting = "AI浮窗资源配置"
    #endif
}

open class DocsDebugBaseViewController: UIViewController {

    public var debugDataSouce: [(String, [DocsDebugCellItem])] = []

    fileprivate let cellID = NSStringFromClass(UITableViewCell.self)
    #if BETA || ALPHA || DEBUG
    lazy var autoOpenDocsMgr = DocsAutoOpenDocsManager.manager(navigator: self)
    lazy var driveAutoPerformanceTest = DocsContainer.shared.resolve(DriveAutoPerformanceTestBase.self, argument: self as UIViewController?)!
    #endif

    lazy var debugTableView: UITableView = {
        let debugTableView = UITableView(frame: CGRect.zero, style: .grouped)
        debugTableView.dataSource = self
        debugTableView.delegate = self
        return debugTableView
    }()

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.title = "调一调 试一试"
        self.view.backgroundColor = UIColor.ud.N00
        configDebugDataSource()

        configNavigation()
        configUI()
    }

    func configNavigation() {
        self.navigationItem.setLeftBarButton({
            let strmoji = ["ヽ(｀Д´)ﾉ", "(･ェ･。)", " (●ﾟωﾟ●)", "ヾ(=･ω･=)o", " (｡♥‿♥｡)", "_(:з」∠)_", "⊙﹏⊙|||", "o(*≧▽≦)ツ"]
            return UIBarButtonItem(title: strmoji.randomElement() ?? "返回", style: .done, target: self, action: #selector(didSelectBack))
        }(), animated: false)

        view.addSubview(debugTableView)
    }

    func configUI() {
        debugTableView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }
    }

    func config(_ cell: UITableViewCell, with debugCellItem: DocsDebugCellItem) {
        cell.textLabel?.text = debugCellItem.title
        cell.detailTextLabel?.text = debugCellItem.detail
        cell.accessibilityIdentifier = debugCellItem.title
        switch debugCellItem.type {
        case .back:
            cell.textLabel?.textColor = UIColor.ud.colorfulRed
        case let .switchButton(isOn, tag):
            cell.accessoryView = {
                let switchButton = UISwitch()
                switchButton.isOn = isOn
                switchButton.tag = tag
                switchButton.accessibilityIdentifier = String("switch_\(debugCellItem.title)")
                switchButton.addTarget(self, action: #selector(didClickSwitchButton(sender:)), for: .valueChanged)
                return switchButton
            }()
            cell.selectionStyle = .none
        default:
            break
        }
    }
    // MARK: 数据源
    open func configDebugDataSource() {}
    // MARK: Switch Action
    @objc
    open func didClickSwitchButton(sender: UISwitch) {}

    open func cellItemFor(_ indexPath: IndexPath) -> DocsDebugCellItem {
        return self.debugDataSouce[indexPath.section].1[indexPath.row]
    }

    public func getAppVersion() -> String {
        return (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "unknown"
    }
}

extension DocsDebugBaseViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return debugDataSouce.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return debugDataSouce[section].1.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let debugCellItem = debugDataSouce[indexPath.section].1[indexPath.row]
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: cellID)
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: cellID)
        }
        // 清空 cell 的样式，不想写个方法就这样包起来
        {
            cell.textLabel?.textColor = UIColor.ud.N1000
            cell.accessoryView = nil
            cell.selectionStyle = .none
        }()
        config(cell, with: debugCellItem)

        return cell
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return debugDataSouce[section].0
    }
}

extension DocsDebugBaseViewController: UITableViewDelegate {
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}

// MARK: 点击事件处理
extension DocsDebugBaseViewController {
    public func didSelectUserInfo(indexPath: IndexPath) {
        //debug下使用，用默认的defaultConfig管控
        SCPasteboard.general(SCPasteboard.defaultConfig()).string = debugDataSouce[indexPath.section].1[indexPath.row].detail
        UDToast.showSuccess(with: "复制成功", on: self.view.window ?? self.view)
    }

    @objc
    public func didSelectBack() {
        if self === self.navigationController?.viewControllers.first {
            self.dismiss(animated: false, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    public func removeFullPkgFiles() {
        let success = GeckoPackageManager.shared.removeFullPkgOnDisk()
        let msg = success ? "【完整包】移除成功，请重启App" : "移除失败，详情见日志"
        UDToast.showSuccess(with: msg, on: self.view.window ?? self.view)
    }

    public func removeGrayscalePkgFiles() {
        let success = GeckoPackageManager.shared.removeGrayscalePkgOnDisk()
        let msg = success ? "【灰度包】移除成功，请重启App" : "移除失败，详情见日志"
        UDToast.showSuccess(with: msg, on: self.view.window ?? self.view)
    }

    public func showSpecialPkgInfo() {
        showPkgInfo(pkgName: "指定包", content: DocsSDK.getSpecialPkgInfo())
    }

    public func showGrayscalePkgInfo() {
        showPkgInfo(pkgName: "mina灰度包", content: DocsSDK.getGrayscalePkgInfo())
    }

    public func showGeckoPkgInfo() {
        showPkgInfo(pkgName: "热更包", content: DocsSDK.getGeckoPkgInfo())
    }

    private func showPkgInfo(pkgName: String, content: String) {
        let dialog = UDDialog()
        dialog.setTitle(text: pkgName)
        dialog.setContent(text: content)
        dialog.addPrimaryButton(text: "关闭", dismissCheck: { () -> Bool in
            return true
        })
        Navigator.shared.present(dialog, from: self)
    }
}

extension DocsDebugBaseViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
#if BETA || ALPHA || DEBUG
class DocsDebugDocsTypePickerController: UITableViewController {

    weak private var autoOpenDocsMgr: DocsAutoOpenDocsManager!

    init(autoOpenDocsManager: DocsAutoOpenDocsManager) {
        super.init(nibName: nil, bundle: nil)
        autoOpenDocsMgr = autoOpenDocsManager
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(DocsAutoOpenDocsManager.self))
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autoOpenDocsMgr.obtainAutoOpenDocsTypes().count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DocsAutoOpenDocsManager.self), for: indexPath)
        let item = autoOpenDocsMgr.obtainAutoOpenDocsTypes()[indexPath.row]
        cell.textLabel?.text = item.docsType.name
        cell.accessoryType = item.isSelect ? .checkmark : .none
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        autoOpenDocsMgr.updateAutoOpenDocsTyep(indexPath.row)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
#endif
