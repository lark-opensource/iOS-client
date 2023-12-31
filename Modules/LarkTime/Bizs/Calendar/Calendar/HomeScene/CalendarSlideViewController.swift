//
//  CalendarSlideViewController.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/5/27.
//

import UniverseDesignIcon
import UIKit
import LarkContainer
import LarkUIKit
import UniverseDesignActionPanel
import LKCommonsLogging

final class CalendarSlideViewController: UIViewController, UserResolverWrapper {

    @ScopedInjectedLazy var calendarInterface: CalendarInterface?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?

    let logger = Logger.log(CalendarSlideViewController.self, category: "Calendar.CalendarSlideViewController")

    var calendarVCDependency: CalendarViewControllerDependency
    var sceneModeDidChange: ((HomeScene.SceneMode) -> Void)?
    var highlightCalendarID: String?
    var source: String?
    var dismissCompleted: (() -> Void)?
    lazy var slideView: SlideView = {
        let slideView = SlideView()
        slideView.backgroundColor = UIColor.ud.bgBody
        return slideView
    }()

    lazy var calendarListController: CalendarListController = {
        let viewModel = CalendarListViewModel(userResolver: self.userResolver, highlightData: highlightCalendarID.map({ .init(source: .calendar, id: $0 )}))
        let vc = CalendarListController(viewModel: viewModel, userResolver: self.userResolver, source: self.source ?? "")
        return vc
    }()

    lazy var tableView: UITableView = {
        return calendarListController.tableView
    }()

    private let slideViewWidthRatio: CGFloat = Display.pad ? 1.0 : 0.8

    let userResolver: UserResolver

    init(with calendarVCDependency: CalendarViewControllerDependency, userResolver: UserResolver) {
        self.calendarVCDependency = calendarVCDependency
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(slideView)

        slideView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            if Display.pad {
                make.leading.trailing.equalToSuperview()
            } else {
                make.width.equalToSuperview().multipliedBy(slideViewWidthRatio)
                make.leading.equalTo(view.snp.trailing)
            }
        }

        var tap = UITapGestureRecognizer()
        tap.delegate = self
        view.addGestureRecognizer(tap)
        _ = tap.rx.event.subscribeForUI(onNext: { [weak self] _ in
            self?.exit()
        })

        slideView.calendarTypeStackView.arrangedSubviews.forEach { view in
            tap = UITapGestureRecognizer()
            if let view = view as? CalendarTypeItemView {
                let mode = view.type.scene
                view.addGestureRecognizer(tap)
                _ = tap.rx.event.asDriver().drive(onNext: { [weak self, weak view] _ in
                    guard let self = self else { return }
                    (self.slideView.calendarTypeStackView.arrangedSubviews as? [CalendarTypeItemView])?.forEach { $0.selected = false }

                    switch mode {
                    case .day(let days):
                        switch days {
                        case .single:
                            CalendarTracerV2.CalendarList.traceClick { $0.click("day_view") }
                        case .week:
                            CalendarTracerV2.CalendarList.traceClick { $0.click("week_view") }
                        case .three:
                            CalendarTracerV2.CalendarList.traceClick { $0.click("three_day_view") }
                        }
                    case .list:
                        CalendarTracerV2.CalendarList.traceClick { $0.click("list_view") }
                    case .month:
                        CalendarTracerV2.CalendarList.traceClick { $0.click("month_view") }
                    }

                    self.sceneModeDidChange?(mode)
                    self.exit()
                    view?.selected = true
                })
            }
        }

        tap = UITapGestureRecognizer()
        slideView.goSettingsView.addGestureRecognizer(tap)
        _ = tap.rx.event.asDriver().drive(onNext: { [weak self] _ in
            self?.goSettings()
        })

        tap = UITapGestureRecognizer()
        slideView.addNewCalendarView.addGestureRecognizer(tap)
        _ = tap.rx.event.subscribeForUI(onNext: { [weak self] gesture in
            if let view = gesture.view {
                self?.addCalendarTapped(sender: view)
            }
        })

        addChild(calendarListController)
        slideView.addSubview(calendarListController.view)
        calendarListController.view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(slideView.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(slideView.goSettingsView.snp.top)
        }
        setupTableView()
    }

    private func setupTableView() {
        // 给 header 部分预留的位置之和
        let offsetY: CGFloat = 20 + 66 + 55 + 13
        tableView.contentInset.top = offsetY
        tableView.contentOffset.y = -offsetY
        tableView.addSubview(slideView.calendarTypeStackView)
        tableView.addSubview(slideView.addNewCalendarView)
        slideView.calendarTypeStackView.snp.remakeConstraints { make in
            make.leading.trailing.equalTo(tableView.frameLayoutGuide).inset(20)
            make.bottom.equalTo(slideView.addNewCalendarView.snp.top).offset(-13)
        }
        slideView.addNewCalendarView.snp.remakeConstraints { make in
            make.leading.trailing.equalTo(tableView.frameLayoutGuide)
            make.bottom.equalTo(tableView.contentLayoutGuide)
        }

    }

    func setDefaultMode(mode: HomeSceneMode) {
        self.slideView.calendarTypeStackView.arrangedSubviews.forEach {
            if let view = $0 as? CalendarTypeItemView {
                view.selected = (view.type.scene == mode)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !Display.pad {
            slideView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(slideViewWidthRatio)
                make.trailing.equalToSuperview()
            }

            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
                self.view.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.3)
            }
        }
    }

    private func goSettings() {
        guard let settingVC = calendarInterface?.getSettingsController(fromWhere: .none) as? DefaultSettingsController else {
            assertionFailure()
            return
        }
        let navi = LkNavigationController(rootViewController: settingVC)
        navi.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        _ = settingVC.view // 提前触发viewDidLoad中的逻辑
        settingVC.addCloseItem()
        present(navi, animated: true)
        CalendarTracerV2.CalendarList.traceClick { $0.click("calendar_main_setting") }
    }

    private func addCalendarTapped(sender: UIView) {
        guard let calendarDependency = self.calendarDependency else {
            self.logger.error("addCalendarTapped failed, can not get calendarDependency from larkcontainer")
            return
        }
        CalendarTracerV2.CalendarList.traceClick { $0.click("cal_plus") }
        let source = UDActionSheetSource(sourceView: sender,
                                         sourceRect: sender.bounds,
                                         arrowDirection: .up)
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(popSource: source))
        let isTurnoffGoogleCalendarImport = FG.isTurnoffGoogleCalendarImport

        let newCalendarTitle = BundleI18n.Calendar.Calendar_Setting_NewCalendar
        let newCalAction: () -> Void = { [weak self, weak actionSheet] in
            guard let self = self else { return }
            if !isTurnoffGoogleCalendarImport {
                actionSheet?.dismiss(animated: true, completion: nil)
            }
            var controller: UIViewController

            if FG.optimizeCalendar {
                let editVC = CalendarEditViewController(viewModel: .init(from: .fromCreate, userResolver: self.userResolver))
                let navi = LkNavigationController(rootViewController: editVC)
                navi.modalPresentationStyle = .fullScreen
                if #available(iOS 13.0, *) { navi.isModalInPresentation = true }
                controller = navi
            } else {
                guard let calendarDependency = self.calendarVCDependency.calendarDependency else { return }
                controller = CalendarManagerFactory.newController(
                    selfUserId: self.userResolver.userID,
                    calendarAPI: self.calendarVCDependency.calendarApi,
                    calendarDependency: calendarDependency,
                    skinType: SettingService.shared().getSetting().skinTypeIos,
                    showSidebar: { [weak self] in
                        self?.localRefreshService?.rxCalendarNeedRefresh.onNext(())
                    },
                    disappearCallBack: nil,
                    finishSharingCallBack: nil
                )
            }

            if Display.pad {
                controller.modalPresentationStyle = .formSheet
            }
            self.present(controller, animated: true, completion: nil)
            CalendarTracerV2.CalendarActionList.traceClick {
                $0.click("add_cal").target("cal_calendar_create_view")
            }
        }

        let subscribeCalendarTitle = BundleI18n.Calendar.Calendar_SubscribeCalendar_SubscribeCalendars
        let subscribeCalAction: () -> Void = { [weak self, weak actionSheet] in
            guard let self = self else { return }
            if !isTurnoffGoogleCalendarImport {
                actionSheet?.dismiss(animated: true, completion: nil)
            }
            let controller = SubscribeViewController(
                userResolver: self.userResolver,
                calendarApi: self.calendarVCDependency.calendarApi,
                currentTenantID: calendarDependency.currentUser.tenantId,
                disappearCallBack: { [weak self] in
                    self?.calendarListController.viewModel.fetchData()
                }
            )
            let nav = LkNavigationController(rootViewController: controller)
            nav.update(style: .default)
            nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            self.present(nav, animated: true, completion: nil)
            CalendarTracerV2.CalendarActionList.traceClick {
                $0.click("subscribe_cal").target("cal_calendar_subscribe_view")
            }
        }

        let importCalendarTitle = BundleI18n.Calendar.Calendar_Sync_AddThirdPartyCalendar
        let googleOrLocalCalAction: () -> Void = { [weak self, weak actionSheet] in
            guard let self = self else { return }
            if !isTurnoffGoogleCalendarImport {
                actionSheet?.dismiss(animated: true, completion: nil)
            }
            CalendarTracer.shareInstance.calAddAccount(actionSource: .quickActionSheet)
            let dependency = ImportCalendarViewControllerDependency(
                bindGoogleCalAddrGetter: self.calendarVCDependency.calendarApi.getBindGoogleCalAddr,
                disappearCallBack: { [weak self] in
                    self?.calendarListController.viewModel.fetchData()
                }
            )
            let navi = LkNavigationController(rootViewController: ImportCalendarViewController.controllerWithClose(userResolver: self.userResolver, dependency: dependency))
            navi.update(style: .default)
            navi.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            self.present(navi, animated: true, completion: nil)
            CalendarTracerV2.CalendarActionList.traceClick {
                $0.click("tripartite_add").target("cal_tripartite_add_view")
            }
        }

        var items: [UDActionSheetItem] = [
            .init(title: newCalendarTitle, action: newCalAction),
            .init(title: importCalendarTitle, action: googleOrLocalCalAction)
        ]

        // C端用户不能订阅日历
        if !calendarDependency.currentUser.isCustomer {
            let index = FG.optimizeCalendar ? 0 : 1
            items.insert(.init(title: subscribeCalendarTitle, action: subscribeCalAction), at: index)
        }

        items.forEach { actionSheet.addItem($0) }
        actionSheet.setCancelItem(text: I18n.Calendar_Common_Cancel)

        self.present(actionSheet, animated: true, completion: nil)
        CalendarTracerV2.CalendarActionList.traceView()
    }

    func exit() {
        guard !Display.pad else {
            dismiss(animated: true) { [weak self] in
                self?.dismissCompleted?()
            }
            return
        }
        slideView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(slideViewWidthRatio)
            make.leading.equalTo(view.snp.trailing)
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.view.backgroundColor = UIColor.clear.withAlphaComponent(0)
        } completion: { _ in
            self.dismiss(animated: false) { [weak self] in
                self?.dismissCompleted?()
            }
        }

    }

}

extension CalendarSlideViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: nil)
        return gestureRecognizer.view?.hitTest(point, with: nil) == gestureRecognizer.view
    }
}

extension CalendarSlideViewController {
    final class CalendarTypeItemView: UIView {
        struct ItemType {
            let title: String
            let image: UIImage
            let scene: HomeScene.SceneMode
        }

        var selected = false {
            didSet {
                if selected {                        imageView.image = imageView
                    .image?
                    .ud.withTintColor(UIColor.ud.primaryContentDefault)
                    backgroundColor = UIColor.ud.primaryFillSolid01
                    titleLabel.textColor = UIColor.ud.primaryContentDefault
                } else {
                    imageView.image = imageView
                        .image?.renderColor(with: .n2)
                    titleLabel.textColor = UIColor.ud.iconN2
                    backgroundColor = .clear
                }
            }
        }
        let type: ItemType

        private lazy var imageView: UIImageView = {
            let imageView = UIImageView()
            return imageView
        }()

        private(set) lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.ud.caption1(.fixed)
            label.numberOfLines = 0
            return label
        }()

        init(type: ItemType) {
            self.type = type
            super.init(frame: .zero)

            translatesAutoresizingMaskIntoConstraints = false

            addSubview(imageView)
            addSubview(titleLabel)

            imageView.image = type.image
            titleLabel.text = type.title

            imageView.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(9)
                make.centerX.equalToSuperview()
                make.size.equalTo(CGSize(width: 30, height: 30))
            }

            titleLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(imageView.snp.bottom).offset(4)
                make.bottom.equalToSuperview().inset(9)
            }

            layer.cornerRadius = 8
            layer.masksToBounds = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    final class AddNewCalendarView: UIView {

        lazy var iconView: UIImageView = {
            let icon: UDIconType = FG.optimizeCalendar ? .addOutlined : .calendarAddOutlined
            let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(icon).renderColor(with: .n2))
            return imageView
        }()

        private(set) lazy var label: UILabel = {
            let label = UILabel()
            label.font = UIFont.ud.body0(.fixed)
            label.text = BundleI18n.Calendar.Calendar_Common_AddCalendar
            label.textColor = UIColor.ud.textTitle
            label.numberOfLines = 0
            return label
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(iconView)
            iconView.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 20, height: 20))
            }

            addSubview(label)
            label.snp.makeConstraints { make in
                make.centerY.equalTo(iconView)
                make.leading.equalTo(iconView.snp.trailing).offset(8)
            }

            addBottomSepratorLine().snp.remakeConstraints { make in
                make.bottom.right.equalToSuperview()
                make.left.equalToSuperview().inset(16)
                make.height.equalTo(0.5)
            }
            addTopSepratorLine().snp.remakeConstraints { make in
                make.top.right.left.equalToSuperview()
                make.height.equalTo(0.5)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            CGSize(width: UIView.noIntrinsicMetric, height: 55)
        }
    }

    final class GoSettingsView: UIView {
        private(set) lazy var label: UILabel = {
            let label = UILabel()
            label.font = UIFont.ud.body0(.fixed)
            label.text = I18n.Calendar_Setting_Settings
            label.textColor = UIColor.ud.textTitle
            label.numberOfLines = 0
            return label
        }()

        private lazy var iconView: UIImageView = {
            let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.rightOutlined).renderColor(with: .n3))
            return imageView
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(label)
            label.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
            }

            addSubview(iconView)
            iconView.snp.makeConstraints { make in
                make.centerY.equalTo(label)
                make.trailing.equalToSuperview().inset(15)
                make.size.equalTo(CGSize(width: 20, height: 20))
            }

            addTopSepratorLine()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            CGSize(width: UIView.noIntrinsicMetric, height: 55)
        }
    }

    final class SlideView: UIView {

        lazy var calendarTypeStackView: UIStackView = {
            let itemViews: [CalendarTypeItemView]
            let day = BundleI18n.Calendar.Calendar_DailyView_DailyViewUpdate322
            let week = BundleI18n.Calendar.Calendar_WeekView_WeekViewUpdate322
            let month = BundleI18n.Calendar.Calendar_MonView_MonthlyViewUpdate322
            let list = BundleI18n.Calendar.Calendar_View_AgendaView
            let threeDay = BundleI18n.Calendar.Calendar_View_ThreeDayView
            if Display.pad {
                itemViews = [
                    .init(type: .init(title: day, image: UDIcon.getIconByKeyNoLimitSize(.viewDayOutlined).renderColor(with: .n2), scene: .day(.single))),
                    .init(type: .init(title: week, image: UDIcon.getIconByKeyNoLimitSize(.view3dayOutlined).renderColor(with: .n2), scene: .day(.week))),
                    .init(type: .init(title: month, image: UDIcon.getIconByKeyNoLimitSize(.viewMonthOutlined).renderColor(with: .n2), scene: .month))
                ]
            } else {
                itemViews =
                [
                    .init(type: .init(title: list, image: UDIcon.getIconByKeyNoLimitSize(.viewTaskOutlined).renderColor(with: .n2), scene: .list)),
                    .init(type: .init(title: day, image: UDIcon.getIconByKeyNoLimitSize(.viewDayOutlined).renderColor(with: .n2), scene: .day(.single))),
                    .init(type: .init(title: threeDay, image: UDIcon.getIconByKeyNoLimitSize(.view3dayOutlined).renderColor(with: .n2), scene: .day(.three))),
                    .init(type: .init(title: month, image: UDIcon.getIconByKeyNoLimitSize(.viewMonthOutlined).renderColor(with: .n2), scene: .month))
                ]
            }
            let stackView = UIStackView(arrangedSubviews: itemViews)
            stackView.distribution = .fillEqually
            return stackView
        }()

        lazy var addNewCalendarView: AddNewCalendarView = AddNewCalendarView()
        lazy var goSettingsView: UIView = GoSettingsView()

        override init(frame: CGRect) {
            super.init(frame: .zero)

            addSubview(calendarTypeStackView)
            calendarTypeStackView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(20)
            }

            addSubview(addNewCalendarView)
            addNewCalendarView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(calendarTypeStackView.snp.bottom).offset(13)
            }

            addSubview(goSettingsView)
            goSettingsView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }
}
