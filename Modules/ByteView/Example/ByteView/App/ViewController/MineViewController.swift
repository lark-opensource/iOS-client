//
//  MineViewController.swift
//  ByteViewDemo
//
//  Created by kiri on 2021/3/10.
//

import UIKit
import LarkContainer
import LarkAccountInterface
import RxSwift
import LarkSetting
import UniverseDesignTheme
import UniverseDesignToast
import UniverseDesignIcon
import ByteViewUI
import ByteViewCommon
import RustPB
import LarkRustClient
import EENavigator
#if canImport(LarkDebug)
import LarkDebug
#endif

typealias GetSettingsRequest = Settings_V1_GetSettingsRequest

class MineViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    private let disposeBag = DisposeBag()
    private var account: LarkAccountInterface.User?
    private lazy var avatarImageView = AvatarView()
    private let nameLabel = UILabel()
    private let tenantLabel = UILabel()
    private let tableView = BaseTableView()
    private var isLightMode: Bool = true
    private var items: [DemoCellRow] = []
    private var rustService: RustService? { try? resolver.resolve(assert: RustService.self) }
    private var passportService: PassportService? { try? resolver.resolve(assert: PassportService.self) }

    let resolver: UserResolver
    init(resolver: UserResolver) {
        self.resolver = resolver
        super.init(nibName: nil, bundle: nil)
        self.title = "我的"
        self.tabBarItem = UITabBarItem(title: self.title, image: UDIcon.getIconByKey(.tabAppFilled), tag: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = false
        view.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.left.top.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.width.height.equalTo(70)
        }

        nameLabel.font = .boldSystemFont(ofSize: 22)
        nameLabel.textColor = UIColor.ud.textTitle
        view.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.right.lessThanOrEqualToSuperview().inset(16)
            make.bottom.equalTo(avatarImageView.snp.centerY)
        }

        tenantLabel.font = .systemFont(ofSize: 14)
        tenantLabel.textColor = UIColor.ud.textPlaceholder
        view.addSubview(tenantLabel)
        tenantLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.lessThanOrEqualToSuperview().inset(16)
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
        }

        tableView.rowHeight = 48
        tableView.separatorColor = .ud.commonTableSeparatorColor
        tableView.register(DemoTableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
            make.top.equalTo(avatarImageView.snp.bottom).offset(20)
        }
        tableView.delegate = self
        tableView.dataSource = self

        passportService?.state.compactMap { [weak self] _ in
            self?.passportService?.foregroundUser
        }.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] user in
            self?.updateAccount(user)
        }).disposed(by: disposeBag)

        self.items = [
            .init(title: "用户设置", action: { [weak self] in
                guard let self = self, let vc = DemoSettingViewController(resolver: self.resolver) else { return }
                self.demoPushOrPresent(vc)
            }),
            .init(title: "切换租户", action: { [weak self] in
                guard let self = self, let vc = DemoTenantViewController(resolver: self.resolver) else { return }
                self.navigationController?.pushViewController(vc, animated: true)
            }),
            .init(title: "获取最新飞书内测配置", action: { [weak self] in
                self?.pullConfig()
            })
        ]

        if #available(iOS 13.0, *) {
            self.items.append(contentsOf: [
                .init(title: "切换深浅外观", action: { [weak self] in
                    if let mode = self?.traitCollection.userInterfaceStyle {
                        UDThemeManager.setUserInterfaceStyle(mode == .light ? .dark : .light)
                    }
                }),
                .init(title: "跟随系统外观", action: {
                    UDThemeManager.setUserInterfaceStyle(.unspecified)
                })
            ])
        }

        #if canImport(LarkDebug)
        self.items.append(.init(title: "高级调试", action: { [weak self] in
            guard let self = self else { return }
            self.demoPresent(body: DebugBody(), navigator: self.resolver.navigator)
        }))
        #endif
        self.items.append(.init(title: "退出登录", action: { [weak self] in
            guard let self = self else { return }
            let actionSheet = UIAlertController(title: "确定要退出登录吗？", message: nil, preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "退出登录", style: .destructive, handler: { [weak self] (_) in
                self?.logout()
            }))
            actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            self.present(actionSheet, animated: true, completion: nil)
        }))

        self.tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 13, *) {
            self.navigationController?.navigationBar.standardAppearance.configureWithDefaultBackground()
            self.navigationController?.navigationBar.scrollEdgeAppearance?.configureWithDefaultBackground()
        }
    }
    
    private func updateAccount(_ user: LarkAccountInterface.User) {
        self.account = user
        avatarImageView.setAvatarInfo(.remote(key: user.avatarKey, entityId: user.userID), size: .medium)
        nameLabel.text = user.localizedName
        tenantLabel.text = user.tenant.tenantName
    }

    private func pullConfig() {
        let hud = UDToast.showLoading(with: "", on: self.view, disableUserInteraction: true)
        fetchFeatureGating()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                hud.remove()
                guard let self = self else {
                    return
                }

                let alert = UIAlertController(title: "飞书内测配置已更新", message: "新配置在重启应用后生效", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "稍后", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "重启", style: .default, handler: { (_) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                        exit(0)
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            }, onError: { [weak self] (error) in
                hud.remove()
                Logger.ui.error("SyncConfig error", error: error)
                if let self = self {
                    UDToast.showFailure(with: "配置更新失败: \(error)", on: self.view)
                }
            }, onDisposed: { hud.remove() }).disposed(by: disposeBag)
    }

    private func fetchFeatureGating() -> Observable<Void> {
        var request = GetSettingsRequest()
        request.fields = ["lark_features"]
        request.syncDataStrategy = .forceServer
        return self.rustService?.sendAsyncRequest(request).map({ _ in }) ?? .empty()
    }

    private func logout() {
        guard let window = view.window else { return }
        let hud = UDToast.showLoading(with: "", on: window, disableUserInteraction: true)
        passportService?.logout(conf: .default, onInterrupt: {
            hud.remove()
        }, onError: { message in
            hud.remove()
            UDToast.showTips(with: message, on: window)
        }, onSuccess: { _, _ in
            hud.remove()
        }, onSwitch: { _ in
            hud.remove()
        })
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if let cell = cell as? DemoTableViewCell {
            cell.updateItem(item)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        items[indexPath.row].action()
    }
}
