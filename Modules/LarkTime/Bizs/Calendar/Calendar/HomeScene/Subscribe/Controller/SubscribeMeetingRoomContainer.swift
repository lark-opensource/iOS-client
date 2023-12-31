//
//  SubscribeMeetingRoomContainer.swift
//  Calendar
//
//  Created by zhuheng on 2021/2/15.
//

import UIKit
import Foundation
import RxCocoa
import LarkUIKit
import RxSwift
import LarkContainer
import LarkCompatible
import LarkKeyboardKit

final class SubscribeMeetingRoomContainer: SubscribeCalendarBase, UserResolverWrapper {
    private typealias UIStyle = EventEditUIStyle
    private lazy var faildView = initFaildView()
    private let filterView = MeetingRoomFilterView()
    var equipmentFilterClick: (() -> Void)?

    private lazy var modules = (
        allMeetingRoom: initAllMeetingRoomModule(),
        searchMeetingRoom: initSearchMeetingRoomModule()
    )
    private lazy var capacityInputView = CapacityInputView()
    private let equipmentSelectorView = EquipmentSelectorView()

    private let rxHideUnavailable = BehaviorRelay(value: false)
    private let rxQuery = BehaviorRelay(value: "")
    var actionSource: MeetingRoomActionSource = .calSubscribe
    private let viewModel: MeetingRoomContainerViewModel
    private let tenantID: String
    private let meetingRoomApi: CalendarRustAPI?

    override var searchText: String? {
        didSet {
            guard let searchText = searchText,
                  searchText != oldValue else { return }
            rxQuery.accept(searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
        }
    }

    let userResolver: UserResolver

    init(userResolver: UserResolver,
         viewModel: MeetingRoomContainerViewModel,
         meetingRoomApi: CalendarRustAPI?,
         tenantID: String) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.meetingRoomApi = meetingRoomApi
        self.tenantID = tenantID
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

        if !viewModel.multiLevelResources {
            viewModel.loadBuilding()
        } else {
            viewModel.rxViewState.accept(.buildingData)
        }
        viewModel.loadEquipment()
    }

    private func observekeyboard() {
        guard let superView = capacityInputView.superview else { return }
        KeyboardKit.shared.keyboardHeightChange(for: superView).debounce(0.03).drive(onNext: { [weak self] (height) in
            guard let self = self, self.capacityInputView.superview != nil else { return }
            self.capacityInputView.snp.updateConstraints {
                $0.bottom.equalToSuperview().offset(-height)
            }
            UIView.animate(withDuration: 0.3) {
                self.capacityInputView.superview?.layoutIfNeeded()
            }
        }).disposed(by: disposeBag)
    }

    private func bindViewData() {
        viewModel.rxViewState.bind { [weak self] (state) in
            guard let self = self else { return }
            switch state {
            case .loading:
                self.loadingView.isHidden = false
                self.filterView.isHidden = true
                self.modules.allMeetingRoom.view.isHidden = true
                self.view.bringSubviewToFront(self.loadingView)
                self.loadingView.show()
            case .buildingData:
                self.loadingView.hide()
                self.filterView.isHidden = false
                self.modules.allMeetingRoom.view.isHidden = false
                self.view.bringSubviewToFront(self.modules.allMeetingRoom.view)
            case .failed:
                self.loadingView.hide()
                self.filterView.isHidden = true
                self.faildView.isHidden = false
                self.view.bringSubviewToFront(self.faildView)
            }
        }.disposed(by: disposeBag)

        viewModel.rxMeetingRoomFilterViewData.bind(to: filterView).disposed(by: disposeBag)
        viewModel.rxEquipmentListViewData.bind(to: equipmentSelectorView).disposed(by: disposeBag)

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

        filterView.equipmentTapped = { [weak self] in
            guard let self = self else { return }
            self.equipmentFilterClick?()
            self.viewModel.loadEquipment()
            self.equipmentSelectorView.isHidden = false

            let backgroundView: UIView = self.navigationController?.view ?? self.view
            backgroundView.bringSubviewToFront(self.equipmentSelectorView)

            self.equipmentSelectorView.show()

            CalendarTracer.shared.calMeetingRoomFilterTapped(actionSource: self.actionSource.rawValue)
        }

        filterView.capacityTapped = { [weak self] in
            guard let self = self else { return }
            self.capacityInputView.isHidden = false

            let backgroundView: UIView = self.navigationController?.view ?? self.view
            backgroundView.bringSubviewToFront(self.capacityInputView)
            self.capacityInputView.beginEdit()

            CalendarTracer.shared.calMeetingRoomFilterTapped(actionSource: self.actionSource.rawValue)
        }

        filterView.resetTapped = { [weak self] in
            guard let self = self else { return }
            self.viewModel.resetFilter()
        }

    }

    private func setupView() {
        view.backgroundColor = UIStyle.Color.viewControllerBackground

        view.addSubview(filterView)
        filterView.snp.makeConstraints {
            $0.left.top.right.equalToSuperview()
            $0.height.equalTo(60)
        }

        addChild(modules.allMeetingRoom)
        modules.allMeetingRoom.didMove(toParent: self)

        view.addSubview(modules.allMeetingRoom.view)
        modules.allMeetingRoom.view.snp.makeConstraints {
            $0.top.equalTo(filterView.snp.bottom)
            $0.left.right.bottom.equalToSuperview()
        }

        view.addSubview(faildView)
        faildView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        addChild(modules.searchMeetingRoom)
        modules.allMeetingRoom.view.addSubview(modules.searchMeetingRoom.view)
        modules.searchMeetingRoom.didMove(toParent: self)
        modules.searchMeetingRoom.view.snp.makeConstraints { $0.edges.equalTo(modules.allMeetingRoom.view) }
        modules.searchMeetingRoom.view.isHidden = true

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

}

extension SubscribeMeetingRoomContainer {
    func initFaildView() -> LoadingPlaceholderView {
        let faildView = LoadFaildRetryView()
        faildView.backgroundColor = UIColor.ud.bgBody
        faildView.isHidden = true
        faildView.retryAction = { [weak self] in
            self?.viewModel.loadBuilding()
        }
        return faildView
    }

    private func initSearchMeetingRoomModule() -> UIViewController {
        let vm = MeetingRoomSearchViewModel(userResolver: self.userResolver,
                                            meetingRoomApi: meetingRoomApi,
                                            tenantId: tenantID,
                                            multiLevelResources: viewModel.multiLevelResources,
                                            rxHideUnavailable: rxHideUnavailable,
                                            rxQuery: rxQuery,
                                            rxNeedEquipments: viewModel.rxNeedEquipments,
                                            rxMinCapacity: viewModel.rxMinCapacity,
                                            scene: .subscribe)
        let controller = SubscribeMeetingRoomSearchViewController(viewModel: vm)
        controller.delegate = self
        return controller
    }

    /// 固定层级的所有会议室列表
    private func initFoldMeetingRoomVC() -> UIViewController {
        let vm = MeetingRoomFoldViewModel(userResolver: self.userResolver,
                                          meetingRoomApi: meetingRoomApi,
                                          tenantId: tenantID,
                                          hideUnavailable: false,
                                          rxNeedEquipments: viewModel.rxNeedEquipments,
                                          rxMinCapacity: viewModel.rxMinCapacity,
                                          rxBuildings: viewModel.rxBuildings,
                                          rxQuery: rxQuery)
        let controller = SubscribeMeetingRoomFoldViewController(viewModel: vm)
        controller.delegate = self
        return controller
    }

    /// 灵活层级的所有会议室列表
    private func initMultiLevelMeetingRoomVC() -> UIViewController {
        var config = MeetingRoomMultiLevelSelectionViewController.Config(showLevelsOnly: false,
                                                                         source: .subscribeMeeting,
                                                                         showDisabledMeetingRooms: true)
        config.rxEquipments = viewModel.rxNeedEquipments
        config.rxMinCapacity = viewModel.rxMinCapacity
        config.rxAvailableRoomsOnly = viewModel.rxAvailableRoomsOnly
       
        let vc = MeetingRoomMultiLevelSelectionViewController(config: config, userResolver: self.userResolver)
        return vc
    }

    private func initAllMeetingRoomModule() -> UIViewController {
        return self.viewModel.multiLevelResources ? initMultiLevelMeetingRoomVC() : initFoldMeetingRoomVC()
    }

    private func jumpToMeetingRoomDetail(resourceID: String) {
        CalendarTracer.shared.calClickMeetingRoomInfoFromSubscribe()
        var context = DetailOnlyContext()
        context.calendarID = resourceID
        let viewModel = MeetingRoomDetailViewModel(input: .detailOnly(context), userResolver: self.userResolver)
        let toVC = MeetingRoomDetailViewController(viewModel: viewModel, userResolver: self.userResolver)
        if Display.pad {
            let navigation = LkNavigationController(rootViewController: toVC)
            navigation.modalPresentationStyle = .formSheet
            navigationController?.present(navigation, animated: true, completion: nil)
        } else {
            navigationController?.pushViewController(toVC, animated: true)
        }
    }
}

extension SubscribeMeetingRoomContainer: SubscribeMeetingRoomSearchViewControllerDelegate {
    func didSelectMeetingRoomDetail(_ resourceID: String, from viewController: SubscribeMeetingRoomSearchViewController) {
        jumpToMeetingRoomDetail(resourceID: resourceID)
    }
}

extension SubscribeMeetingRoomContainer: SubscribeMeetingRoomFoldViewControllerDelegate {
    func didSelectMeetingRoomDetail(_ resourceID: String, from viewController: SubscribeMeetingRoomFoldViewController) {
        jumpToMeetingRoomDetail(resourceID: resourceID)
    }
}
