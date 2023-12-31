//
//  MineViewController.swift
//  MailDemo
//
//  Created by haojin on 2021/4/23.
//

import UIKit
import LarkAccountInterface
import RxSwift
import SuiteAppConfig
import RoundedHUD
import LarkFeatureGating
import Swinject
import LKCommonsLogging
import LarkMessengerInterface
import EENavigator
import LarkUIKit
import LarkLocalizations
import LarkAlertController
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignTheme
import UniverseDesignColor
import LarkNavigation
#if LARKCONTACT
import LarkMessengerInterface
import LarkContact
#endif

extension MineViewController: SideBarAbility {}

class MineViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private var account: Account?
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let tenantLabel = UILabel()
    private let tableView = UITableView()
    private let resolver: Resolver
    /// 当前缓存的大小
    private var currCacheSize: Float = 0
    /// 当前是否正在清除缓存
    private var currIsClearLoading: Bool = false
    /// 当前是否正在获取 size
    private var currIsSizeGetting: Bool = false
    private lazy var userSpaceService: UserCacheService = resolver.resolve(UserCacheService.self)!

    private var items: [MineItem] = []

    init(resolver: Resolver) {
        self.resolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        avatarImageView.layer.cornerRadius = 35
        view.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { (maker) in
            maker.leading.top.equalTo(view.safeAreaLayoutGuide).inset(15)
            maker.width.height.equalTo(70)
        }

        nameLabel.font = .boldSystemFont(ofSize: 22)
        nameLabel.textColor = UIColor.ud.N900
        view.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (maker) in
            maker.leading.equalTo(avatarImageView)
            maker.trailing.lessThanOrEqualToSuperview().inset(15)
            maker.top.equalTo(avatarImageView.snp.bottom).offset(12)
        }

        tenantLabel.font = .systemFont(ofSize: 12)
        tenantLabel.textColor = UIColor.ud.N500
        view.addSubview(tenantLabel)
        tenantLabel.snp.makeConstraints { (maker) in
            maker.leading.equalTo(avatarImageView)
            maker.trailing.lessThanOrEqualToSuperview().inset(15)
            maker.top.equalTo(nameLabel.snp.bottom).offset(8)
        }

        AccountServiceAdapter.shared.currentAccountObservable.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] account in
                self?.updateAccount(account)
            }).disposed(by: disposeBag)

        var allItems: [MineItem] = [
            .init(title: "退出登录", action: { [weak self] (sender) in
                self?.logout(sender)
            }),
            .init(title: "清除缓存", action: { [weak self] (sender) in
                self?.clearCache()
            }),
            .init(title: "显示语言", action: { [weak self] (sender) in
                self?.changeLanguage()
            })
        ]

        #if LARKCONTACT
        allItems.append(.init(title: "打开邮箱联系人", action: { [weak self] (sender) in
            self?.enterContact()
        }))
        #endif

        self.items = allItems
        if #available(iOS 13.0, *) {
            self.items.append(.init(title: "切换DarkMode", action: { [weak self] (sender) in
                self?.changeMode()
            }))
        } else {
            self.items.append(.init(title: "13以下没DarkMode", action: { (sender) in
            }))
        }

        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
            maker.top.equalTo(tenantLabel.snp.bottom).offset(20)
        }
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func updateAccount(_ account: Account) {
        self.account = account
        loadAvatarWithUrl(urlString: account.avatarUrl)
        nameLabel.text = account.name
        tenantLabel.text = account.tenantInfo.tenantName
    }

    private func loadAvatarWithUrl(urlString: String) {
        DispatchQueue.global().async { [weak self] in
            if let url = URL(string: urlString),
               let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.avatarImageView.image = image
                }
            }
        }
    }

    private func logout(_ sender: UIView?) {
        let actionSheet = UIAlertController(title: "确定要退出登录吗？", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "退出登录", style: .destructive, handler: { [weak self] (_) in
            self?.doLogout()
        }))
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        if let popover = actionSheet.popoverPresentationController, let anchor = sender {
            popover.sourceView = anchor
            popover.sourceRect = anchor.bounds
        }
        present(actionSheet, animated: true, completion: nil)
    }

    private func doLogout() {
        guard let window = view.window else {
            return
        }
        let hud = UDToast.showLoading(with: "", on: window, disableUserInteraction: true)
        AccountServiceAdapter.shared.relogin(conf: .default, onError: { (message) in
            hud.remove()
            UDToast.showTips(with: message, on: window)
        }, onSuccess: {
            UDToast.removeToast(on: window)
        }, onInterrupt: {
            UDToast.removeToast(on: window)
        })
    }

    /// 清除缓存
    private func clearCache() {
        let alert = UIAlertController(title: "本地缓存的图片、视频等内容将被清理，但云端仍保留原始文件，可随时重新加载", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { [weak self] (_) in
            guard let self = `self` else { return }
            self.currIsClearLoading = true
            /// 清除太快会闪一下，所以这里加一个时间，最少0.5s才刷新表格视图
            let beginTime: TimeInterval = NSDate().timeIntervalSince1970
            self.userSpaceService
                .clearCache()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (cacheSize) in
                    guard let `self` = self else { return }
                    let endTime: TimeInterval = NSDate().timeIntervalSince1970
                    if endTime - beginTime >= 0.5 {
                        self.currIsClearLoading = false
                        self.currIsSizeGetting = false
                        self.currCacheSize = cacheSize
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + (0.5 - (endTime - beginTime)), execute: {
                            self.currIsClearLoading = false
                            self.currIsSizeGetting = false
                            self.currCacheSize = cacheSize
                        })
                    }
                }, onCompleted: {
                    // 3.15临时方案：发送通知告知其他业务清理缓存
                    let notificationName = "LarkCacheDidClear"
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationName), object: nil)
                    if let window = self.view.window {
                        UDToast.showTips(with: "清理成功", on: window)
                    }
                }).disposed(by: self.disposeBag)
        }))

        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    ///显示语言
    private func changeLanguage() {
        let vc = SelectLanguageController(title: "显示语言") { (model, from) in
            let message = "将飞书语言切换到\(model.name)"
            let alertController = LarkAlertController()
            alertController.setContent(text: message)
            alertController.addCancelButton()
            alertController.addPrimaryButton(text: "确认", dismissCompletion: { [weak self] in
                guard let self = self else { return }
                let language = model.language.localeIdentifier
                let configurationAPI = self.resolver.resolve(ConfigurationAPI.self)!
                var hud: UniverseDesignToast.UDToast?
                if let window = from.view.window {
                    hud = UDToast.showLoading(with: "", on: window, disableUserInteraction: true)
                }
                /// 上传语言 + 触发 sdk 拉取系统消息模板
                configurationAPI.updateDeviceSetting(language: language)
                    .flatMap({ (_) -> Observable<Void> in
                        return configurationAPI.getSystemMessageTemplate(language: language)
                    }).catchError({ (error) -> Observable<()> in
                        print(
                            "update message error\(error)"
                        )

                        DispatchQueue.main.async {
                            if let window = from.view.window {
                                hud?.showFailure(with:"upload失败",
                                                 on: window,
                                                 error: error)
                            }
                        }
                        return Observable.empty()
                    }).subscribe(onNext: { (_) in
                        LanguageManager.setCurrent(language: model.language, isSystem: model.isSystem)
                        /// 主线程执行UI操作
                        DispatchQueue.main.async {
                            hud?.remove()
                            exit(0)
                        }
                    }, onError: { (error) in
                        print("err \(error)")
                    }).disposed(by: self.disposeBag)
            })
            Navigator.shared.present(alertController, from: from)
        }
        let nav = UINavigationController.init(rootViewController: vc)
        Navigator.shared.present(nav, from: self)
    }

    ///切换模式
    @available(iOS 13, *)
    private func changeMode() {
        if #available(iOS 13.0, *) {
            let alert = UIAlertController(title: "外观", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "跟随系统", style: .destructive, handler: { (_) in
                UDThemeManager.setUserInterfaceStyle(.unspecified)
            }))
            alert.addAction(UIAlertAction(title: "浅色", style: .destructive, handler: { (_) in
                UDThemeManager.setUserInterfaceStyle(.light)
            }))
            alert.addAction(UIAlertAction(title: "深色", style: .destructive, handler: { (_) in
                UDThemeManager.setUserInterfaceStyle(.dark)
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            if let popoverController = alert.popoverPresentationController {
              popoverController.sourceView = self.view
              popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            present(alert, animated: true, completion: nil)
        }
    }

    #if LARKCONTACT
    private func enterContact() {
        hideSideBar(animate: true) {
            DemoEventBus.shared.fireRouterEvent(event: .namecard)
        }
    }
    #endif

    struct MineItem {
        let title: String
        let action: ((UIView?) -> Void)?
        init(title: String, action: ((UIView?) -> Void)? = nil) {
            self.title = title
            self.action = action
        }
    }
}

extension MineViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = item.title
        cell.textLabel?.font = .systemFont(ofSize: 15)
        cell.textLabel?.textColor = UIColor.ud.N900
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        items[indexPath.row].action?(tableView.cellForRow(at: indexPath))
    }
}
