//
//  HomeVC.swift
//  CalendarDemo
//
//  Created by linlin on 2017/12/19.
//  Copyright © 2017年 EE. All rights reserved.
//

import UIKit
@testable import Calendar
import LarkContainer
import LarkUIKit
import LarkRustClient
import AnimatedTabBar
import EENavigator
import LarkTab
import RxSwift
import LarkDebug
import FLEX
import SnapKit
import RustPB
import UniverseDesignTheme
import FLEX
import UniverseDesignColorPicker

extension UIModalPresentationStyle: CaseIterable, CustomStringConvertible {
    public static var allCases: [UIModalPresentationStyle] {
        let styles = [UIModalPresentationStyle.fullScreen,
                      UIModalPresentationStyle.pageSheet,
                      UIModalPresentationStyle.formSheet,
                      UIModalPresentationStyle.popover]
        if #available(iOS 13.0, *) {
            return [.automatic] + styles
        } else {
            return styles
        }
    }

    public var description: String {
        switch self {
        case .automatic:
            return "automatic"
        case .fullScreen:
            return "fullscreen"
        case .pageSheet:
            return "pageSheet"
        case .formSheet:
            return "formSheet"
        case .popover:
            return "popover"
        default:
            return "unknown"
        }
    }
}
final class HomeVC: UITableViewController {


    enum ShowDetailStyle: CaseIterable, CustomStringConvertible {
        static var allCases: [ShowDetailStyle] {
            [.push] + UIModalPresentationStyle.allCases.map { .present($0) }
        }

        case push
        case present(UIModalPresentationStyle)

        var description: String {
            switch self {
            case .push:
                return "push"
            case .present(let style):
                return String(describing: style)
            }
        }
    }

    struct DatasourceItem {
        var title: String
        var targetVC: () -> UIViewController
        var customAction: (() -> Void)?
    }

    var datasource: [DatasourceItem] = []

    var style = ShowDetailStyle.push

    @InjectedLazy var rustClient: RustService
    @InjectedLazy var calendar: CalendarInterface
    @InjectedLazy var calendarAPI: CalendarRustAPI
    let disposeBag = DisposeBag()

    func setupDatasource() {
        setDefaultWorkHourSetting()
        datasource = [
            DatasourceItem(title: "blankController") { () -> UIViewController in
                return BlankController()
            },
            DatasourceItem(title: "ReminderMockController") { () -> UIViewController in
                return ReminderMockController()
            },
            DatasourceItem(title: "消息卡片") { () -> UIViewController in
                return CalendarCardController()
            },
            DatasourceItem(title: "忙闲页面", targetVC: { [weak self] () -> UIViewController in
                guard let self = self else { return UIViewController() }
                /// 6571810623900877060 z文涛 海外
                /// 6389565523687899394 朱朝
                let vc = self.calendar.getOldFreeBusyController(userId: "6389565523687899394", isFromProfile: false)
                if Display.pad {
                    vc.modalPresentationStyle = .formSheet
                }
                return vc
            }),
            DatasourceItem(title: "搜索页面", targetVC: { [weak self] () -> UIViewController in
                guard let self = self else { return UIViewController() }
                return self.calendar.getSearchController(query: nil)
            }),
            DatasourceItem(title: "群忙闲", targetVC: { [weak self] () -> UIViewController in
                guard let self = self else { return UIViewController() }
                //山寨日历群:6570647131789459716 , 6729700326720405763
                let vc = self.calendar
                    .getGroupFreeBusyController(chatId: "6719414547679019277", chatType: "group", createEventBody: nil)
                return vc
            }),
            DatasourceItem(title: "会议室签到", targetVC: { () -> UIViewController in
                let navi = LkNavigationController(rootViewController: MeetingRoomOrderViewController(viewModel: MeetingRoomOrderViewController.ViewModel(token: "8784e310-15da-4105-be9b-fd825c6bfdf5", userResolver: Container.shared.getCurrentUserResolver()), originalURL: URL(string: "https://feishu.cn")!, userResolver: Container.shared.getCurrentUserResolver()))
                navi.modalPresentationStyle = .fullScreen
                return navi
            }),
            DatasourceItem(title: "会议室表单", targetVC: { () -> UIViewController in
                MeetingRoomFormViewController(resourceCustomization: Calendar_V1_SchemaExtraData.ResourceCustomization(), userResolver: Container.shared.getCurrentUserResolver())
            }),
            DatasourceItem(title: "点我切换Dark/Light Mode", targetVC: { UIViewController() }, customAction: {
                if #available(iOS 13.0, *) {
                    let currentTheme = UDThemeManager.userInterfaceStyle
                    if currentTheme == .dark || currentTheme == .unspecified {
                        UDThemeManager.setUserInterfaceStyle(.light)
                    } else {
                        UDThemeManager.setUserInterfaceStyle(.dark)
                    }
                }
            }),
            DatasourceItem(title: "抢占会议室") { () -> UIViewController in
                let vc = self.calendar.getSeizeMeetingroomController(token: "7fb28c72-915e-4641-9154-5f39048aa149")
                return vc
            },
            DatasourceItem(title: "日历详情页shareToken", targetVC: { UIViewController() }, customAction: {
                Navigator.shared.open(URL(string: "https://applink.feishu.cn/client/calendar/detail?shareToken=8HmuRknIGU7COxhlTlJRYX0rBu-Jzp3SdVbmjpqnk3H_P5JgfXFLe7yUfkbH22l6NGljA7zz9w==")!, from: self)
            }),
            DatasourceItem(title: "新版demo") { () -> UIViewController in
                let vc = DemoVC()
//                let nav = LkNavigationController(rootViewController: vc)
                return vc
            },
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        signal(SIGPIPE, SIG_IGN) // 防止demo崩溃 https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/CommonPitfalls/CommonPitfalls.html
        setupDatasource()
        title = "Caledar Demo"
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))

        let leftItem = UIBarButtonItem(title: "debugger", style: .plain, target: self, action: #selector(showDebugger))
        navigationItem.leftBarButtonItem = leftItem

        if #available(iOS 14.0, *) {
            let rightItem = UIBarButtonItem(title: "style", style: .plain, target: nil, action: nil)
            let actions = ShowDetailStyle.allCases.map { style in
                UIAction(title: String(describing: style),
                         image: nil,
                         identifier: nil,
                         discoverabilityTitle: nil,
                         attributes: [],
                         state: .off) { _ in
                    rightItem.title = String(describing: style)
                    self.style = style
                }
            }

            rightItem.menu = UIMenu(title: "Show Detail Style", image: nil, identifier: nil, options: [], children: actions)
            navigationItem.rightBarButtonItem = rightItem
        }

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.isNavigationBarHidden = false
    }

    @objc func showDebugger() {
        Navigator.shared.present(
            body: DebugBody(),
            wrap: UINavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .fullScreen }
        )
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = datasource[indexPath.row]

        if let customAction = item.customAction {
            customAction()
            return
        }

        let vc = item.targetVC()

        let style = (vc is UINavigationController) ? .present(.fullScreen) : self.style

        switch style {
        case .push:
            self.navigationController?.pushViewController(vc, animated: true)
        case .present(let style):
            vc.modalPresentationStyle = style
            self.present(vc, animated: true, completion: nil)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)
        cell.contentView.backgroundColor = UIColor.ud.bgBody
        cell.backgroundColor = UIColor.ud.bgBody
        cell.textLabel?.text = datasource[indexPath.row].title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension HomeVC: TabRootViewController {
    var controller: UIViewController {
        self
    }

    public var tab: Tab { return CalendarDemoTab.mockTab }

}

