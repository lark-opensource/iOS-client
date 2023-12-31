//
//  DemoTenantViewController.swift
//  ByteView_Example
//
//  Created by kiri on 2023/9/1.
//

import Foundation
import ByteViewUI
import LarkContainer
import LarkAccountInterface
import RxSwift
import LarkSetting
import UniverseDesignIcon

final class DemoTenantViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView()
    let userResolver: UserResolver
    private let passportService: PassportService
    private let currentUser: User
    private let fg: FeatureGatingService
    private let disposeBag = DisposeBag()
    private var users: [User] = []

    init?(resolver: UserResolver) {
        guard let service = try? resolver.resolve(assert: PassportService.self),
              let userService = try? resolver.resolve(assert: PassportUserService.self),
              let fg = try? resolver.resolve(assert: FeatureGatingService.self) else { return nil }
        self.userResolver = resolver
        self.passportService = service
        self.currentUser = userService.user
        self.fg = fg
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "切换租户"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        tableView.rowHeight = 68
        tableView.register(DemoUserCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self

        if showAdd {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UDIcon.getIconByKey(.addOutlined), style: .plain, target: self, action: #selector(addAccount(_:)))
        }

        tenantsObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.users = $0
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
    }

    private var showAdd: Bool {
        // 某些 KA 不允许账户同登，此时屏蔽加入团队入口
        let fgValue = fg.staticFeatureGatingValue(with: "lark.tenant.penetration.enable")
        let fgValue1 = fg.staticFeatureGatingValue(with: "suite_join_function")
        return !currentUser.isExcludeLogin && fgValue && fgValue1
    }

    var tenantsObservable: Observable<[User]> {
        if fg.staticFeatureGatingValue(with: "suite_transfer_function") {
            return passportService.menuUserListObservable
        } else {
            return passportService.state.map({ state in
                if let user = state.user {
                    return [user]
                } else {
                    return []
                }
            })
        }
    }

    @objc func addAccount(_ sender: Any?) {
        guard let nav = self.navigationController, let w = self.view.window else { return }
        w.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak w] in
            w?.isUserInteractionEnabled = true
        })
        passportService.pushToTeamConversion(fromNavigation: nav, trackPath: "sidebar_icon")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = self.users[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if let cell = cell as? DemoUserCell {
            cell.avatarView.setImageURL(user.tenant.iconURL, accessToken: currentUser.sessionKey ?? "")
            cell.titleLabel.text = user.tenant.localizedTenantName
            cell.subtitleLabel.text = user.localizedName
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = self.users[indexPath.row]
        if user.userID == currentUser.userID {
            self.doBack()
        } else {
            ByteViewDialog.Builder()
                .title("是否要切换到 \(user.tenant.localizedTenantName)")
                .leftTitle("取消")
                .rightTitle("确定")
                .rightHandler({ [weak self] _ in
                    self?.passportService.switchTo(userID: user.userID)
                    self?.logger.info("Changed to \(user.localizedName), tenant: \(user.tenant.localizedTenantName)")
                })
                .show()
        }
    }
}
