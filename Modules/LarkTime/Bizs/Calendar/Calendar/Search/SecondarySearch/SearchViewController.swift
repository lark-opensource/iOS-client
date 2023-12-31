//
//  SearchViewController.swift
//  CalendarInChat
//
//  Created by zoujiayi on 2019/8/9.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import LarkUIKit
import CalendarFoundation
import LarkContainer
// import EENavigator

public final class CalendarSearchViewController: BaseUIViewController, UserResolverWrapper {
    private let getDetailController: GetNormalDetailController
    private let disposeBag = DisposeBag()
    private let originalCalendarIds: [String]

    private let searchNaviBar: SearchNaviBar
    var searchBar: SearchBar { return searchNaviBar.searchbar }
    private var searchField: SearchUITextField { return searchNaviBar.searchbar.searchTextField }
    private var searchFilter = CalendarSearchFilter()
    private let calendarAPI: CalendarRustAPI

    private weak var calendarFilter: CalendarFilterItem?
    private weak var attendeeFilter: AttendeeFilterItem?
    private weak var meetingRoomFilter: CalendarFilterItem?
    private weak var dateFilter: CalendarFilterItem?

    private var filters: [SearchFilterSelectorCellContext] = []
    let filterView = SearchFilterSelectorView(filters: [])
    private let loader: SearchDataLoader
    private let calenderLoader: (() -> Observable<[[SidebarCellContent]]>)
    private let currentTenantId: String
    private let multiLevelResources: Bool
    private let subscribeViewController: UIViewController
    private let calendarFilterViewController: CalendarFilterViewController

    public var userResolver: UserResolver
    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    private let shouldUseSearchBar: Bool

    init(userResolver: UserResolver,
         getDetailController: @escaping GetNormalDetailController,
         subscribeViewController: UIViewController,
         calenderLoader: @escaping () -> Observable<[[SidebarCellContent]]>,
         calendarApi: CalendarRustAPI,
         skinType: CalendarSkinType,
         startWeekday: DaysOfWeek,
         is12Hour: BehaviorRelay<Bool>,
         query: String,
         currentTenantId: String,
         searchNaviBar: SearchNaviBar?) {
        self.userResolver = userResolver
        self.calenderLoader = calenderLoader
        self.calendarAPI = calendarApi
        self.getDetailController = getDetailController
        self.originalCalendarIds = []
        self.subscribeViewController = subscribeViewController
        self.currentTenantId = currentTenantId
        let tenantSetting = SettingService.shared().tenantSetting ?? SettingService.defaultTenantSetting
        self.multiLevelResources = tenantSetting.resourceDisplayType == .hierarchical && FG.multiLevel
        self.searchNaviBar = searchNaviBar ?? SearchNaviBar(style: .back)
        self.shouldUseSearchBar = searchNaviBar == nil

        loader = SearchDataLoader(api: calendarAPI,
                                  skinType: skinType,
                                  is12Hour: is12Hour,
                                  startWeekday: startWeekday)
        calendarFilterViewController = CalendarFilterViewController(calenderLoader: calenderLoader,
                                                                    subscribeViewController: subscribeViewController,
                                                                    userResolver: self.userResolver)

        super.init(nibName: nil, bundle: nil)

        searchField.text = query

        filters = getFilters()
        initCalendarFilter()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody
        isNavigationBarHidden = true
        if shouldUseSearchBar {
            layoutSearchZone()
        }

        setUpFilterView()

        let searchInstanceView = SearchTableViewWraaper(loader: loader, localRefreshService: self.localRefreshService)
        var hasTracedFirstDataAppear = false
        loader.reloadData = { [weak searchInstanceView, weak self] (isEmptyQuery) in
            searchInstanceView?.reloadTable(isEmptyQuery: isEmptyQuery)
            guard let `self` = self else { return }
            if !hasTracedFirstDataAppear {
                CalendarTracer.shareInstance.calSearchAdvanced(hasResult: !self.loader.getData().isEmpty)
                hasTracedFirstDataAppear = true
            }
        }
        self.view.addSubview(searchInstanceView)
        searchInstanceView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(filterView.snp.bottom)
            make.bottom.equalToSuperview()
        }
        searchInstanceView.reloadTable(isEmptyQuery: true)
        searchInstanceView.onItemSelected = { [weak self] item in
            guard let `self` = self else { return }
            CalendarTracer.shareInstance.calSearchResult(actionSource: .advanced)
            let vc = self.getDetailController(.search,
                                              item.key,
                                     item.calendarId,
                                     item.originalTime,
                                     Int64(item.startDate.timeIntervalSince1970),
                                     Int64(item.endDate.timeIntervalSince1970),
                                     "",
                                     false,
                                     false,
                                     .search)
            if Display.pad {
                let nav = LkNavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .formSheet
                self.present(nav, animated: true)
            } else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }

        search()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchField.becomeFirstResponder()
    }

    func getFilters() -> [SearchFilterSelectorCellContext] {
        var calOriginalText = ""

        if self.searchFilter.calendarIds.isEmpty {
            calOriginalText = BundleI18n.Calendar.Calendar_EventSearch_ChooseCal
        } else {
            calOriginalText = BundleI18n.Calendar.Calendar_Plural_SearchInCalendar(number: searchFilter.calendarIds.count)
        }

        let calendarFilter = CalendarFilterItem(originalLabelText: calOriginalText) { [unowned self] in
            self.showCalendarFilter()
            self.filterView.set(filters: self.filters)
        }

        let dateFilter = CalendarFilterItem(originalLabelText: BundleI18n.Calendar.Calendar_EventSearch_Date) { [unowned self] in
            self.showDateFilter()
            self.filterView.set(filters: self.filters)
        }

        let meetingRoomFilter = CalendarFilterItem(originalLabelText: BundleI18n.Calendar.Calendar_Edit_Room) { [unowned self] in
            self.showSearchMeetingRoom()
            self.filterView.set(filters: self.filters)
        }
        let attendeeFilter = AttendeeFilterItem { [unowned self] in
            self.showAttendeeFilter()
            self.filterView.set(filters: self.filters)
        }
        calendarFilter.isActive = false
        attendeeFilter.isActive = false
        meetingRoomFilter.isActive = false
        dateFilter.isActive = false

        self.calendarFilter = calendarFilter
        self.attendeeFilter = attendeeFilter
        self.meetingRoomFilter = meetingRoomFilter
        self.dateFilter = dateFilter

        if multiLevelResources {
            return [calendarFilter, attendeeFilter, dateFilter]
        } else {
            return [calendarFilter, attendeeFilter, meetingRoomFilter, dateFilter]
        }
    }

    private func setUpFilterView() {
        filterView.set(filters: filters)
        self.view.addSubview(filterView)
        filterView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            if shouldUseSearchBar {
                make.top.equalTo(searchNaviBar.snp.bottom)
            } else {
                make.top.equalToSuperview()
            }
        }
    }

    private func layoutSearchZone() {
        view.addSubview(searchNaviBar)
        searchNaviBar.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
        }
        searchBar.leftButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] () in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        searchBar.cancelButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] () in
                guard let self = self else { return }
                if self.presentingViewController != nil {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                } else {
                    if
                        let viewControllers = self.navigationController?.viewControllers,
                        let vcCount = Optional(viewControllers.count),
                        viewControllers.count >= 3,
                        viewControllers[vcCount - 2] is SearchBarTransitionTopVCDataSource {
                        self.navigationController?.popToViewController(viewControllers[vcCount - 3], animated: true)
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            })
            .disposed(by: disposeBag)
        searchField.placeholder = BundleI18n.Calendar.Calendar_EventSearch_Event
        searchField.rx.controlEvent(.editingChanged).throttle(.milliseconds(100), scheduler: MainScheduler.instance).bind { [weak self] () in
            self?.search()
        }
    }

    public func search() {
        loader.search(query: searchField.text ?? "", filter: searchFilter)
    }

    func showAttendeeFilter() {
        let attendeeChatterIds = searchFilter.attendees.compactMap { $0.chatterId }
        let attendeeChatIds = searchFilter.attendees.compactMap { $0.chatId }
        calendarDependency?
            .jumpToSearchAttendeeController(from: self,
                                              title: BundleI18n.Calendar.Calendar_Edit_AddGuest,
                                              chatterIds: attendeeChatterIds,
                                              chatIds: attendeeChatIds,
                                              needSearchOuterTenant: true,
                                              enableSearchingOuterTenant: true) { [weak self] seeds in
                guard let `self` = self, let primaryCalendarID = self.calendarManager?.primaryCalendarID else { return }
                self.calendarAPI.loadAttendees(by: seeds, primaryCalendarID: primaryCalendarID).subscribe(onNext: { [weak self] (attendees) in
                    guard let `self` = self,
                    let attendeeFilter = self.attendeeFilter  else { return }
                    self.searchFilter.attendees = attendees

                    attendeeFilter.set(avatars: attendees.map { AvatarImpl(avatarKey: $0.avatar.avatarKey, userName: $0.avatar.userName, identifier: $0.avatar.identifier) })
                    if attendees.isEmpty {
                        attendeeFilter.isActive = false
                    } else {
                        attendeeFilter.isActive = true
                    }
                    self.filters[1] = attendeeFilter
                    self.filterView.set(filters: self.filters)
                    self.search()
                }, onError: { (error) in
                    operationLog(message: "\(error)", optType: "SearchViewControllerError")
                }).disposed(by: self.disposeBag)
            }
    }

    private func showSearchMeetingRoom() {
        if !multiLevelResources {
            let viewModel = MeetingRoomContainerViewModel(userResolver: self.userResolver, tenantID: currentTenantId, actionSource: .searchMeeting)
            let vc = SearchMeetingRoomFilterableController(userResolver: self.userResolver,
                                                           viewModel: viewModel,
                                                           selectedMeetingRooms: searchFilter.resource,
                                                           meetingRoomApi: calendarAPI,
                                                           tenantID: currentTenantId)
            self.navigationController?.pushViewController(vc, animated: true)
            vc.delegate = self
            return
        }
    }

    private func initCalendarFilter() {
        calendarFilterViewController.finishChooseCalendars = { [weak self] calendars in
            guard let `self` = self else { return }
            if calendars.isEmpty {
                self.calendarFilter?.setText(BundleI18n.Calendar.Calendar_EventSearch_ChooseCal)
                self.calendarFilter?.isActive = false
            } else {
                self.calendarFilter?.setText(BundleI18n.Calendar.Calendar_Plural_SearchInCalendar(number: calendars.count))
                self.calendarFilter?.isActive = true
            }
            self.filterView.set(filters: self.filters)
            self.searchFilter.calendarIds = calendars
            self.search()
        }
        calendarFilterViewController.reloadData(needCallBack: true)
    }

    private func showCalendarFilter() {
        self.navigationController?.pushViewController(calendarFilterViewController, animated: true)
    }

    private func showDateFilter() {
        let startDate: Date?
        if let startTS = searchFilter.startTimeStamp {
            startDate = Date(timeIntervalSince1970: TimeInterval(startTS))
        } else {
            startDate = nil
        }

        let endDate: Date?
        if let endTS = searchFilter.endTimeStamp {
            endDate = Date(timeIntervalSince1970: TimeInterval(endTS))
        } else {
            endDate = nil
        }

        let vc = SearchDateFilterViewController(startDate: startDate, endDate: endDate)
        vc.finishChooseBlock = { [weak self] (_, startDate, endDate) in
            guard let `self` = self else { return }
            var timeString = ""
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            if startDate != nil {
                if endDate != nil {
                    timeString = BundleI18n.Calendar.Calendar_StandardTime_GeneralDateTimeRangeWithoutWrap(startTime: formatter.string(from: startDate!), endTime: formatter.string(from: endDate!))
                    self.dateFilter?.isActive = true
                } else {
                    timeString = BundleI18n.Calendar.Calendar_EventSearch_TimeFilter(x: formatter.string(from: startDate!))
                    self.dateFilter?.isActive = true
                }
            } else if endDate != nil {
                timeString = BundleI18n.Calendar.Calendar_EventSearch_TimeFilterTwo(y: formatter.string(from: endDate!))
                self.dateFilter?.isActive = true
            } else {
                timeString = BundleI18n.Calendar.Calendar_EventSearch_Date
                self.dateFilter?.isActive = false
            }
            self.dateFilter?.setText(timeString)
            self.filterView.set(filters: self.filters)
            if let startDateTS = startDate?.timeIntervalSince1970 {
                self.searchFilter.startTimeStamp = Int64(startDateTS)
            } else {
                self.searchFilter.startTimeStamp = nil
            }
            if let endDateTS = endDate?.timeIntervalSince1970 {
                self.searchFilter.endTimeStamp = Int64(endDateTS)
            } else {
                self.searchFilter.endTimeStamp = nil
            }
            self.search()
        }
        self.present(vc, animated: false)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
}

extension CalendarSearchViewController: SearchMeetingRoomFilterableControllerDelegate {

    func didUnselectMeetingRoom(from: SearchMeetingRoomFilterableController) {
        self.meetingRoomFilter?.setText(BundleI18n.Calendar.Calendar_Edit_Room)
        self.meetingRoomFilter?.isActive = false
        self.searchFilter.resource = []
        self.filterView.set(filters: self.filters)
        self.navigationController?.popViewController(animated: true)
        self.search()
    }

    func didSelectMeetingRoom(_ meetingRoom: CalendarMeetingRoom, from: SearchMeetingRoomFilterableController) {
        self.meetingRoomFilter?.setText(meetingRoom.fullName)
        self.meetingRoomFilter?.isActive = true

        self.searchFilter.resource = [meetingRoom]
        self.filterView.set(filters: self.filters)
        self.navigationController?.popViewController(animated: true)
        self.search()
    }
}
