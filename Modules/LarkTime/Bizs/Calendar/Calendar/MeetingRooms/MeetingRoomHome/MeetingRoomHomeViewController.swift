//
//  MeetingRoomHomeViewController.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/5/6.
//

import UIKit
import LarkContainer
import LarkCompatible
import RxSwift
import RxCocoa
import LarkKeyboardKit
import LarkUIKit
import EENavigator
import CTFoundation
import LarkExtensions
import UniverseDesignToast
import LarkGuideUI
import LarkGuide
import UniverseDesignTheme
import UniverseDesignEmpty
import CalendarFoundation
import UniverseDesignLoading
import LarkActivityIndicatorView
import UniverseDesignColor
import SnapKit

class TableViewBottomLoadingMoreView: UIView {

    private let loadingView: UniverseDesignLoading.UDSpin

    init() {
        loadingView = UDLoading.presetSpin(
            color: .primary,
            loadingText: I18n.Calendar_Common_LoadingCommon,
            textDistribution: .horizonal
        )
        super.init(frame: .zero)
        addSubview(loadingView)

        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(44)
            make.top.equalToSuperview().offset(13)
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        loadingView.reset()
    }
}

final class MeetingRoomHomeViewController: UIViewController, UserResolverWrapper {

    private lazy var monthViewProvider: MonthViewProvider = {
        let settingProvider = SettingService.shared()
        let monthViewProvider = MonthViewProvider(date: Date(),
                                                  superView: view,
                                                  firstWeekday: settingProvider.getSetting().firstWeekday,
                                                  tableView: meetingRoomTableView,
                                                  alternateCalendar: settingProvider.getSetting().alternateCalendar ?? .noneCalendar,
                                                  width: view.bounds.width)
        monthViewProvider.delegate = self
        return monthViewProvider
    }()

    private lazy var filterView: MeetingRoomHomeFilterView = {
        let view = MeetingRoomHomeFilterView()
        view.viewData = MeetingRoomHomeViewModel.Filter()
        return view
    }()

    private var viewModel: MeetingRoomHomeViewModel
    private let bag = DisposeBag()
    private var firstFixedProviderWidth = false

    let userResolver: UserResolver

    @ScopedProvider private var newGuideManager: NewGuideService?
    @ScopedInjectedLazy private var pushService: RustPushService?
    @ScopedInjectedLazy private var meetingRoomHomeTracer: MeetingRoomHomeTracer?

    let throttler = Throttler(delay: 3, executeLast: true)

    private lazy var loadMoreView = TableViewBottomLoadingMoreView()

    private lazy var meetingRoomTableView: UITableView = {
        let table = UITableView(frame: .zero)
        table.register(MeetingRoomHomeTableViewCell.self, forCellReuseIdentifier: "cell")
        table.dataSource = self
        table.delegate = self
        table.rowHeight = 122
        table.estimatedRowHeight = 122
        table.contentInset.bottom = 80
        let emptyView = EmptyDataView(
            content: BundleI18n.Calendar.Calendar_MeetingRoom_NoMeetingRoomsEmptyState,
            placeholderImage: UDEmptyType.noSchedule.defaultImage().ud.resized(to: CGSize(width: 100, height: 100)))
        emptyView.useCenterConstraints = true
        table.lu.emptyDataView = emptyView
        table.tableFooterView = nil
        return table
    }()

    private var meetingRoomInstances = [MeetingRoomHomeViewModel.MeetingRoomInstances]() {
        didSet {
            meetingRoomTableView.reloadData()
            if meetingRoomInstances.isEmpty {
                meetingRoomTableView.lu.addEmptyDataViewIfNeeded { make in
                    make.centerX.equalToSuperview()
                    make.centerY.equalToSuperview().offset(-50)
                }
                meetingRoomTableView.separatorStyle = .none
            } else {
                meetingRoomTableView.lu.emptyDataView?.removeFromSuperview()
                meetingRoomTableView.separatorStyle = .singleLine
                meetingRoomTableView.isScrollEnabled = true
            }
        }
    }

    var selectedDateDidChange: ((Date) -> Void)?
    var calendarVCDependency: CalendarViewControllerDependency?

    var currentDate: Date {
        viewModel.selectedDateRelay.value
    }

    // filter views
    private lazy var capacityInputView = CapacityInputView()
    private lazy var equipmentSelectorView = EquipmentSelectorView()

    // 暂时只在多层级下启用
    private weak var multiLevelLoadingView: LoadingView?

    init(viewModel: MeetingRoomHomeViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let calView = monthViewProvider.view
        calView.frame.origin.y += 6

        view.addSubview(filterView)
        view.addSubview(calView)

        filterView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(calView.snp.bottom)
            make.height.equalTo(60)
        }

        view.addSubview(meetingRoomTableView)
        meetingRoomTableView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(filterView.snp.bottom)
        }

        #if !LARK_NO_DEBUG
        addDebugGesture()
        #endif

        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if firstFixedProviderWidth == false {
            // 因JTAppleCalendar + 非约束实现，width不准，需要首次布局时校准
            monthViewProvider.onWidthChange(width: view.bounds.size.width)
            firstFixedProviderWidth = true
        }
    }

    private func bind() {
        if viewModel.multiLevelResources {
            filterView.buildingTapped = { [weak self] in
                guard let self = self else { return }
                self.viewModel.resetInjectedRootLevel()
                let multiLevelVC = MeetingRoomHomeMultiLevelSelectionViewController(rootLevel: self.viewModel.rootLevelInjected?.subLevels.first ?? self.viewModel.rootLevelInjected,
                                                                                    selectedLevelIds: self.viewModel.selectedLevelIds, userResolver: self.userResolver)
                multiLevelVC.modalPresentationStyle = .overFullScreen
                self.present(multiLevelVC, animated: false)

                if let vc = multiLevelVC.multiSelectionVC {
                    multiLevelVC.confirmButton.rx.tap
                        .withLatestFrom(vc.rx.selectedLevelIds)
                        .subscribeForUI(onNext: { [weak self] levelIds in
                            self?.viewModel.multiLevelChangeFilter(selectedLevelIds: levelIds)
                        })
                        .disposed(by: self.bag)
                }
            }

            viewModel.rxHasMore
                .subscribeForUI(onNext: { [weak self] hasMore in
                    if hasMore {
                        self?.meetingRoomTableView.tableFooterView = self?.loadMoreView
                        self?.loadMoreView.reset()
                    } else {
                        self?.meetingRoomTableView.tableFooterView = nil
                    }
                })
                .disposed(by: self.bag)
        } else {
            filterView.buildingTapped = { [weak self] in
                guard let self = self else { return }
                let buildingSelectionVC = MeetingRoomBuildingSelectionViewController()
                if let buildingAndFloors = self.viewModel.selectedBuildingAndFloors {
                    buildingSelectionVC.selectedBuilding = buildingAndFloors.0
                    if case let .specifics(floors) = buildingAndFloors.1 {
                        buildingSelectionVC.selectedFloors = floors
                    } else {
                        buildingSelectionVC.selectedFloors = [MeetingRoomBuildingSelectionViewController.allFloorsStr]
                    }
                }
                buildingSelectionVC.buildings = self.viewModel.allBuildings

                buildingSelectionVC.didSelectBuildingAndFloors = { [weak self] building, selectedfloors in
                    guard let self = self else { return }
                    guard let building = building else {
                        return
                    }
                    if selectedfloors.contains(MeetingRoomBuildingSelectionViewController.allFloorsStr) {
                        self.viewModel.changeFilter(building: building, floors: .all)
                    } else {
                        self.viewModel.changeFilter(building: building, floors: .specifics(selectedfloors))
                    }
                    CalendarTracer.shared.meetingRoomViewActions(action: .changeBuilding)
                }
                let popUp = PopupViewController(rootViewController: buildingSelectionVC)
                popUp.shouldShowTopIndicatorInCompact = false
                self.present(popUp, animated: true)
            }
        }

        filterView.equipmentTapped = { [weak self] in
            guard let self = self else { return }

            let backgroundView = LarkUIKitExtension.getRootWindowByView(self.view) ?? self.view
            backgroundView?.addSubview(self.equipmentSelectorView)
            backgroundView?.bringSubviewToFront(self.equipmentSelectorView)
            self.equipmentSelectorView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            struct EquipmentSelectorViewData: EquipmentSelectorViewDataType {
                var _equipmentInfos: [(equipment: Rust.EquipmentExpand, isSelected: Bool)]
                var equipmentInfos: [(equipment: String, isSelected: Bool)] {
                    _equipmentInfos.map { ($0.equipment.equipment.i18NName, $0.isSelected) }
                }
            }
            self.equipmentSelectorView.viewData = EquipmentSelectorViewData(_equipmentInfos: self.viewModel.equipmentsWithSelection)
            backgroundView?.layoutIfNeeded()
            self.equipmentSelectorView.show()
        }

        filterView.capacityTapped = { [weak self] in
            guard let self = self else { return }

            let backgroundView = LarkUIKitExtension.getRootWindowByView(self.view) ?? self.view
            backgroundView?.addSubview(self.capacityInputView)
            backgroundView?.bringSubviewToFront(self.capacityInputView)
            self.capacityInputView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            self.capacityInputView.isHidden = false
            self.capacityInputView.beginEdit(capacity: self.filterView.viewData?.capacity)
        }

        capacityInputView.confirmTapped = { [weak self] input in
            self?.viewModel.changeFilter(capacity: input)
            CalendarTracer.shared.meetingRoomViewActions(action: .changeCapacity)
        }

        equipmentSelectorView.equipmentTapped = { [weak self] indices in
            guard let self = self else { return }
            let equipments = indices.map { self.viewModel.equipmentsWithSelection[$0].0.id }
            self.viewModel.changeFilter(equipments: equipments)
            CalendarTracer.shared.meetingRoomViewActions(action: .changeEquipment)
        }

        filterView.refreshTapped = { [weak self] in
            self?.refreshAll { [weak self] in
                guard let self = self else { return }
                UDToast.showLoading(with: BundleI18n.Calendar.Calendar_MeetingRoom_Refreshing, on: self.view)
            }
        }

        viewModel.filterDriver.drive(onNext: { [weak self] filter in
            guard let self = self else { return }
            self.filterView.viewData = filter
        })
        .disposed(by: bag)

        viewModel.meetingRoomsDriver.drive(onNext: { [weak self] meetingRooms in
            guard let self = self else { return }
            self.meetingRoomInstances = meetingRooms
        })
        .disposed(by: bag)

        if viewModel.multiLevelResources {
            viewModel.meetingRoomsDriver.asObservable()
                .filter { !$0.isEmpty }
                .timeout(.seconds(15), scheduler: MainScheduler.instance)
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self] _ in
                    self?.multiLevelLoadingView?.hideSelf()
                }
                .disposed(by: bag)
        }

        viewModel.meetingRoomInstanceUpdateRelay
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] instances in
                guard let self = self else { return }
                var indices = [Int]()
                instances.forEach { instance in
                    if let index = self.meetingRoomInstances.firstIndex(where: { instance.meetingRoom == $0.meetingRoom }) {
                        indices.append(index)
                        self.meetingRoomInstances[index] = instance
                    }
                }
                self.meetingRoomTableView.reloadRows(at: indices.map { IndexPath(row: $0, section: 0) }, with: .none)

                if self.view.subviews.last(where: { $0 is RoundedView }) != nil {
                    UDToast.showSuccess(with: BundleI18n.Calendar.Calendar_MeetingRoom_Refreshed, on: self.view)
                }
            })
            .disposed(by: bag)
        viewModel.meetingRoomInstanceUpdateFailedRelay
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                if self.view.subviews.last(where: { $0 is RoundedView }) != nil {
                    UDToast.showFailure(with: BundleI18n.Calendar.Calendar_MeetingRoom_UnableToRefresh, on: self.view)
                }
            })
            .disposed(by: bag)

        viewModel.currentTimeRelay.asDriver().drive(onNext: { [weak self] time in
            guard let self = self, self.viewModel.selectedDateRelay.value.isInToday else { return }
            (self.meetingRoomTableView.visibleCells as? [MeetingRoomHomeTableViewCell])?.forEach { $0.currentTime = time }
        })
        .disposed(by: bag)

        pushService?.rxMeetingRoomInstanceChanged
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] calendarIDs in
                calendarIDs
                    .compactMap { id in
                        self?.meetingRoomInstances.first(where: { $0.meetingRoom.calendarID == id })?.meetingRoom
                    }
                    .forEach {
                        self?.viewModel.loadInstances(meetingRoomID: $0, ignoreCache: true)
                    }
            })
            .disposed(by: bag)

        NotificationCenter.default.rx.notification(UIDevice.orientationDidChangeNotification)
            .delay(.milliseconds(100), scheduler: MainScheduler.instance)
            .subscribeForUI(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.monthViewProvider.onWidthChange(width: self.view.bounds.width)
            })
            .disposed(by: bag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if viewModel.multiLevelResources
            && multiLevelLoadingView == nil
            && meetingRoomInstances.isEmpty {
            let loadingView = LoadingView(displayedView: view)
            loadingView.backgroundColor = UIColor.ud.commonBackgroundColor
            loadingView.showLoading()
            multiLevelLoadingView = loadingView
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let rootView = view.window?.rootViewController?.viewIfLoaded {
            KeyboardKit.shared.keyboardHeightChange(for: rootView)
                .debounce(.milliseconds(50))
                .drive(onNext: { [weak self] height in
                    guard let self = self else { return }
                    UIView.animate(withDuration: 0.3) {
                        self.capacityInputView.transform = CGAffineTransform(translationX: 0, y: -height)
                    }
                })
                .disposed(by: self.bag)
        }

        selectedDateDidChange?(viewModel.selectedDateRelay.value)

        monthViewProvider.onWidthChange(width: view.bounds.width)

        showBuildingGuideIfNeeded(targetView: filterView.buildingItem)

        viewModel.updateSDKFilterIfNeededOnAppear()?.subscribe(onNext: { [weak self] _ in
            self?.refreshAll()
        }).disposed(by: bag)

        refreshAll()
        CalendarTracer.shared.showMeetingRoomView()
    }

    func refreshAll(success: (() -> Void)? = nil) {
        throttler.call { [weak self] in
            guard let self = self else { return }
            if let indexPaths = self.meetingRoomTableView.indexPathsForVisibleRows {
                indexPaths.map(\.row)
                    .map { self.meetingRoomInstances[$0].meetingRoom }
                    .forEach { self.viewModel.loadInstances(meetingRoomID: $0, ignoreCache: true) }
                if !indexPaths.isEmpty {
                    success?()
                }
            }
        }
    }

    // 对外暴露的改变当前日期接口
    func changeSelectedDate(date: Date) {
        monthViewProvider.selectDate(date: date)
        monthViewProvider.reloadData()
    }

    private func showBuildingGuideIfNeeded(targetView: UIView) {

        // 创建单个气泡的配置
        let guideKey = "all_calendar_tab_findrooms_building"
        let bubbleConfig = BubbleItemConfig(
            guideAnchor: TargetAnchor(targetSourceType: .targetView(targetView)),
            textConfig: TextInfoConfig(detail: BundleI18n.Calendar.Calendar_MeetingRoom_FindRoomOnboardingTwo)
        )
        let singleBubbleConfig = SingleBubbleConfig(delegate: self, bubbleConfig: bubbleConfig)
        newGuideManager?.showBubbleGuideIfNeeded(guideKey: guideKey, bubbleType: .single(singleBubbleConfig), dismissHandler: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MeetingRoomHomeViewController: GuideSingleBubbleDelegate {
    func didClickLeftButton(bubbleView: GuideBubbleView) {
        self.newGuideManager?.closeCurrentGuideUIIfNeeded()
    }

    func didClickRightButton(bubbleView: GuideBubbleView) {
        self.newGuideManager?.closeCurrentGuideUIIfNeeded()
    }

    func didTapBubbleView(bubbleView: GuideBubbleView) {
        self.newGuideManager?.closeCurrentGuideUIIfNeeded()
    }
}

// MARK: - UITableViewDataSource
extension MeetingRoomHomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        meetingRoomInstances.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MeetingRoomHomeTableViewCell

        let room = meetingRoomInstances[indexPath.row].meetingRoom
        if room.displayType == .hierarchical, room.resourceNameWithLevelInfo.count == 2 {
            cell.title = room.resourceNameWithLevelInfo[0]
            cell.pathName = room.resourceNameWithLevelInfo[1]
        } else {
            cell.title = room.floorName.isEmpty ? room.name : "\(room.floorName)-\(room.name)"
            cell.pathName = ""
        }
        cell.needApproval = room.needsApproval
        cell.capacity = room.capacity
        cell.equipment = room.equipments.map(\.i18NName).joined(separator: "·")

        let instances = meetingRoomInstances[indexPath.row].instances

        switch instances {
        case .loading:
            cell.instances = []
        case let .some(ins):
            cell.instances = ins.compactMap { ins in
                let referenceDate = self.viewModel.selectedDateRelay.value

                let startDate = max(referenceDate.dayStart(), Date(timeIntervalSince1970: TimeInterval(ins.startTime)))
                let endDate = min(referenceDate.dayEnd(), Date(timeIntervalSince1970: TimeInterval(ins.endTime)))

                var cal = Calendar.gregorianCalendar
                cal.timeZone = TimeZone.current

                var startHour = Double(cal.component(.hour, from: startDate))
                startHour += Double(cal.component(.minute, from: startDate)) / 60

                var endHour = Double(cal.component(.hour, from: endDate))
                endHour += Double(cal.component(.minute, from: endDate)) / 60

                return MeetingRoomDayInstancesView.SimpleInstance(startTime: startHour, endTime: endHour, editable: ins.isEditable)
            }
        }
        if viewModel.selectedDateRelay.value.isInToday {
            cell.currentTime = viewModel.currentTimeRelay.value
        }

        meetingRoomHomeTracer?.renderFinish()

        return cell
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension MeetingRoomHomeViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.map { meetingRoomInstances[$0.row] }
            .forEach {
                viewModel.loadInstances(meetingRoomID: $0.meetingRoom)
            }
    }
}

// MARK: - UITableViewDelegate
extension MeetingRoomHomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let meetingRoom = meetingRoomInstances[indexPath.row].meetingRoom

        var buildingName = ""
        if let buildingAndFloors = viewModel.selectedBuildingAndFloors,
           buildingAndFloors.0.id == meetingRoom.buildingID {
            buildingName = buildingAndFloors.0.name
        }
        var body = CalendarCreateEventBody(meetingRoom: [(meetingRoom, buildingName, "")])
        body.attendees = [.meWithMeetingRoom(meetingRoom: meetingRoom)]
        body.perferredScene = .freebusy
        body.startDate = viewModel.selectedDateRelay.value

        CalendarTracer.shared.meetingRoomViewActions(action: .resourceDetail(meetingRoomCalendarID: meetingRoom.calendarID))

        self.userResolver.navigator.present(body: body, from: self, prepare: { vc in
            vc.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        })
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.loadInstances(meetingRoomID: meetingRoomInstances[indexPath.row].meetingRoom)
        if viewModel.multiLevelResources,
           indexPath.section == 0 && indexPath.row == meetingRoomInstances.count - 1 {
            if meetingRoomInstances.count >= 500 {
                UDToast.showTips(with: I18n.Calendar_Room_NumberRoomsMax, on: self.view)
            } else {
                self.viewModel.loadMoreHierarchicalRoomViewResourceList()
            }
        }
    }
}

// MARK: - MonthViewDelegate
extension MeetingRoomHomeViewController: MonthViewDelegate {
    func monthViewProvider(_ monthViewProvider: MonthViewProvider, didSelectedDate date: Date) {
        selectedDateDidChange?(date)
        viewModel.selectedDateRelay.accept(date)
        meetingRoomInstances = meetingRoomInstances.map {
            var instance = $0
            instance.instances = .loading
            return instance
        }
        CalendarTracer.shared.meetingRoomViewActions(action: .changeDate)
        meetingRoomTableView.reloadData()
    }

    func monthViewProvider(_ monthViewProvider: MonthViewProvider, cellForItemAt date: Date) -> [UIColor] {
        []
    }
}

#if !LARK_NO_DEBUG
// MARK: 会议室主视图便捷调试
extension MeetingRoomHomeViewController: ConvenientDebug {
    func addDebugGesture() {
        guard FG.canDebug else { return }
        self.meetingRoomTableView.rx.gesture(Factory<UILongPressGestureRecognizer> { _, _ in })
            .when([.began])
            .subscribe(onNext: { [weak self] recognizer in
                guard let self = self else { return }
                let location = recognizer.location(in: self.meetingRoomTableView)
                if let index = self.meetingRoomTableView.indexPathForRow(at: location) {
                    let room = self.meetingRoomInstances[index.row].meetingRoom
                    self.showInfo(info: room.debugDescription, in: self)
                }
            })
            .disposed(by: self.bag)
    }
}
#endif
