//
//  FakeViewController.swift
//  LarkTodo
//
//  Created by wangwanxin on 2021/5/11.
//

import Foundation
import AnimatedTabBar
import LarkUIKit
import LarkTab
import RxCocoa
import EENavigator
import LarkDebug
import UniverseDesignTheme
import TodoInterface
import LarkAppLinkSDK
import LarkContainer
@testable import Todo

final class FakeTab: TabRepresentable {
    static var tab: Tab {
        #if canImport(MessengerMod)
        return Tab.calendar
        #else
        return Tab.feed
        #endif
    }
    var tab: Tab { Self.tab }
}

final class FakeViewController: UITableViewController, TabRootViewController, LarkNaviBarDataSource, LarkNaviBarDelegate, UserResolverWrapper {

    var userResolver: LarkContainer.UserResolver

    var titleText: BehaviorRelay<String> { BehaviorRelay(value: "Todo fake controller") }

    var isNaviBarEnabled: Bool { true }

    var isDrawerEnabled: Bool { true }

    var tab: Tab { FakeTab.tab }

    var controller: UIViewController { self }
    @ScopedInjectedLazy private var appLinkService: AppLinkService?

    private var datasource: [String] = []

    init(resolver: UserResolver) {
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            UDThemeManager.setUserInterfaceStyle(.unspecified)
        }
        datasource = [
            "debugger",
            "ChatTodo",
            "AppLink",
            "PickAssigneesFromDocx",
            "test rank"
        ]
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")

        print("日志存储路径: \(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true))")
    }
}

extension FakeViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)
        cell.textLabel?.text = datasource[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0: // show debugger
            showDebugger()
        case 1: // TODO 测试群: 6940559477934391297 （release）
            // (id=6980899046470713364, entity_type=1) Boe 张威
            // 6937119111923105819 - 三个臭皮匠
            let body = ChatTodoBody(chatId: "6980899046470713364", isFromThread: false)
            userResolver.navigator.present(
                body: body,
                wrap: UINavigationController.self,
                from: self,
                prepare: { $0.modalPresentationStyle = .fullScreen }
            )
        case 2:
            // ref: https://bytedance.feishu.cn/wiki/wikcnEcv9mnmNmM6i2LcCcEbpOe
            enum AuthScene: Int { case message = 1, pano }
            enum NaviStyle: String { case push, present }
            let guid = "3404515315286804"
            let authScene = AuthScene.message
            let naviStyle = NaviStyle.push
            let prefix = "https://applink.feishu.cn/client/todo/view?tab=all"
//            let urlStr = "\(prefix)?guid=\(guid)&navigateStyle=\(naviStyle.rawValue)&authscene=\(authScene.rawValue)"
            if let url = URL(string: prefix) {
                appLinkService?.open(url: url, from: .unknown, fromControler: self) { _ in
                    //
                }
            }
        case 3:
            var body = TodoUserBody()
            let user1 = ["id": "6694421526193635587", "name": "zhangwei"]
            let user2 = ["id": "6935990806239051803", "name": "wangwanxin"]
            let user3: [String : Any] = ["id": "6917811156727889921", "name": "linhongyu", "completedMilliTime": Int64(1648453083)]
            body.param = [TodoUserBody.users: [user1, user2, user3], TodoUserBody.enableMultiAssignee: true]
            userResolver.navigator.present(
                body: body,
                wrap: UINavigationController.self,
                from: self,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        case 4:
            testRank()
        default:
            print("do nothing")
        }
    }

    private func showDebugger() {
        userResolver.navigator.present(
            body: DebugBody(),
            wrap: UINavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .fullScreen }
        )
    }

    private func testRank() {
        assert(Utils.Rank.index(of: "0") == 0)
        assert(Utils.Rank.index(of: "9") == 9)
        assert(Utils.Rank.index(of: "a") == 10)
        assert(Utils.Rank.index(of: "f") == 15)
        assert(Utils.Rank.index(of: "n") == 23)
        assert(Utils.Rank.index(of: "z") == 35)

        assert(Utils.Rank.next(of: "kkkkf") == "kkkkn")
        assert(Utils.Rank.next(of: "kkkkp6") == "kkkkpe")
        assert(Utils.Rank.next(of: "kkkkpz") == "kkkkx1")
        assert(Utils.Rank.next(of: "") == "8")

        assert(Utils.Rank.pre(of: "kkkkn") == "kkkkf")
        assert(Utils.Rank.pre(of: "kkkkpt") == "kkkkpl")
//        assert(Utils.Rank.pre(of: "1") == "iiiiii") // 中断言符合预期

        assert(Utils.Rank.middle(of: "1", and: "z") == "i")
        assert(Utils.Rank.middle(of: "a", and: "a") == "a")
        assert(Utils.Rank.middle(of: "kkkkpt", and: "kkkkpl") == "kkkkpp")
        assert(Utils.Rank.middle(of: "kkkkp7", and: "kkkkp8") == "kkkkp7i")
        assert(Utils.Rank.middle(of: "zzzzzz", and: "zzzzzz1") == "zzzzzz1i")
    }
}
