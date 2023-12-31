//
//  SearchMeetingRoomFilterableController.swift
//  Calendar
//
//  Created by zhuheng on 2021/2/16.
//

import UniverseDesignIcon
import Foundation
import UIKit
import Swinject
import RxSwift
import RxCocoa
import LarkUIKit
import LarkContainer
import LKCommonsLogging
import UniverseDesignTabs
import LarkKeyboardKit

protocol SearchMeetingRoomFilterableControllerDelegate: AnyObject {
    func didUnselectMeetingRoom(from: SearchMeetingRoomFilterableController)
    func didSelectMeetingRoom(_ meetingRoom: CalendarMeetingRoom, from: SearchMeetingRoomFilterableController)
}

final class SearchMeetingRoomFilterableController: BaseUIViewController, UserResolverWrapper {
    private typealias UIStyle = EventEditUIStyle
    private lazy var searchTextField = initSearchTextField()
    private lazy var loadingView = initLoadingView()
    private lazy var faildView = initFaildView()
    private let filterView = MeetingRoomFilterView()
    var actionSource: MeetingRoomActionSource = .searchMeeting
    private lazy var modules = (
        allMeetingRoom: initAllMeetingRoomModule(),
        searchMeetingRoom: initSearchMeetingRoomModule()
    )
    private lazy var capacityInputView = CapacityInputView()
    private let equipmentSelectorView = EquipmentSelectorView()

    private let rxHideUnavailable = BehaviorRelay(value: true)
    private let rxQuery = BehaviorRelay(value: "")

    private let viewModel: MeetingRoomContainerViewModel
    private let selectedMeetingRooms: [CalendarMeetingRoom]
    private let tenantID: String
    private let meetingRoomApi: CalendarRustAPI
    private let disposeBag = DisposeBag()
    private let meetingRoomContainerView = UIView()

    weak var delegate: SearchMeetingRoomFilterableControllerDelegate?

    let userResolver: UserResolver

    init(userResolver: UserResolver,
         viewModel: MeetingRoomContainerViewModel,
         selectedMeetingRooms: [CalendarMeetingRoom],
         meetingRoomApi: CalendarRustAPI,
         tenantID: String) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.selectedMeetingRooms = selectedMeetingRooms
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
        setupNaviItem()

        observekeyboard()

        bindViewData()
        bindViewAction()

        viewModel.loadBuilding()
        viewModel.loadEquipment()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    private func bindViewData() {
        viewModel.rxViewState.bind { [weak self] (state) in
            guard let self = self else { return }
            switch state {
            case .loading:
                self.loadingView.isHidden = false
                self.view.bringSubviewToFront(self.loadingView)
            case .buildingData:
                self.meetingRoomContainerView.isHidden = false
                self.view.bringSubviewToFront(self.meetingRoomContainerView)
            case .failed:
                self.faildView.isHidden = false
                self.view.bringSubviewToFront(self.faildView)
            }
        }.disposed(by: disposeBag)

        viewModel.rxMeetingRoomFilterViewData.bind(to: filterView).disposed(by: disposeBag)
        viewModel.rxEquipmentListViewData.bind(to: equipmentSelectorView).disposed(by: disposeBag)
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
        }.bind(to: rxQuery).disposed(by: disposeBag)

        filterView.equipmentTapped = { [weak self] in
            guard let self = self else { return }
            self.viewModel.loadEquipment()
            self.equipmentSelectorView.isHidden = false
            let backgroundView: UIView = self.navigationController?.view ?? self.view
            backgroundView.bringSubviewToFront(self.equipmentSelectorView)
            if self.searchTextField.canResignFirstResponder {
                self.searchTextField.resignFirstResponder()
            }
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

    private func setupNaviItem() {
        isNavigationBarHidden = false
        let closeItem = LKBarButtonItem(
            image: UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24))
        )
        closeItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        navigationItem.leftBarButtonItem = closeItem
    }

    private func setupView() {
        view.backgroundColor = UIStyle.Color.viewControllerBackground

        searchTextField.backgroundColor = UIColor.ud.bgBody
        view.addSubview(searchTextField)
        searchTextField.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.height.equalTo(71)
        }

        view.addSubview(filterView)
        filterView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.height.equalTo(60)
            $0.top.equalTo(searchTextField.snp.bottom).offset(8)
        }

        view.addSubview(meetingRoomContainerView)
        meetingRoomContainerView.snp.makeConstraints {
            $0.top.equalTo(filterView.snp.bottom)
            $0.left.right.bottom.equalToSuperview()
        }

        addChild(modules.allMeetingRoom)
        modules.allMeetingRoom.didMove(toParent: self)

        let titleView = initTitleStatckView()
        meetingRoomContainerView.addSubview(titleView)
        titleView.snp.makeConstraints {
            $0.left.top.right.equalToSuperview()
        }

        meetingRoomContainerView.addSubview(modules.allMeetingRoom.view)
        modules.allMeetingRoom.view.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.left.right.bottom.equalToSuperview()
        }

        view.addSubview(loadingView)
        loadingView.snp.makeConstraints {
            $0.edges.equalTo(meetingRoomContainerView)
        }

        view.addSubview(faildView)
        faildView.snp.makeConstraints {
            $0.edges.equalTo(meetingRoomContainerView)
        }

        addChild(modules.searchMeetingRoom)
        modules.searchMeetingRoom.didMove(toParent: self)
        meetingRoomContainerView.addSubview(modules.searchMeetingRoom.view)
        modules.searchMeetingRoom.view.snp.makeConstraints { $0.edges.equalTo(meetingRoomContainerView) }
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

extension SearchMeetingRoomFilterableController {
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

    func initSearchTextField() -> UITextField {
        let textField = NewEventContentTextField(inset: 16)
        textField.clearButtonMode = .whileEditing
        textField.attributedPlaceholder = NSAttributedString(
            string: BundleI18n.Calendar.Calendar_EventSearch_SearchRoom,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder]
        )
        textField.textColor = UIColor.ud.textTitle
        textField.font = UIFont.cd.mediumFont(ofSize: 22)
        textField.addSearchIcon()
        textField.returnKeyType = .done
        textField.backgroundColor = UIColor.ud.bgBody
        return textField
    }

    private func initSearchMeetingRoomModule() -> UIViewController {
        let selectedMeetingRoomIDs = Set(selectedMeetingRooms.map { $0.uniqueId })
        let vm = MeetingRoomSearchViewModel(userResolver: userResolver,
                                            meetingRoomApi: meetingRoomApi,
                                            tenantId: tenantID,
                                            multiLevelResources: viewModel.multiLevelResources,
                                            rxHideUnavailable: rxHideUnavailable,
                                            rxQuery: rxQuery,
                                            rxNeedEquipments: viewModel.rxNeedEquipments,
                                            rxMinCapacity: viewModel.rxMinCapacity,
                                            filterMeetingRoomIds: selectedMeetingRoomIDs,
                                            scene: .search)
        let controller = MeetingRoomSearchViewController(viewModel: vm)
        controller.delegate = self
        return controller
    }

    private func initAllMeetingRoomModule() -> UIViewController {
        let vm = MeetingRoomFoldViewModel(userResolver: userResolver,
                                          meetingRoomApi: meetingRoomApi,
                                          startDate: Date(timeIntervalSince1970: 0),
                                          endDate: Date(timeIntervalSince1970: 0),
                                          tenantId: tenantID,
                                          hideUnavailable: false,
                                          rrule: nil,
                                          rxNeedEquipments: viewModel.rxNeedEquipments,
                                          rxMinCapacity: viewModel.rxMinCapacity,
                                          rxBuildings: viewModel.rxBuildings)
        let controller = MeetingRoomFoldViewController(viewModel: vm, emptyHolderText: I18n.Calendar_Room_NoOneToFind)
        controller.delegate = self
        return controller
    }

    private func initTitleStatckView() -> UIView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill

        if let selectMeetingRoom = selectedMeetingRooms.first {
            stackView.addArrangedSubview(initSelectedMeetingRoomTitle())
            let cell = SelectedMeetingRoomView()
            cell.setupContent(model: selectMeetingRoom, allowDeleteOriginalRooms: true)
            cell.close = { [weak self] (_) in
                guard let self = self else { return }
                self.delegate?.didUnselectMeetingRoom(from: self)
            }
            stackView.addArrangedSubview(cell)
            cell.snp.makeConstraints {                $0.height.equalTo(NewEventViewUIStyle.Margin.cellHeight)
            }
        }

        stackView.addArrangedSubview(initAllMeetingRoomTitle())

        return stackView
    }

    private func initSelectedMeetingRoomTitle() -> UIView {
        return meetingRoomTitleView(icon: UIImage.cd.image(named: "meetingroom_header").withRenderingMode(.alwaysOriginal), title: BundleI18n.Calendar.Calendar_Edit_ChosenRooms)
    }

    private func initAllMeetingRoomTitle() -> UIView {
        return meetingRoomTitleView(icon: UIImage.cd.image(named: "meetingRoom_list").withRenderingMode(.alwaysOriginal), title: BundleI18n.Calendar.Calendar_Edit_AllRooms)
    }

    private func meetingRoomTitleView(icon: UIImage, title: String) -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.ud.bgBase
        let whiteView = UIView()
        whiteView.backgroundColor = UIColor.ud.bgBody
        headerView.addSubview(whiteView)
        whiteView.snp.makeConstraints {
            $0.left.width.bottom.equalToSuperview()
            $0.top.equalToSuperview().offset(8)
            $0.height.equalTo(NewEventViewUIStyle.Margin.tableViewHeaderHeight)
        }

        let iconImageView = UIImageView(image: icon)
        whiteView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints {
            $0.size.equalTo(UIStyle.Layout.iconSize)
            $0.left.equalToSuperview().offset(UIStyle.Layout.iconLeftMargin)
            $0.centerY.equalTo(52 / 2)
        }

        let titleLabel = UILabel.cd.titleLabel(fontSize: 16)
        titleLabel.text = title
        whiteView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(UIStyle.Layout.contentLeftMargin)
            $0.right.equalToSuperview()
            $0.centerY.equalTo(iconImageView)
        }

        let bottomLineView = UIView()
        bottomLineView.backgroundColor = UIStyle.Color.horizontalSeperator
        whiteView.addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(UIStyle.Layout.contentLeftMargin)
            $0.right.bottom.equalToSuperview()
            $0.height.equalTo(UIStyle.Layout.horizontalSeperatorHeight)
        }

        return headerView
    }

    private func jumpToMeetingRoomDetail(_ resourceID: String) {
        CalendarTracer.shared.calClickMeetingRoomInfoFromSearch()
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

extension SearchMeetingRoomFilterableController: MeetingRoomFoldViewControllerDelegate {
    func autoJustTimeTapped(needRenewalReminder: Bool, rrule: EventRecurrenceRule?) {
    }
    
    func didSelectMeetingRooms(_ meetingRooms: [CalendarMeetingRoom], from viewController: MeetingRoomFoldViewController) {
        // 搜索不支持多选
        if let first = meetingRooms.first {
            delegate?.didSelectMeetingRoom(first, from: self)
        }
    }

    func didSelectMeetingRoomDetail(_ resourceID: String, from viewController: MeetingRoomFoldViewController) {
        jumpToMeetingRoomDetail(resourceID)
    }
}

extension SearchMeetingRoomFilterableController: MeetingRoomSearchViewControllerDelegate {
    func didSelectMeetingRoomDetail(_ resourceID: String, from viewController: MeetingRoomSearchViewController) {
        jumpToMeetingRoomDetail(resourceID)
    }

    func didSelectMeetingRoom(
        _ meetingRoom: CalendarMeetingRoom,
        from viewController: MeetingRoomSearchViewController) {
        delegate?.didSelectMeetingRoom(meetingRoom, from: self)
    }
}
