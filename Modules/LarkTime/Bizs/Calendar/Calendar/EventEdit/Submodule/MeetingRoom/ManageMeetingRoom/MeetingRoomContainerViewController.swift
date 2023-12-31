//
//  MeetingRoomContainerViewController.swift
//  Calendar
//
//  Created by zhuheng on 2021/1/22.
//

import Foundation
import UIKit
import Swinject
import RxSwift
import RxCocoa
import LarkUIKit
import LarkContainer
import LKCommonsLogging
import UniverseDesignTabs
import UniverseDesignInput
import UniverseDesignIcon
import LarkKeyboardKit
import UniverseDesignToast
import UniverseDesignCheckBox

/// 会议室选择页面
extension MeetingRoomContainerViewController {
    static let logger = Logger.log(MeetingRoomContainerViewController.self, category: "calendar.edit.meetingRoom")
}

enum MeetingRoomActionSource: String { // 用于埋点
    case fullEventEditor = "full_event_editor"
    case calSubscribe = "cal_subscribe"
    case searchMeeting = "search_meeting"
}

protocol MeetingRoomContainerViewControllerDelegate: AnyObject {
    func didCancelEditMeetingRoom(from viewController: MeetingRoomContainerViewController)

    func didSelectMeetingRooms(_ meetingRooms: [CalendarMeetingRoom], from viewController: UIViewController)

    func didSelectMeetingRoomDetail(_ resourceID: String, from viewController: UIViewController)
    // 一键调整被点击
    func autoJustTimeTapped(needRenewalReminder: Bool, rrule: EventRecurrenceRule?)
}
final class MeetingRoomContainerViewController: UIViewController, UserResolverWrapper {
    private typealias UIStyle = EventEditUIStyle
    private lazy var searchTextField = initSearchTextField()
    private lazy var loadingView = initLoadingView()
    private lazy var faildView = initFaildView()
    private let filterView = MeetingRoomFilterView()
    private lazy var classifyTitleView = initClassifyTitleView()
    var editType: EventEditViewController.EditType = .new
    var actionSource: MeetingRoomActionSource = .fullEventEditor // 埋点
    private lazy var buildingContainerView: UDTabsListContainerView = {
        return UDTabsListContainerView(dataSource: self)
    }()
    private lazy var modules = (
        allMeetingRoom: initAllMeetingRoomModule(),
        enableMeetingRoom: initEnableMeetingRoomModule(),
        searchMeetingRoom: initSearchMeetingRoomModule()
    )
    private lazy var capacityInputView = CapacityInputView()
    private let equipmentSelectorView = EquipmentSelectorView()
    private let rxHideUnavailable = BehaviorRelay(value: true)
    private let rxQuery = BehaviorRelay(value: "")

    private let viewModel: MeetingRoomContainerViewModel
    private let selectedMeetingRooms: [CalendarMeetingRoom]

    private let meetingRoomApi: CalendarRustAPI?
    private let disposeBag = DisposeBag()

    weak var delegate: MeetingRoomContainerViewControllerDelegate?

    let userResolver: UserResolver

    init(userResolver: UserResolver,
         viewModel: MeetingRoomContainerViewModel,
         selectedMeetingRooms: [CalendarMeetingRoom],
         meetingRoomApi: CalendarRustAPI?) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.selectedMeetingRooms = selectedMeetingRooms
        self.meetingRoomApi = meetingRoomApi
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()

        observekeyboard()

        bindViewData()
        bindViewAction()

        viewModel.loadBuilding()
        viewModel.loadEquipment()

        if #available(iOS 13.0, *) {
            parent?.isModalInPresentation = true
        }
    }

    private func observekeyboard() {
        KeyboardKit.shared.keyboardHeightChange(for: self.view).debounce(0.03).drive(onNext: { [weak self] (height) in
            guard let self = self, self.capacityInputView.superview != nil else { return }
            self.capacityInputView.snp.updateConstraints {
                $0.bottom.equalToSuperview().offset(-height)
            }
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }).disposed(by: disposeBag)

    }

    private func bindViewData() {
        viewModel.rxViewState.bind { [weak self] (state) in
            guard let self = self else { return }
            switch state {
            case .loading:
                self.loadingView.isHidden = false
                self.view.bringSubviewToFront(self.loadingView)
            case .buildingData:
                self.buildingContainerView.isHidden = false
                self.view.bringSubviewToFront(self.buildingContainerView)
            case .failed:
                self.faildView.isHidden = false
                self.view.bringSubviewToFront(self.faildView)
            }
        }.disposed(by: disposeBag)

        viewModel.rxNavigationState.bind { [weak self] state in
            guard let self = self else { return }
            var navigationManageVC: UIViewController = self
            if let parent = self.parent { navigationManageVC = parent }
            switch state {
            case .normal:
                navigationManageVC.navigationItem.leftBarButtonItem = self.cancelBarItem
            case .normalMultiSelect:
                navigationManageVC.navigationItem.leftBarButtonItem = self.cancelBarItem
                navigationManageVC.navigationItem.rightBarButtonItem = self.multiBarItem
            case let .multiSelecting(number):
                navigationManageVC.navigationItem.leftBarButtonItem = self.multiCancelBarItem
                navigationManageVC.navigationItem.rightBarButtonItem = self.multiConfirmBarItem
                let atLeastOne = number > 0
                let buttonTitle = BundleI18n.Calendar.Calendar_Common_Confirm + (atLeastOne ? "(\(number))" : "")
                self.multiConfirmBarItem.resetTitle(title: buttonTitle)
                self.multiConfirmBarItem.isEnabled = atLeastOne
            }
        }.disposed(by: disposeBag)

        viewModel.rxNavigationState
            .map { $0.isMultiSelecting }
            .bind { [weak self] multiSelecting in
                guard let self = self else { return }
                self.selectAllView.isHidden = !multiSelecting
                self.selectAllView.snp.updateConstraints {
                    $0.height.equalTo(multiSelecting ? self.view.safeAreaInsets.bottom + 44 : 0)
                }
            }.disposed(by: disposeBag)

        viewModel.rxSelectAll.bind { [weak self] type in
            self?.selectAllView.selectType = type
        }.disposed(by: disposeBag)

        viewModel.rxLoading.bind { [weak self] item in
            guard let self = self else { return }
            switch item {
            case .none: UDToast.removeToast(on: self.view)
            case .loading(let text): UDToast.showLoading(with: text, on: self.view, disableUserInteraction: true)
            case .failed(let text): UDToast.showFailure(with: text, on: self.view)
            }
        }.disposed(by: disposeBag)

        viewModel.rxMultiSelectConfirm.bind { [weak self] meetingRooms in
            guard let self = self else { return }
            self.delegate?.didSelectMeetingRooms(meetingRooms, from: self)
        }.disposed(by: disposeBag)

        viewModel.rxMeetingRoomFilterViewData.bind(to: filterView).disposed(by: disposeBag)
        viewModel.rxEquipmentListViewData.bind(to: equipmentSelectorView).disposed(by: disposeBag)

        // 会议室多层级
        viewModel.rxMultiLevelSelectedMeetingRooms
            .map { meetingRooms in
                meetingRooms.map {
                    CalendarMeetingRoom.makeMeetingRoom(fromResource: $0, buildingName: "", tenantId: "")
                }
            }
            .bind { [weak self] meetingRooms in
                guard let self = self else { return }
                self.delegate?.didSelectMeetingRooms(meetingRooms, from: self)
            }
            .disposed(by: disposeBag)

        viewModel.onFilterReset = { [weak self] in
            guard let self = self else { return }
            self.equipmentSelectorView.reset()
            self.capacityInputView.reset()
        }
    }

    private func bindViewAction() {
        equipmentSelectorView.equipmentTapped = { [weak self] (selectedIndexs) in
            guard let self = self else { return }
            self.viewModel.updateNeededEquipments(with: selectedIndexs)
        }

        capacityInputView.confirmTapped = { [weak self] (minCapacity) in
            guard let self = self else { return }
            self.viewModel.updateMiniCapacity(with: minCapacity)
        }

        searchTextField.rx.text.map {
            let text = $0 ?? ""
            return text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }.bind(to: rxQuery)
        .disposed(by: disposeBag)

        filterView.equipmentTapped = { [weak self] in
            guard let self = self else { return }
            self.equipmentSelectorView.isHidden = false
            let backgroundView: UIView = self.navigationController?.view ?? self.view
            backgroundView.bringSubviewToFront(self.equipmentSelectorView)
            if self.searchTextField.canResignFirstResponder {
                self.searchTextField.resignFirstResponder()
            }
            self.equipmentSelectorView.show()
            CalendarTracer.shared.calMeetingRoomFilterTapped(actionSource: self.actionSource.rawValue, editType: self.editType.rawValue)
        }

        filterView.capacityTapped = { [weak self] in
            guard let self = self else { return }
            self.capacityInputView.isHidden = false
            let backgroundView: UIView = self.navigationController?.view ?? self.view
            backgroundView.bringSubviewToFront(self.capacityInputView)
            self.capacityInputView.beginEdit(capacity: self.filterView.viewData?.capacity)
            CalendarTracer.shared.calMeetingRoomFilterTapped(actionSource: self.actionSource.rawValue, editType: self.editType.rawValue)
        }

        filterView.availableRoomsTapped = {[weak self] in
            guard let self = self else { return }
            self.viewModel.toggleAvailableRoomsOnly()
        }

        filterView.resetTapped = { [weak self] in
            guard let self = self else { return }
            self.viewModel.resetFilter()
        }

    }

    private func setupView() {
        view.backgroundColor = .ud.bgBody

        view.addSubview(searchTextField)
        searchTextField.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(36)
        }

        view.addSubview(filterView)
        filterView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.height.equalTo(56)
            $0.top.equalTo(searchTextField.snp.bottom).offset(8)
        }

        // 添加分割view
        let separator = UIView()
        separator.backgroundColor = .ud.bgBase
        view.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.top.equalTo(filterView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(8)
        }

        if viewModel.multiLevelResources {
            var config = MeetingRoomMultiLevelSelectionViewController.Config(showLevelsOnly: false,
                                                                             alwaysShowLevelIndicator: false,
                                                                             source: .addMeeting,
                                                                             startDate: viewModel.startDate ?? Date(),
                                                                             endDate: viewModel.endDate ?? Date(),
                                                                             rrule: viewModel.rrule,
                                                                             showDisabledMeetingRooms: false)
            config.rxEquipments = viewModel.rxNeedEquipments
            config.rxMinCapacity = viewModel.rxMinCapacity
            config.rxAvailableRoomsOnly = viewModel.rxAvailableRoomsOnly
            config.eventConditions = viewModel.eventConditions
            config.meetingRoomWithFormUnAvaliableReason = viewModel.meetingRoomWithFormUnAvailableReason
            config.eventParam = viewModel.eventParam
            config.endDate = viewModel.endDate
            config.endDateEditable = viewModel.endDateEditable
            let multiLevelVC = MeetingRoomMultiLevelSelectionViewController(config: config, userResolver: self.userResolver)

            addChild(multiLevelVC)
            view.addSubview(multiLevelVC.view)
            multiLevelVC.view.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(separator.snp.bottom)
            }
            multiLevelVC.didMove(toParent: self)

            multiLevelVC.rx.selectedMeetingRooms
                .sample(viewModel.rxMultiLevelSelectionConfirmed)
                .bind(to: viewModel.rxMultiLevelSelectedMeetingRooms)
                .disposed(by: disposeBag)

            multiLevelVC.rx.autoJustTimeTappedOb
                .throttle(.milliseconds(200), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (value, rrule) in
                    guard let self = self else { return }
                    self.delegate?.autoJustTimeTapped(needRenewalReminder: value, rrule: rrule)
                })
                .disposed(by: disposeBag)

            multiLevelVC.rx.selectedMeetingRooms
                .withLatestFrom(viewModel.rxIsMultiSelect) { return ($0, $1) }
                .subscribeForUI { [weak self] meetingRoomSelected, isMultiSelect in
                    if !isMultiSelect {
                        guard meetingRoomSelected.count == 1 else {
                            return
                        }
                        self?.viewModel.rxMultiLevelSelectionConfirmed.onNext(())
                    }
                }
                .disposed(by: disposeBag)

            viewModel.rxIsMultiSelect
                .distinctUntilChanged()
                .throttle(.milliseconds(200), scheduler: MainScheduler.instance)
                .bind(to: multiLevelVC.isMultiSelectActive)
                .disposed(by: disposeBag)

            let selectedCount = multiLevelVC.rx.selectedMeetingRooms
                .map(\.count)
                .startWith(0)
            selectedCount
                .map { $0 == 0 ? BundleI18n.Calendar.Calendar_Common_Confirm : BundleI18n.Calendar.Calendar_Common_Confirm + "(\($0))" }
                .subscribeForUI(onNext: { [weak self] title in
                    guard let self = self else { return }
                    self.multiConfirmBarItem.resetTitle(title: title)
                })
                .disposed(by: disposeBag)
            selectedCount
                .map { $0 > 0 }
                .bind(to: multiConfirmBarItem.rx.isEnabled)
                .disposed(by: disposeBag)

            addChild(modules.searchMeetingRoom)
            view.addSubview(modules.searchMeetingRoom.view)
            modules.searchMeetingRoom.view.snp.makeConstraints { $0.edges.equalTo(multiLevelVC.view) }
            modules.searchMeetingRoom.didMove(toParent: self)
            modules.searchMeetingRoom.view.isHidden = true

            view.addSubview(loadingView)
            loadingView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            loadingView.isHidden = false

            multiLevelVC.rx.currentLevel
                .subscribeForUI(onNext: { [weak loadingView] _ in
                    loadingView?.removeFromSuperview()
                })
                .disposed(by: disposeBag)
        } else {
            view.addSubview(classifyTitleView)
            classifyTitleView.snp.makeConstraints {
                $0.left.right.equalToSuperview()
                $0.height.equalTo(40)
                $0.top.equalTo(separator.snp.bottom)
            }

            view.addSubview(selectAllView)
            selectAllView.snp.makeConstraints {
                $0.leading.trailing.bottom.equalToSuperview()
                $0.height.equalTo(view.safeAreaInsets.bottom + 44)
            }

            classifyTitleView.listContainer = buildingContainerView
            view.addSubview(buildingContainerView)
            buildingContainerView.snp.makeConstraints {
                $0.top.equalTo(classifyTitleView.snp.bottom)
                $0.left.right.equalToSuperview()
                $0.bottom.equalTo(selectAllView.snp.top)
            }

            view.addSubview(loadingView)
            loadingView.snp.makeConstraints {
                $0.edges.equalTo(buildingContainerView)
            }

            view.addSubview(faildView)
            faildView.snp.makeConstraints {
                $0.edges.equalTo(buildingContainerView)
            }

            addChild(modules.searchMeetingRoom)
            modules.searchMeetingRoom.didMove(toParent: self)
            buildingContainerView.addSubview(modules.searchMeetingRoom.view)
            modules.searchMeetingRoom.view.snp.makeConstraints { $0.edges.equalToSuperview() }
            modules.searchMeetingRoom.view.isHidden = true
            view.bringSubviewToFront(selectAllView)
        }

        let backgroundView: UIView = navigationController?.view ?? view
        backgroundView.addSubview(equipmentSelectorView)
        equipmentSelectorView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        equipmentSelectorView.isHidden = true

        backgroundView.addSubview(capacityInputView)
        capacityInputView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        capacityInputView.isHidden = true
    }

    // MARK: - Lazy View
    private lazy var cancelBarItem: LKBarButtonItem = {
        let cancelItem = LKBarButtonItem(
            title: BundleI18n.Calendar.Calendar_Common_Cancel
        )
        cancelItem.button.rx.tap
            .bind { [weak self] in
                guard let self = self else { return }
                self.delegate?.didCancelEditMeetingRoom(from: self)
            }
            .disposed(by: disposeBag)
        return cancelItem
    }()

    private lazy var multiBarItem: LKBarButtonItem = {
        let multiSelectItem = LKBarButtonItem()
        // 目前端上通过 disable 规避，未来由 admin 强绑定 isOneMost 和 多选设置 Todo by @蒋雨
        let isOneMost = SettingService.shared().tenantSetting?.resourceSubscribeCondition.oneMostPerEvent ?? false
        multiSelectItem.resetTitle(title: BundleI18n.Calendar.Calendar_Common_Multi, font: UIFont.ud.headline(.fixed))
        multiSelectItem.setBtnColor(color: isOneMost ? UIColor.ud.textDisabled : UIColor.ud.textTitle)
        multiSelectItem.isEnabled = !isOneMost
        multiSelectItem.button.rx.tap
            .bind { [weak self] in
                guard let self = self else { return }
                self.viewModel.tapAction(.multiSelect)
            }
            .disposed(by: disposeBag)
        return multiSelectItem
    }()

    private lazy var multiCancelBarItem: LKBarButtonItem = {
        let multiCancelItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Cancel)
        multiCancelItem.setBtnColor(color: UIColor.ud.textTitle)
        multiCancelItem.button.rx.tap
            .bind { [weak self] in
                guard let self = self else { return }
                self.viewModel.tapAction(.multiSelectCancel)
            }
            .disposed(by: disposeBag)
        return multiCancelItem
    }()

    private lazy var multiConfirmBarItem: LKBarButtonItem = {
        let multiConfirmItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Confirm)
        multiConfirmItem.setBtnColor(color: UIColor.ud.primaryContentDefault)
        multiConfirmItem.button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        multiConfirmItem.button.rx.tap
            .bind { [weak self] in
                guard let self = self else { return }
                self.viewModel.tapAction(.multiSelectConfirm)
            }
            .disposed(by: disposeBag)
        return multiConfirmItem
    }()

    private lazy var selectAllView: SelectAllView = {
        let view = SelectAllView(frame: .zero) { [weak self] in
            self?.viewModel.toggleSelectAll()
        }
        return view
    }()
}

extension MeetingRoomContainerViewController: UDTabsViewDelegate {
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        rxHideUnavailable.accept(index == 0)
    }
}

extension MeetingRoomContainerViewController: UDTabsListContainerViewDataSource {
    func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
        return 2
    }

    func listContainerView(_ listContainerView: UDTabsListContainerView, initListAt index: Int) -> UDTabsListContainerViewDelegate {
        if index == 0 {
            return modules.enableMeetingRoom
        } else {
            return modules.allMeetingRoom
        }
    }
}
extension MeetingRoomContainerViewController {
    func initLoadingView() -> LoadingPlaceholderView {
        let loadingView = LoadingPlaceholderView()
        loadingView.backgroundColor = UIColor.ud.bgBody
        loadingView.isHidden = true
        loadingView.text = BundleI18n.Calendar.Calendar_Common_LoadingCommon
        return loadingView
    }

    func initFaildView() -> LoadingPlaceholderView {
        let faildView = LoadFaildRetryView()
        faildView.backgroundColor = UIColor.ud.bgBody
        faildView.isHidden = true
        faildView.retryAction = { [weak self] in
            self?.viewModel.loadBuilding()
        }
        return faildView
    }

    func initSearchTextField() -> SearchTextField {
        let textField = SearchTextField()
        textField.layer.cornerRadius = 8
        textField.layer.masksToBounds = true
        let placeholder = NSAttributedString(string: BundleI18n.Calendar.Calendar_EventSearch_SearchRoom, attributes: [.foregroundColor: UIColor.ud.textPlaceholder])
        textField.attributedPlaceholder = placeholder
        return textField
    }

    private func initSearchMeetingRoomModule() -> UIViewController {
        let selectedMeetingRoomIDs = Set(selectedMeetingRooms.map { $0.uniqueId })
        let vm = MeetingRoomSearchViewModel(userResolver: self.userResolver,
                                            meetingRoomApi: meetingRoomApi,
                                            tenantId: viewModel.tenantID,
                                            startDate: viewModel.startDate,
                                            endDate: viewModel.endDate,
                                            rrule: viewModel.rrule,
                                            eventConditions: viewModel.eventConditions,
                                            meetingRoomWithFormDisableReason: viewModel.meetingRoomWithFormUnAvailableReason,
                                            multiLevelResources: viewModel.multiLevelResources,
                                            rxHideUnavailable: viewModel.multiLevelResources ? viewModel.rxAvailableRoomsOnly : rxHideUnavailable,
                                            rxQuery: rxQuery,
                                            rxNeedEquipments: viewModel.rxNeedEquipments,
                                            rxMinCapacity: viewModel.rxMinCapacity,
                                            filterMeetingRoomIds: selectedMeetingRoomIDs,
                                            scene: .add)
        let controller = MeetingRoomSearchViewController(viewModel: vm)
        controller.delegate = self
        return controller
    }

    private func initClassifyTitleView() -> UDTabsTitleView {
        let tabsView = UDTabsTitleView()
        tabsView.titles = [BundleI18n.Calendar.Calendar_Edit_AvaliableRooms, BundleI18n.Calendar.Calendar_Edit_AllRooms]
        let config = tabsView.getConfig()
        config.layoutStyle = .average
        config.itemSpacing = 0
        config.titleNormalColor = .ud.textCaption
        config.titleSelectedColor = .ud.primaryPri500
        config.titleNormalFont = UIFont.systemFont(ofSize: 14)
        config.contentEdgeInsetLeft = 0

        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorWidthIncrement = -20
        indicator.backgroundColor = .ud.primaryPri500
        tabsView.indicators = [indicator]
        tabsView.setConfig(config: config)
        tabsView.delegate = self
        tabsView.backgroundColor = UIColor.ud.bgBody
        tabsView.addBottomSepratorLine()
        return tabsView
    }

    private func initAllMeetingRoomModule() -> UDTabsListContainerViewDelegate {
        let vm = MeetingRoomFoldViewModel(userResolver: self.userResolver,
                                          meetingRoomApi: meetingRoomApi,
                                          startDate: viewModel.startDate ?? Date(),
                                          endDate: viewModel.endDate ?? Date(),
                                          timezone: viewModel.timezone,
                                          tenantId: viewModel.tenantID,
                                          hideUnavailable: false,
                                          rrule: viewModel.rrule,
                                          eventConditions: viewModel.eventConditions,
                                          meetingRoomWithFormDisableReason: viewModel.meetingRoomWithFormUnAvailableReason,
                                          rxNeedEquipments: viewModel.rxNeedEquipments,
                                          rxMinCapacity: viewModel.rxMinCapacity,
                                          rxBuildings: viewModel.rxBuildings,
                                          rxMultiSelectTrigger: viewModel.rxIsMultiSelect,
                                          rxBuildingSelectedMap: viewModel.rxBuildingSelectedMap,
                                          rxMeetingRoomSelectedMap: viewModel.rxMeetingRoomSelectedMap,
                                          rxAllMeetingRooms: viewModel.rxAllBuildings,
                                          rxSelectAll: viewModel.rxSelectAll)
        vm.endDateEditable = viewModel.endDateEditable
        vm.eventParam = viewModel.eventParam
        let controller = MeetingRoomFoldViewController(viewModel: vm, emptyHolderText: I18n.Calendar_Room_NoOneToFind)
        controller.delegate = self
        return controller
    }

    private func initEnableMeetingRoomModule() -> UDTabsListContainerViewDelegate {
        let vm = MeetingRoomFoldViewModel(userResolver: self.userResolver,
                                          meetingRoomApi: meetingRoomApi,
                                          startDate: viewModel.startDate ?? Date(),
                                          endDate: viewModel.endDate ?? Date(),
                                          timezone: viewModel.timezone,
                                          tenantId: viewModel.tenantID,
                                          hideUnavailable: true,
                                          rrule: viewModel.rrule,
                                          eventConditions: viewModel.eventConditions,
                                          meetingRoomWithFormDisableReason: viewModel.meetingRoomWithFormUnAvailableReason,
                                          rxNeedEquipments: viewModel.rxNeedEquipments,
                                          rxMinCapacity: viewModel.rxMinCapacity,
                                          rxBuildings: viewModel.rxBuildings,
                                          rxMultiSelectTrigger: viewModel.rxIsMultiSelect,
                                          rxBuildingSelectedMap: viewModel.rxBuildingSelectedMap,
                                          rxMeetingRoomSelectedMap: viewModel.rxMeetingRoomSelectedMap,
                                          rxAllMeetingRooms: viewModel.rxAllBuildings,
                                          rxSelectAll: viewModel.rxSelectAll)
        vm.eventParam = viewModel.eventParam
        vm.endDateEditable = viewModel.endDateEditable
        let controller = MeetingRoomFoldViewController(viewModel: vm, emptyHolderText: I18n.Calendar_Detail_NoAvailableRoomsFound)
        controller.delegate = self
        return controller
    }
}

extension MeetingRoomContainerViewController: MeetingRoomFoldViewControllerDelegate {
    func didSelectMeetingRooms(_ meetingRooms: [CalendarMeetingRoom], from viewController: MeetingRoomFoldViewController) {
        self.delegate?.didSelectMeetingRooms(meetingRooms, from: viewController)
    }

    func didSelectMeetingRoomDetail(_ resourceID: String, from viewController: MeetingRoomFoldViewController) {
        delegate?.didSelectMeetingRoomDetail(resourceID, from: viewController)
    }
    
    // 一键调整被点击
    func autoJustTimeTapped(needRenewalReminder: Bool, rrule: EventRecurrenceRule?) {
        delegate?.autoJustTimeTapped(needRenewalReminder: needRenewalReminder, rrule: rrule)
    }
}

extension MeetingRoomContainerViewController: MeetingRoomSearchViewControllerDelegate {
    func didSelectMeetingRoomDetail(_ resourceID: String, from viewController: MeetingRoomSearchViewController) {
        delegate?.didSelectMeetingRoomDetail(resourceID, from: viewController)
    }

    func didSelectMeetingRoom(_ meetingRoom: CalendarMeetingRoom, from viewController: MeetingRoomSearchViewController) {
        self.delegate?.didSelectMeetingRooms([meetingRoom], from: viewController)
    }

}

/// 全选View
extension MeetingRoomContainerViewController {
    final class SelectAllView: UIView {

        var selectType: SelectType {
            didSet {
                checkBox.isEnabled = selectType != .disabled
                checkBox.isSelected = selectType == .selected || selectType == .halfSelected
                checkBox.updateUIConfig(boxType: selectType.boxType, config: UDCheckBoxUIConfig())
            }
        }

        let toggleHandler: (() -> Void)?
        let bag = DisposeBag()

        init(frame: CGRect, toggleHandler: (() -> Void)?) {
            selectType = .nonSelected
            self.toggleHandler = toggleHandler
            super.init(frame: frame)
            layoutUI()
        }

        required init?(coder: NSCoder) {
            fatalError()
        }

        private let contentView = UIView()

        private func layoutUI() {

            backgroundColor = UIColor.ud.bgBody

            addSubview(contentView)
            checkBox.isUserInteractionEnabled = false
            contentView.addSubview(checkBox)

            contentView.snp.makeConstraints {
                $0.top.leading.trailing.equalToSuperview()
                $0.height.equalTo(44)
            }

            checkBox.snp.makeConstraints {
                $0.leading.equalTo(16)
                $0.centerY.equalToSuperview()
                $0.size.equalTo(CGSize(width: 20, height: 20))
            }

            addTopBorder()

            label.text = I18n.Calendar_Common_SelectAll
            label.textColor = .ud.textTitle
            label.font = UIFont.cd.font(ofSize: 14)
            contentView.addSubview(label)
            label.snp.makeConstraints { make in
                make.leading.equalTo(checkBox.snp.trailing).offset(8)
                make.centerY.equalToSuperview()
                make.trailing.lessThanOrEqualToSuperview()
            }

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggle))
            addGestureRecognizer(tapGesture)
        }

        @objc
        private func toggle() {
            toggleHandler?()
        }

        private let checkBox = UDCheckBox()
        private let label = UILabel()
    }
}

extension MeetingRoomMultiLevelSelectionViewController: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        view
    }
}
