//
//  MainViewController.swift
//  LarkAccountDev
//
//  Created by Miaoqi Wang on 2020/9/23.
//

import UIKit
import LarkAccountInterface
import Kingfisher
import LarkUIKit
import WebKit
import EENavigator
import LKCommonsLogging

class ListViewController: UIViewController {

    static let logger = Logger.log(ListViewController.self, category: "Demo")
    
    var items: [[Item]] {
        didSet {
            DispatchQueue.main.async {
                self.table.reloadData()
            }
        }
    }

    init(items: [[Item]]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var table: UITableView = {
        let tb = UITableView(frame: .zero, style: .grouped)
        tb.delegate = self
        tb.dataSource = self
        tb.separatorStyle = .none
        tb.lu.register(cellSelf: MainTableViewCell.self)
        tb.estimatedRowHeight = 50
        tb.rowHeight = UITableView.automaticDimension
        return tb
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        title = "Passport Demo"

        view.addSubview(table)
        table.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        setCookie()
    }

    func setCookie() {
        // oauth 接口需要cookie
        let domains = [".feishu.cn", ".feishu-boe.cn"]
        domains.forEach { (domain) in
            let properties: [HTTPCookiePropertyKey: Any] = [
                .name: "session",
                .value: AccountServiceAdapter.shared.currentAccessToken,
                .path: "/",
                .domain: domain
            ]
            if let cookie = HTTPCookie(properties: properties) {
                HTTPCookieStorage.shared.setCookie(cookie)
                DispatchQueue.main.async {
                    WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie, completionHandler: nil)
                }
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {}
}

extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        items[indexPath.section][indexPath.row].action?()
    }
}

extension ListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MainTableViewCell.lu.reuseIdentifier, for: indexPath) as? MainTableViewCell else {
            return UITableViewCell()
        }

        cell.setItem(items[indexPath.section][indexPath.row])
        return cell
    }
}

class MainViewController: ListViewController {

    init() {
        super.init(items: [])

        let userItems: [Item] = [
            Item(title: "用户列表", action: {
                let current = AccountServiceAdapter.shared.currentAccountInfo
                let accounts = [current] + AccountServiceAdapter.shared.accounts.filter({ $0.userID != current.userID })

                let users = accounts.map { act in
                    Item(title: act.name + (current.userID == act.userID ? "(Current)" : ""),
                         subtitle: act.tenantInfo.tenantName,
                         imageUrl: act.avatarUrl,
                         action: {
                            AccountServiceAdapter.shared.switchTo(userID: act.userID)
                         }
                    )
                }
                let vc = ListViewController(items: [users, []])
                Navigator.shared.push(vc, from: self)
            })
        ]

        let featureItems = [
            Item(title: AccountServiceAdapter.shared.accountSecurityCenterEntryTitle()) {
                AccountServiceAdapter.shared.openAccountSecurityCenter(from: self)
            },
            Item(title: "页面测试") {
                Navigator.shared.push(AllVCDemoVC(), from: self)
            },
            Item(title: "组织架构", action: {
                Navigator.shared.push(DepartmentTestListController(), from: self)
            })
        ]

        let otherItems = [
            Item(title: "登出", action: {
                let config = LogoutConf.default
                config.forceLogout = true
                AccountServiceAdapter.shared.relogin(conf: config, onError: { (error) in
                    print("logout error \(error)")
                }, onSuccess: {
                    #if SIMPLE
                    LoginService.shared.relogin()
                    #endif
                }, onInterrupt: {})
            })
        ]

        items = [userItems, featureItems, otherItems]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct Item {
    let title: String
    let subtitle: String?
    let imageUrl: String?
    let action: (() -> Void)?

    init(title: String,
         subtitle: String? = nil,
         imageUrl: String? = nil,
         action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.imageUrl = imageUrl
        self.action = action
    }
}

class MainTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        imageView?.contentMode = .scaleAspectFit
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setItem(_ item: Item) {
        textLabel?.text = item.title
        detailTextLabel?.text = item.subtitle
        if let urlString = item.imageUrl {
            imageView?.lk.setExternalImage(
                key: urlString,
                url: urlString,
                placeholder: image(of: .lightGray, rect: CGRect(x: 0, y: 0, width: 60, height: 60))
            )
        } else {
            imageView?.image = nil
        }
        if item.action == nil {
            accessoryType = .none
        } else {
            accessoryType = .disclosureIndicator
        }
    }

    func image(of color: UIColor, rect: CGRect) -> UIImage? {
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
