//
//  DefaultSettingsController.swift
//  Calendar
//
//  Created by zc on 2018/5/24.
//  Copyright © 2018年 EE. All rights reserved.
//

import UniverseDesignIcon
import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import CalendarFoundation
import LarkContainer

final class SettingsInLarkController: DefaultSettingsController {
    override func viewDidLoad() {
        super.viewDidLoad()
        addBackItem()
    }
}

struct DefaultSettingsControllerDependency {
    let settingProvider: SettingProvider
    let is12HourStyle: BehaviorRelay<Bool>
    let accountManageVCGetter: ((AccountManageViewControllerDependency.PresentStyle) -> AccountManageViewController)
}

class DefaultSettingsController: BaseUIViewController, UserResolverWrapper {

    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var timeZoneService: TimeZoneService?

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    private lazy var provider: SettingPageProvider = {
        return SettingPageProvider(settingProvider: dependency.settingProvider,
                                   is12HourStyle: dependency.is12HourStyle,
                                   timeZoneService: timeZoneService,
                                   userID: userResolver.userID,
                                   fromWhere: fromWhere)
    }()

    let userResolver: UserResolver
    let fromWhere: CalendarSettingBody.FromWhere

    private let loadingView = LoadingPlaceholderView()
    private let disposeBag = DisposeBag()
    private let dependency: DefaultSettingsControllerDependency
    private var didScroll: Bool = false

    init(userResolver: UserResolver,
         dependency: DefaultSettingsControllerDependency,
         fromWhere: CalendarSettingBody.FromWhere = .none) {
        self.userResolver = userResolver
        self.dependency = dependency
        self.fromWhere = fromWhere
        super.init(nibName: nil, bundle: nil)
        self.title = BundleI18n.Calendar.Calendar_NewSettings_Calendar
        self.provider.delegate = self
        view.backgroundColor = UIColor.ud.bgFloatBase
        self.modalPresentationStyle = .fullScreen
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.isCalendarDataReady() {
            layoutSettingView()
            loadingView.isHidden = true
        } else {
            layoutLoadingView()
            loadingView.isHidden = false
            bindViewModel()
        }
        self.addCloseBtn()
        CalendarTracerV2.SettingCalendar.traceView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.fromWhere == .todayEvent && !didScroll {
            didScroll = true
            self.provider.view.scrollToFeedToTopSetting()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SettingService.shared().stateManager.activate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingService.shared().stateManager.inActivate()
    }

    func addCloseBtn() {
        let closeBarButton: LKBarButtonItem
        closeBarButton = LKBarButtonItem(image: UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined).scaleNaviSize().renderColor(with: .n1))
        closeBarButton.button.addTarget(self,
                                        action: #selector(dismissSelf),
                                        for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = closeBarButton
    }

    @objc
    fileprivate func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        LarkBadgeManager.hidden(.cal_local_item)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    private var needAuthWarningController: LocalCalNoAuthWarningController?

}

extension DefaultSettingsController: SettingPageProviderDelegate {

    func didSelectedWorkingHours(_ provider: SettingPageProvider) {
        let vc = WorkingHoursController(firstWeekday: provider.firstWeekday,
                                        is12HourStyle: dependency.is12HourStyle,
                                        workHourSetting: provider.workHourSettting)
        vc.workingHoursSettingChanged = { [weak self] (workHourSetting, onError: @escaping (SettingModel.WorkHourSetting) -> Void) in
            provider.setWorkHourSetting(workHourSetting, onError: onError)
            self?.traceClick("my_work_time")
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func didSelectedFirstWeekday(_ provider: SettingPageProvider) {
        let firstWeekdayPickerVC = FirstWeekdayPickerController(firstWeekday: provider.firstWeekday) { [weak self] firstWeekday in
            provider.setFirstWeekday(firstWeekday: firstWeekday)
            self?.navigationController?.popViewController(animated: true)
            self?.traceClick("first_day_of_week")
        }
        self.navigationController?.pushViewController(firstWeekdayPickerVC, animated: true)
    }

    func didSelectedAlternateCalendarday(_ provider: SettingPageProvider) {
        let alternateCalendarVC = AlternateCalendarController(alternateCalendar: provider.alternateCalendar) { [weak self] alternateCalendar in
            provider.setAlternateCalendary(alternateCalendary: alternateCalendar)
            self?.navigationController?.popViewController(animated: true)
            self?.traceClick("other_calendar_system")
        }
        self.navigationController?.pushViewController(alternateCalendarVC, animated: true)
    }

    func didSelectSkinSetting(_ provider: SettingPageProvider) {
        let skinSettingVC = SkinSettingController(skinType: provider.skinType) { [weak self] (type) in
            CalendarTracer.shareInstance.calSettingTheme(themeType: .init(type: type))
            provider.setSkinType(skinType: type)
            self?.navigationController?.popViewController(animated: true)
            self?.traceClick("event_color")
        }
        self.navigationController?.pushViewController(skinSettingVC, animated: true)
    }

    func didSelectLocalCal(_ provider: SettingPageProvider) {
        let localCal = LocalCalendarSettingController()
        self.navigationController?.pushViewController(localCal, animated: true)
    }

    func settingPageProvider(_ provider: SettingPageProvider, didSelectDefaultReminderWith model: Setting) {
        let picker = SettingReminderPickerController(reminder: model.noneAllDayReminder,
                                                     isAllday: false,
                                                     is12HourStyle: dependency.is12HourStyle)
        self.navigationController?.pushViewController(picker, animated: true)
        picker.selectCallBack = { [weak self] reminder in
            provider.setReminder(reminder)
            self?.navigationController?.popViewController(animated: true)
            CalendarTracer.shareInstance.calSettingNonAlldayNotification(reminder?.minutes)
            self?.traceClick("not_all_day_event_notification")
        }
    }

    func settingPageProvider(_ provider: SettingPageProvider,
                          didSelectAlldayReminderWith model: Setting) {

        let picker = SettingReminderPickerController(reminder: model.allDayReminder,
                                                     isAllday: true,
                                                     is12HourStyle: dependency.is12HourStyle)
        self.navigationController?.pushViewController(picker, animated: true)
        picker.selectCallBack = { [weak self] reminder in
            provider.setAlldayReminder(reminder)
            self?.navigationController?.popViewController(animated: true)
            CalendarTracer.shareInstance.calSettingAlldayNotification(reminder?.minutes)
            self?.traceClick("all_day_event_notification")
        }
    }

    func settingPageProvider(_ provider: SettingPageProvider,
                          didSelectGuestPermission model: Setting) {
        let permission = SettingService.shared().guestPermission
        let vc = EventEditGuestPermissionViewController(viewData: .init(guestPermission: permission),
                                                        source: .calendarSetting)
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func settingPageProvider(_ provider: SettingPageProvider,
                          didSelectEventDurationWith model: Setting) {

        let picker = EventDurationPickerController(duration: Int(model.defaultEventDuration))
        self.navigationController?.pushViewController(picker, animated: true)
        picker.selectCallBack = { [weak self] duration in
            provider.setEventDuration(duration)
            self?.navigationController?.popViewController(animated: true)
            CalendarTracer.shareInstance.calSettingEventDur(duration)
            self?.traceClick("event_default_length")
        }
    }

    func didSelectAccountManage(_ provider: SettingPageProvider) {
        let viewController = dependency.accountManageVCGetter(.push)
        viewController.newEmailAddressSelectedCallback = { _ in
            DispatchQueue.main.async {
                provider.forceUpdateSettingView()
            }
        }
        viewController.source = .setting
        self.navigationController?.pushViewController(viewController, animated: true)
        CalendarTracerV2.SettingCalendar.traceClick {
            $0.click("calendar_tripartite_manage").target("cal_tripartite_manage_view")
        }
    }

    func didSelectMeetingAccountManage(_ provider: SettingPageProvider) {
        let viewModel = MeetingAccountManageViewModel(userResolver: self.userResolver)
        let viewController = MeetingAccountManageViewController(viewModel: viewModel, userResolver: self.userResolver)
        self.navigationController?.pushViewController(viewController, animated: true)
        CalendarTracerV2.SettingCalendar.traceClick {
            $0.click("vchat_tripartite_manage").target("vchat_tripartite_manage_view")
        }
    }

    func settingPageProvider(_ provider: SettingPageProvider, didSelectAdditionalTimeZone model: Setting) {
        let body = CalendarAdditionalTimeZoneManagerBody(provider: provider)
        self.userResolver.navigator.push(body: body, from: self)
    }

    private func traceClick(_ click: String) {
        CalendarTracerV2.SettingCalendar.traceClick {
            $0.click(click).target("none")
        }
    }
}

extension DefaultSettingsController: EventEditGuestPermissionViewControllerDelegate {

    func didFinishEdit(from viewController: EventEditGuestPermissionViewController) {
        provider.setGuestPermission(viewController.viewData.guestPermission)
        self.navigationController?.popViewController(animated: true)
    }

    func didCancelEdit(from viewController: EventEditGuestPermissionViewController) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension DefaultSettingsController {

    func bindViewModel() {
        calendarManager?.updateRustCalendar()
        calendarManager?.rxCalendarUpdated
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                operationLog(message: "Calendar Data is not empty")
                self.layoutSettingView()
                self.loadingView.isHidden = true
            }).disposed(by: disposeBag)
    }

    func layoutLoadingView() {
        self.view.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func layoutSettingView() {
        self.view.addSubview(self.provider.view)
        self.provider.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    // MARK: 日历数据为空时，不能加载设置页
    func isCalendarDataReady() -> Bool {
        guard let isRustCalendarEmpty = calendarManager?.isRustCalendarEmpty else {
            return false
        }
        return !isRustCalendarEmpty
    }
}
