//
//  DemoAssembly.swift
//  SpaceDemo
//
//  Created by 曾浩泓 on 2022/3/31.
//  Copyright © 2022 Bytedance. All rights reserved.

import UIKit
import LarkTab
import SKUIKit
import SKCommon
import Swinject
import LarkUIKit
import LarkNavigation
import EENavigator
import AnimatedTabBar
import LarkLocalizations
import LarkAlertController
import UniverseDesignTheme
import UniverseDesignToast
import UniverseDesignColor
import LarkAccountInterface
import UniverseDesignActionPanel
import LarkAssembler
import BootManager
import LarkContainer
import Lynx
import SKDrive

final class DemoRegistTask: FlowBootTask, Identifiable {
    static var identify = "SpaceDemoRegisterTask"

    override var runOnlyOnce: Bool { return true }
    override var scheduler: Scheduler { return .main }

    override func execute(_ context: BootContext) {
        #if canImport(MessengerMod)
        #else
        SideBarVCRegistry.registerSideBarVC { _, hostVC in
            let vc = DemoSettingViewController(style: .grouped)
            vc.hostVC = hostVC
            return vc
        }
        #endif

        #if canImport(CJPay)
        #else
        _ = LynxEnvManager.registerRouter()
        LynxEnv.sharedInstance().devtoolEnabled = true
        LynxEnv.sharedInstance().redBoxEnabled = true
        #endif
                
        DriveModule().unzipPreviewResourcesIfNeeded() // 为了单元测试正常跑，需要解压drive预览资源
    }
}

class DemoSettingViewController: UITableViewController, SideBarAbility {
    weak var hostVC: UIViewController?
    
    private var dataSource: [[SettingItem]] = {
        var utilSection: [SettingItem] = [
            .language,
            .qrScan
        ]
        if #available(iOS 13, *) {
            utilSection.append(.themeSwitch)
        }
        let accountSection: [SettingItem] = [.logOut]
        return [utilSection, accountSection]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }
}

enum SettingItem: String {
    case themeSwitch = "外观切换"
    case language = "语言设置"
    case qrScan = "扫一扫"
    case logOut = "退出登录"
}
extension DemoSettingViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.section][indexPath.row].rawValue
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let item = dataSource[indexPath.section][indexPath.item]
        switch item {
        case .themeSwitch:
            if #available(iOS 13.0, *) {
                showThemeSetting(cell: cell)
            }
        case .language:
            hideSideBar(animate: true) { [weak self] in
                self?.switchLanguage()
            }
        case .qrScan:
            hideSideBar(animate: true) { [weak self] in
                self?.showQRScan()
            }
        case .logOut:
            logOut(cell: cell)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    private func udPopSource(with sourceView: UIView?) -> UDActionSheetSource? {
        guard Display.pad, let sourceView = sourceView else { return nil }
        return UDActionSheetSource(
            sourceView: sourceView,
            sourceRect: sourceView.bounds,
            arrowDirection: .any
        )
    }
}

extension DemoSettingViewController {
    @available(iOS 13.0, *)
    func showThemeSetting(cell: UITableViewCell?) {
        let actionSheet = UDActionSheet.actionSheet(title: "切换外观", popSource: udPopSource(with: cell))
        self.addItem(for: actionSheet, style: .unspecified, text: "跟随系统")
        self.addItem(for: actionSheet, style: .light, text: "浅色")
        self.addItem(for: actionSheet, style: .dark, text: "深色")
        self.present(actionSheet, animated: true)
    }
    @available(iOS 13.0, *)
    func addItem(for actionSheet: UDActionSheet, style: UIUserInterfaceStyle, text: String) {
        let isSelected = UDThemeManager.userInterfaceStyle == style
        let str = isSelected ? text + "  ✅" : text
        actionSheet.addItem(text: str) {
            UDThemeManager.setUserInterfaceStyle(style)
        }
    }
}

extension DemoSettingViewController {
    func showQRScan() {
        guard let hostVC = hostVC else { return }
        let url = URL(string: "https://applink.feishu.cn/client/qrcode/main")!
        Navigator.shared.open(url, from: hostVC)
    }
}

extension DemoSettingViewController {
    func logOut(cell: UITableViewCell?) {
        let actionSheet = UDActionSheet.actionSheet(popSource: udPopSource(with: cell))
        actionSheet.addItem(text: "退出登录所有帐号") { [weak self] in
            guard let self = self else { return }
            let hud = UDToast.showLoading(with: "", on: self.view)
            AccountServiceAdapter.shared.relogin(conf: .default) { [weak self] message in
                hud.remove()
                if let view = self?.view {
                    UDToast.showFailure(with: message, on: view)
                }
            } onSuccess: {
                hud.remove()
            } onInterrupt: { [weak self] in
                hud.remove()
                if let view = self?.view {
                    UDToast.showFailure(with: "无法退出登录，请重试", on: view)
                }
            }
        }
        actionSheet.addItem(text: "取消", style: .cancel)
        self.present(actionSheet, animated: true)
    }
}

extension DemoSettingViewController {
    func switchLanguage() {
        guard let hostVC = hostVC else { return }
        let vc = SelectLanguageController() { (model, from) in
            let alertController = LarkAlertController()
            alertController.setContent(text: "需要重启")
            alertController.addCancelButton()
            alertController.addPrimaryButton(text: "重启", dismissCompletion: {
                LanguageManager.setCurrent(language: model.language, isSystem: model.isSystem)
                DispatchQueue.main.async {
                    exit(0)
                }
            })
            Navigator.shared.present(alertController, from: from)
        }
        let nav = LkNavigationController(rootViewController: vc)
        Navigator.shared.present(nav, from: hostVC)
    }
}
