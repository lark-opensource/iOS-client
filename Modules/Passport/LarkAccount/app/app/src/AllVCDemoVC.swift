//
//  AllVCDemoVC.swift
//  SuiteLoginDev
//
//  Created by quyiming on 2019/8/1.
//

import SnapKit
import LarkUIKit
import LarkLocalizations
import RoundedHUD
import LarkActionSheet
import LarkAccount
import LarkAccountInterface

// swiftlint:disable force_unwrapping
class AllVCDemoVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    lazy var tableView: UITableView = {
        let tb = UITableView(frame: .zero, style: .plain)
        tb.delegate = self
        tb.dataSource = self
        tb.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        return tb
    }()

    lazy var datasource: [(String, () -> Void)] = {

        return [
            // MARK: ========================= V3 ===================================
            ("V3 Manage Password", {
                DebugFactory.shared.updatePassword(fromNavigation: self.navigationController!)
            }),
            ("V3 Team Conversion", {
                DebugFactory.shared.pushToTeamConversion(fromNavigation: self.navigationController!)
            }),
            ("Mobile Code Select", {
                let vc = MobileCodeSelectViewController(
                    mobileCodeLocale: LanguageManager.currentLanguage,
                    topCountryList: [],
                    blackCountryList: [],
                    confirmBlock: { (_) in
                    self.navigationController?.dismiss(animated: true)
                })
                let navi = LkNavigationController(rootViewController: vc)
                self.navigationController?.present(navi, animated: true, completion: nil)
            }),
            ("Account Management", {
                let vc = DebugFactory.shared.credentialList()
                if Display.pad {
                    let nav = UINavigationController(rootViewController: vc)
                    nav.isNavigationBarHidden = true
                    self.customPresent(nav)
                } else {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }),
            ("Auth", {
                let vc = DebugFactory.shared.authViewController()
                vc.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                self.navigationController?.present(vc, animated: true, completion: nil)
            }),
            // MARK: ========================= 安全验证密码 ===================================
            ("Security Modify Password", {
                let vc = DebugFactory.shared.securityModifyPwdVC()
                self.navigationController?.pushViewController(vc, animated: true)
            }),
            ("Security Set Password", {
                let vc = LkNavigationController(rootViewController: DebugFactory.shared.securitySetPwdVC())
                vc.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                self.present(vc, animated: true, completion: nil)
            }),
            ("Security View", {
                DebugFactory.shared.attachSecurityVC(isOpen: true, appID: "1000")
            }),
            // MARK: ========================= 注销 ===================================
            ("Unregister View", {
                DebugFactory.shared.unregisterVC(from: self.navigationController!)
            }),
            ("Base ViewController", {
                let vc = DebugFactory.shared.baseVC(title: "注册账号", detail: "这是一个测试这是一个测试这是一个测试这是一个测试这是一个测试这是一个测试")
                let navi = LkNavigationController(rootViewController: vc)
                self.navigationController?.present(navi, animated: true, completion: nil)
            }),
            ("Init Personal Info", {
                let vc = DebugFactory.shared.initPersonal()
                self.navigationController?.pushViewController(vc, animated: true)
            }),
            ("Switch User", {
                DebugFactory.shared.switchUser(presentingViewController: self)
            }),
            ("Recover Account", {
                let vc = DebugFactory.shared.recoverAccountCarrier()
                self.navigationController?.pushViewController(vc, animated: true)
            }),
            ("One Click Login", {
                if let vc = DebugFactory.shared.oneKeyLogin(isRegister: false) {
                    if UIDevice.current.userInterfaceIdiom != .pad {
                        vc.modalPresentationStyle = .overFullScreen
                    }
                    self.navigationController?.present(vc, animated: true, completion: nil)
                } else {
                    RoundedHUD.showTips(with: "Not enabled", on: self.view)
                }
            }),
            ("Create Team", {
                self.navigationController?.pushViewController(DebugFactory.shared.createTeam(), animated: true)
            }),
            ("SimplifyLogin", {
                let vc = DebugFactory.shared.simplifyLogin()
                let navi = LkNavigationController(rootViewController: vc)
                self.navigationController?.present(navi, animated: true, completion: nil)
            }),
            ("MagicLink", {
                let vc = DebugFactory.shared.magicLink()
                self.navigationController?.pushViewController(vc, animated: true)
            }),
            ("TenantCodeJoin", {
                let vc = DebugFactory.shared.joinTenantCode()
                self.navigationController?.pushViewController(vc, animated: true)
            }),
            ("Turing", {
                DebugFactory.shared.turing()
            }),
            ("Set Name", {
                let vc = DebugFactory.shared.setNameVC()
                self.navigationController?.pushViewController(vc, animated: true)
            }),
            ("Pending Approve", {
                let vc = DebugFactory.shared.pendingApprove()
                self.navigationController?.pushViewController(vc, animated: true)
            }),
            ("Choose Or Create", {
                let vc = DebugFactory.shared.chooseOrCreate()
                self.navigationController?.pushViewController(vc, animated: true)
            }),
            ("Official Email", {
                let vc = DebugFactory.shared.officialEmail()
                self.navigationController?.pushViewController(vc, animated: true)
            }),
            ("OAuth Code", {
                let hud = RoundedHUD.showLoading(on: self.view)
                AccountServiceAdapter.shared
                    .getAuthorizationCode(
                        req: AuthCodeReq(
                            appId: "lkwi8z26zvibshfsjb",
                            redirectUri: "lkwi8z26zvibshfsjb://oauth",
                            packageId: "com.bytedance.lark.LarkAccountDev",
                            scope: "scope_a scope_b"
                        )
                    ) { (result) in
                        hud.remove()
                        switch result {
                        case .success(let resp):
                            self.alert(content: "Success: \(resp.code)")
                        case .failure(let error):
                            self.alert(content: "Failure: \(error)")
                        }
                }
            })
        ]
    }()

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.view.addSubview(self.tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        let configItem = UIBarButtonItem(title: "Debug Config", style: .plain, target: self, action: #selector(changeDebugConfig))
        self.navigationItem.setRightBarButton(configItem, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)
        cell.textLabel?.text = self.datasource[indexPath.row].0
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.datasource[indexPath.row].1()
    }

    func alert(content: String) {
        let alert = UIAlertController(title: content, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @objc
    func changeDebugConfig(_ sender: UIBarButtonItem) {
        let sheet = ActionSheet(title: sender.title ?? "")
        configs.forEach { (title, items) in
            sheet.addItem(title: title) {
                let subSheet = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
                items.forEach { (item) in
                    subSheet.addAction(UIAlertAction(title: item.name, style: .default, handler: { (_) in
                        item.action()
                    }))
                }
                subSheet.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (_) in
                    subSheet.dismiss(animated: true, completion: nil)
                }))
                if UIDevice.current.userInterfaceIdiom == .pad {
                    subSheet.popoverPresentationController?.sourceView = self.navigationController?.navigationBar
                    subSheet.popoverPresentationController?.sourceRect = self.navigationController?.navigationBar.bounds ?? .zero
                }
                self.present(subSheet, animated: true, completion: nil)
            }
        }
        sheet.addCancelItem(title: "Cancel")
        self.present(sheet, animated: true, completion: nil)
    }
}

// MARK: - debug config
extension AllVCDemoVC {
    var configs: [(title: String, items: [ConfigItem])] {
        return [
            ("Language-\(LanguageManager.currentLanguage.displayName)", selectLanguageItems)
        ]
    }

    var selectLanguageItems: [ConfigItem] {
        var items: [ConfigItem] = []
        LanguageManager.supportLanguages.forEach { (locale) in
            items.append(
                ConfigItem(name: locale.displayName, action: {
                    LanguageManager.setCurrent(language: locale, isSystem: false)
                    RoundedHUD.showSuccess(with: locale.displayName, on: self.view)
                })
            )
        }
        return items
    }

    struct ConfigItem {
        let name: String
        let action: () -> Void
    }
}

extension UIViewController {
    func customPresent(_ vc: UIViewController, modelStyle: UIModalPresentationStyle? = nil, popOverSourceView: UIView? = nil, animated: Bool = true, completion: @escaping () -> Void = {}) {
        if let modelStyle = modelStyle {
            vc.modalPresentationStyle = modelStyle
        } else {
            if Display.pad {
                if let sourceView = popOverSourceView {
                    vc.modalPresentationStyle = .popover
                    vc.popoverPresentationController?.sourceView = sourceView
                    vc.popoverPresentationController?.sourceRect = sourceView.bounds
                }
            } else {
                vc.modalPresentationStyle = .fullScreen
            }
        }
        present(vc, animated: animated, completion: completion)
    }
}
