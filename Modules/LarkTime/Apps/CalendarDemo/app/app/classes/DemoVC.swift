//
//  NewHomeVC.swift
//  CalendarDemo
//
//  Created by huoyunjie on 2021/9/30.
//

import UIKit
@testable import Calendar
import LarkContainer
import AnimatedTabBar
import EENavigator
import LarkDebug
import SnapKit
import UniverseDesignTheme
import UniverseDesignDialog
import LarkQRCode
import LarkTab
import LarkUIKit
import UniverseDesignToast

extension DemoVC {
    /// 数据类型： 功能相关
    private func setupCommonAction() {
        let items = [
            DemoCellModel(title: "DM切换", customAction: {
                if #available(iOS 13.0, *) {
                    let currentTheme = UDThemeManager.userInterfaceStyle
                    if currentTheme == .dark || currentTheme == .unspecified {
                        UDThemeManager.setUserInterfaceStyle(.light)
                    } else {
                        UDThemeManager.setUserInterfaceStyle(.dark)
                    }
                }
            }, style: .switch_({
                if #available(iOS 13.0, *) {
                    return UDThemeManager.userInterfaceStyle == .dark
                } else {
                    return false
                }
            })),
            DemoCellModel(title: "Calendar 便捷调试", customAction: {
                FG.canDebug = !FG.canDebug
            }, style: .switch_({
                FG.canDebug
            })),
            DemoCellModel(title: "扫一扫", customAction: {
                Navigator.shared.present(
                    body: QRCodeControllerBody(),
                    from: self,
                    prepare: { controller in
                        controller.modalPresentationStyle = .fullScreen
                    } )
            }),
            DemoCellModel(title: "applink跳转", customAction: {
                let dialog = UDDialog()
                dialog.setTitle(text: "applink跳转")
                let content = UIView()
                let text = UITextField()
                text.borderStyle = .roundedRect
                content.addSubview(text)
                text.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                    make.height.equalTo(33)
                }
                dialog.setContent(view: content)
                dialog.addCancelButton()
                dialog.addPrimaryButton(text: "跳转", dismissCompletion: {
                    let link = text.text
                    Navigator.shared.open((URL(string: link!) ?? URL(string: "https://applink.feishu.cn/client/calendar/detail?shareToken=8HmuRknIGU7COxhlTlJRYX0rBu-Jzp3SdVbmjpqnk3H_P5JgfXFLe7yUfkbH22l6NGljA7zz9w=="))!, from: self)
                })
                self.present(dialog, animated: true, completion: nil)
            }),
            DemoCellModel(title: "农历测试", customAction: {
                LunarTest().mainTest()
                LunarTest().mainTest2()
            }),
        ]
        self.dataSourceItems.append(items)
    }

    /// 数据类型： 页面展示相关
    private func setupPageView() {
        let items = [
            DemoCellModel(title: "profile日历", targetVC: { [weak self] in
                guard let self = self else { return UIViewController() }
                let vc = self.calendar.getOldFreeBusyController(userId: "", isFromProfile: false)
                return vc
            }),
            DemoCellModel(title: "群忙闲日历", targetVC: { [weak self] in
                guard let self = self else { return UIViewController() }
                let vc = self.calendar.getOldGroupFreeBusyController(chatId: "6965842742559653890", chatType: "group", createEventBody: nil)
                return vc
            }),
            DemoCellModel(title: "消息卡片展示", targetVC: {
                let vc = CalendarCardController()
                return vc
            }),
            DemoCellModel(title: "日历设置", targetVC: { [weak self] in
                guard let self = self else { return UIViewController() }
                let settingVC = self.calendar.getSettingsController(fromWhere: .none)
                return settingVC
            }),
            DemoCellModel(title: "日历详情页", targetVC: { [weak self] in
                // 正式：6969165273245302786
                // BOE：6950530018398257171
                let viewModel = LegacyCalendarDetailViewModel(param: .token("g9qKUtRLmpeO9Cg-0w5IrMlFG0cIKwVWDniaE7mEWvy9D027p3OaNPf14kWo2gP6jMsoSmLK7w=="), userResolver: Container.shared.getCurrentUserResolver())
                let controller = LegacyCalendarDetailController(viewModel: viewModel, userResolver: Container.shared.getCurrentUserResolver())
                let naviVC = LkNavigationController(rootViewController: controller)
                return naviVC
            }),
            DemoCellModel(title: "可组装编辑页", customAction: {
                let legoInfo: EventEditLegoInfo = .none(adding: [
                    .id(.datePicker),
                    .id(.timeZone),
                    .id(.location),
                    .id(.videoMeeting),
                    .id(.meetingRoom)])
                let editMode: EventEditMode
                let interceptor: EventEditInterceptor
                if let event = self.event {
                    editMode = EventEditMode.edit(event: event)
                    interceptor = EventEditInterceptor.onlyResult(callBack: { event in
                        print(event)
                    })
                } else {
                    editMode = EventEditMode.create
                    interceptor = EventEditInterceptor.onlyResult { event in
                        print(event)
                        self.event = event
                    }
                }

                let result = self.calendar.getEventEditController(legoInfo: legoInfo,
                                                                      editMode: editMode,
                                                                      interceptor: interceptor,
                                                                      title: "编辑日程")
                switch result {
                case .success(let controller):
                    Navigator.shared.present(controller, from: self)
                case .error(let message):
                    UDToast().showTips(with: message, on: self.view)
                }
            }),
            DemoCellModel(title: "时区选择", customAction: { [weak self] in
                guard let self = self else { return }
                let timeZone = TimeZone.current
                self.calendar.showTimeZoneSelectController(with: nil, from: self, onTimeZoneSelect: { timeZone in
                    print("henry timezone \(timeZone.identifier)")
                })
            }),
            DemoCellModel(title: "webinar event", customAction: { [weak self] in
                guard let self = self else { return }
                let createEventBody = CalendarCreateEventBody(perferredScene: .webinar)
                Navigator.shared.present(body: createEventBody, from: self)
            })
        ]
        self.dataSourceItems.append(items)
    }

    /// 数据组装
    private func setupDataSource() {
        self.setupCommonAction()
        self.setupPageView()
    }
}

final class DemoVC: UITableViewController {

    enum ShowStyle {
        case push
        case showDetail
        case present(UIModalPresentationStyle)

        static var allCases: [ShowStyle] {
            [.push, .showDetail] + UIModalPresentationStyle.allCases.map { .present($0) }
        }

        var description: String {
            switch self {
            case .push: return "push"
            case .showDetail: return "showDetail"
            case .present(let style): return String(describing: style)
            }
        }
    }

    @InjectedLazy var calendar: CalendarInterface

    private var dataSourceItems: [[DemoCellModel]] = []
    private var style: ShowStyle = .present(.pageSheet)

    private var event: MailCalendarEvent? = nil

    init() {
        super.init(style: .grouped)
        setupDataSource()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        signal(SIGPIPE, SIG_IGN)
        setupNavigationItem()
        setupTableView()

        if #available(iOS 15.0, *) {
//            UITableView.appearance().sectionHeaderTopPadding = 0
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        let sections = self.dataSourceItems.count
        for section in 0..<sections {
            let lastRow = self.dataSourceItems[section].count - 1
            let firstCell = tableView.cellForRow(at: IndexPath(row: 0, section: section)) as? DemoCellView
            let lastCell = tableView.cellForRow(at: IndexPath(row: lastRow, section: section)) as? DemoCellView
            firstCell?.setCornersRadius(radius: 8, roundingCorners: [[.topLeft, .topRight]])
            lastCell?.setCornersRadius(radius: 8, roundingCorners: [[.bottomLeft, .bottomRight]])
        }
    }

    @objc
    func showDebugger() {
        Navigator.shared.present(
            body: DebugBody(),
            wrap: UINavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .fullScreen }
        )
    }

    private func setupNavigationItem() {
        title = "Calendar Demo"
        //left navigationBarButton
        let leftNavBarBtn = UIBarButtonItem(title: "debugger", style: .plain, target: self, action: #selector(showDebugger))
        navigationItem.leftBarButtonItem = leftNavBarBtn

        if #available(iOS 14.0, *) {
            let rightNavBarBtn = UIBarButtonItem(title: "style", style: .plain, target: nil, action: nil)
            let actions = ShowStyle.allCases.map { style in
                UIAction(title: String(describing: style),
                         image: nil,
                         identifier: nil,
                         discoverabilityTitle: nil,
                         attributes: [],
                         state: .off) { _ in
                    rightNavBarBtn.title = String(describing: style)
                    self.style = style
                }
            }
            rightNavBarBtn.menu = UIMenu(title: "show style", image: nil, identifier: nil, options: [], children: actions)
            navigationItem.rightBarButtonItem = rightNavBarBtn
        }

    }

    private func setupTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.backgroundColor = UIColor.ud.bgFloatBase
        self.tableView.rowHeight = 45
        self.tableView.separatorStyle = .none
        self.tableView.register(DemoCellView.self, forCellReuseIdentifier: "Cell")
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let cell = tableView.cellForRow(at: indexPath) as? DemoCellView,
              let viewData = cell.viewData else { return }
        if let customeAction = viewData.customAction {
            customeAction()
            if case let .switch_(action) = cell.viewData?.style {
                cell.switchButton.setOn(action(), animated: true)
            }
            return
        }

        let vc = viewData.targetVC()

        switch style {
        case .push:
            if vc is UINavigationController {
                vc.modalPresentationStyle = .pageSheet
                self.present(vc, animated: true, completion: nil)
            } else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case .showDetail:
            self.showDetailViewController(vc, sender: nil)
        case .present(let style):
            vc.modalPresentationStyle = style
            if case .popover = style,
               let cell = tableView.cellForRow(at: indexPath) {
                vc.popoverPresentationController?.sourceView = cell
                vc.popoverPresentationController?.canOverlapSourceViewRect = false
                vc.popoverPresentationController?.sourceRect = cell.bounds
                vc.popoverPresentationController?.permittedArrowDirections = .left
            }
            self.present(vc, animated: true, completion: nil)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        guard let viewcell = cell as? DemoCellView,
              indexPath.section < dataSourceItems.count,
              indexPath.row < dataSourceItems[indexPath.section].count else {
            return UITableViewCell()
        }
        let vm = dataSourceItems[indexPath.section][indexPath.row]
        viewcell.viewData = vm
        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSourceItems.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSourceItems[section].count
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 33
    }
}

extension DemoVC: TabRootViewController {
    var controller: UIViewController {
        self
    }

    public var tab: Tab { return CalendarDemoTab.mockTab }

}

extension DemoVC: TabbarItemTapProtocol {
    public func onTabbarItemDoubleTap() {
        onTabbarItemTapped()
    }

    public func onTabbarItemTap(_ isSameTab: Bool) {
        if isSameTab {
            onTabbarItemTapped()
        }
    }

    public func onTabbarItemTapped() {
        guard let nav = self.navigationController else { return }
        let vcs = nav.viewControllers
        if vcs.count > 1 {
            if vcs[0] == self {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
}
