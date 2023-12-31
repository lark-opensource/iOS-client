//
//  MineViewController.swift
//  ByteViewDemo
//
//  Created by kiri on 2021/3/10.
//

import UIKit
import LarkAccountInterface
import RxSwift
import UniverseDesignColor
import SuiteAppConfig
import RoundedHUD
import LarkFeatureGating
import UniverseDesignTheme

class MineViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private var account: Account?
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let tenantLabel = UILabel()
    private let tableView = UITableView()

    private var isLightMode: Bool = true

    private var items: [MineItem] = []

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

        self.items = [
            .init(title: "获取最新飞书内测配置", action: { [weak self] (sender) in
                self?.pullConfig(sender)
            })
        ]

        if #available(iOS 13.0, *) {
            UDThemeManager.setUserInterfaceStyle(.unspecified)
            let item = MineItem(title: "切换深浅外观") { _ in
                if let mode = UIApplication.shared.keyWindow?.traitCollection.userInterfaceStyle {
                    UDThemeManager.setUserInterfaceStyle(mode == .light ? .dark : .light)
                }
            }
            self.items.append(item)
        }

        let item = MineItem(title: "退出登录") { [weak self] (sender) in
            self?.logout(sender)
        }
        self.items.append(item)

        tableView.separatorStyle = .none
        tableView.register(BaseTableViewCell.self, forCellReuseIdentifier: "Cell")
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
        avatarImageView.setAvatar(key: account.avatarKey, url: URL(string: account.avatarUrl))
        nameLabel.text = account.name
        tenantLabel.text = account.tenantInfo.tenantName
    }

    private func pullConfig(_ sender: UIView?) {
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
        let hud = RoundedHUD.showLoading(on: window, disableUserInteraction: true)
        AccountServiceAdapter.shared.relogin(conf: .default, onError: { (message) in
            hud.remove()
            RoundedHUD.showTips(with: message, on: window)
        }, onSuccess: {
            hud.remove()
        }, onInterrupt: {
            hud.remove()
        })
    }

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

class BaseTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectedBackgroundView = UIView()
        self.selectedBackgroundView?.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIImageView {

    private var avatarBackgroundColor: UIColor? {
        return UIColor.ud.N100
    }

    public func setAvatar(key: String?, url: URL?, preventCompression: Bool = true) {
        let color = avatarBackgroundColor
        backgroundColor = color
        image = nil

        if preventCompression {
            contentMode = .scaleAspectFill
            clipsToBounds = true
        }

        let completion: (UIImage?) -> Void = { [weak self] image in
            if image != nil {
                self?.backgroundColor = .clear
            } else {
                self?.backgroundColor = color
            }
        }
        kf.setImage(with: url, placeholder: nil, completionHandler: { result in
            switch result {
            case .failure:
                completion(nil)
            case .success(let imageResult):
                completion(imageResult.image)
            }

        })
    }
}
