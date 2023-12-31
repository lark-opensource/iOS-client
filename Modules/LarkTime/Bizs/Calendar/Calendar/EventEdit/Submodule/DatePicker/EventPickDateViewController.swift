//
//  EventPickDateViewController.swift
//  Calendar
//
//  Created by 张威 on 2020/3/23.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignDialog
import UniverseDesignColor
import CalendarFoundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import RoundedHUD
import CTFoundation
import LarkAlertController
import LarkContainer

// 日程 - Date 编辑页

protocol EventPickDateViewControllerDelegate: AnyObject {
    func didCancelEdit(from viewController: EventPickDateViewController)
    func didFinishEdit(from viewController: EventPickDateViewController)
    func selectTimeZone(from viewController: EventPickDateViewController, with anchorDate: Date)
}

final class EventPickDateViewController: BaseUIViewController,
                                         EventEditConfirmAlertSupport,
                                         UserResolverWrapper,
                                         UITableViewDataSource,
                                         UITableViewDelegate {
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }

    let viewModel: EventPickDateViewModel
    weak var delegate: EventPickDateViewControllerDelegate?

    let disposeBag = DisposeBag()

    let userResolver: UserResolver

    private lazy var allDayView = AllDayView(isOn: self.viewModel.rxIsAllDay.value)

    private lazy var dateRangeView = EventEditDateRangeSwitchView(selectedState: self.viewModel.dateState.value)

    private let datePickerContainerView = UIView()
    private var datePickerViews = [String: EventEditDatePickerView]()

    private lazy var tableView = setupTableView()
    private lazy var timeZoneTitleView = setupTimeZoneTitleView()
    private lazy var timeZoneView = setupTimeZoneView()

    private let viewContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.backgroundColor = EventEditUIStyle.Color.viewControllerBackground
        return stackView
    }()

    private lazy var timezoneTipView: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textPlaceholder
        label.font = UIFont.ud.body2(.fixed)
        label.numberOfLines = 0
        return label
    }()

    private lazy var rootView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag
        return scrollView
    }()

    private lazy var timezoneTipDivideLine = EventBasicDivideView()
    private lazy var dateRangeViewBottomDivideLine = EventBasicDivideView()
    private lazy var allDayViewDivideLine = EventBasicDivideView()
    private lazy var timezoneTipcontainerView = UIView()

    private let cellReuseId = "Cell"
    // datePicker 没有 frame 自适应的能力，当 view.width 变化时，需重新构建 datePicker
    private var datePickerDisplayWidth: CGFloat?

    private let cellHeight: CGFloat = 66
    private let headerHeight: CGFloat = 36

    init(viewModel: EventPickDateViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        self.title = BundleI18n.Calendar.Calendar_Edit_Time
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupNaviItems()
        bindViewData()
    }

    override func viewWillLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let containerWidth = view.bounds.width - 32
        if let displayWidth = datePickerDisplayWidth,
            view.bounds.width > 1,
            abs(containerWidth - displayWidth) < 0.0001 {
            return
        }

        datePickerDisplayWidth = containerWidth

        datePickerViews.values.forEach { $0.removeFromSuperview() }
        datePickerViews.removeAll()

        let state = viewModel.dateState.value
        let date: Date
        switch state {
        case .start: date = viewModel.startDateForDatePicker
        case .end: date = viewModel.endDateForDatePicker
        }
        switchDatePicker(
            for: state,
            with: date,
            isAllDay: viewModel.rxIsAllDay.value,
            is12HourStyle: viewModel.rxIs12HourStyle.value,
            displayWidth: containerWidth
        )
    }

    private func bindViewData() {
        // for all day view
        allDayView.isOn.asDriver().skip(1).drive(onNext: { [weak self] isOn in
            self?.viewModel.updateIsAllDay(isOn)
        }).disposed(by: disposeBag)

        // for data range view
        viewModel.rxDateRangeViewData.bind(to: dateRangeView).disposed(by: disposeBag)

        dateRangeView.onSeletedStateChanged = { [weak self] state in
            self?.viewModel.dateState.accept(state)
        }

        // for date picker
        typealias PickerRelatedTuple = (is12HourStyle: Bool, dateSwitchState: EventPickDateViewModel.DateSwitchState, isAllDay: Bool, range: EventPickDateViewModel.DateRange, timezoneDisplayType: TimezoneDisplayType)
        Observable.combineLatest(viewModel.rxIs12HourStyle, viewModel.dateState, viewModel.rxIsAllDay, viewModel.rxDateRange, viewModel.rxTimezoneDisplayType)
            .distinctUntilChanged { (before: PickerRelatedTuple, after: PickerRelatedTuple) -> Bool in
                before.is12HourStyle == after.is12HourStyle &&
                before.dateSwitchState == after.dateSwitchState &&
                before.isAllDay == after.isAllDay &&
                before.range.start == after.range.start &&
                before.range.end == after.range.end &&
                before.timezoneDisplayType == after.timezoneDisplayType
            }
            .subscribeForUI(onNext: { [weak self] (tuple) in
                guard let self = self else { return }
                guard let displayWidth = self.datePickerDisplayWidth else { return }
                let (is12HourStyle, state, isAllDay, _, _) = tuple
                let date: Date
                switch state {
                case .start: date = self.viewModel.startDateForDatePicker
                case .end: date = self.viewModel.endDateForDatePicker
                }
                self.switchDatePicker(
                    for: state,
                    with: date,
                    isAllDay: isAllDay,
                    is12HourStyle: is12HourStyle,
                    displayWidth: displayWidth
                )
            })
            .disposed(by: disposeBag)

        if CalConfig.isMultiTimeZone {
            // for timeZone view
            viewModel.rxIsAllDay.bind { [weak self] isAllDay in
                self?.timeZoneView.isHidden = isAllDay
                self?.dateRangeViewBottomDivideLine.isHidden = isAllDay
                self?.view.needsUpdateConstraints()
            }.disposed(by: disposeBag)
            viewModel.rxTimeZoneViewData.bind(to: timeZoneTitleView.rx.text).disposed(by: disposeBag)
            timeZoneView.onClick = { [weak self] in
                guard let self = self else { return }

                let selectTimeZone: () -> Void = {
                    let eventRange = self.viewModel.editItem.dateRange
                    let anchorDate = self.viewModel.dateState.value == .start ? eventRange.start : eventRange.end
                    self.delegate?.selectTimeZone(from: self, with: anchorDate)
                }

                let commonParam = CommonParamData(event: self.viewModel.pbEvent,
                                                  startTime: Int64(self.viewModel.rxDateRange.value.start.timeIntervalSince1970))
                CalendarTracerV2.EventFullCreate.traceClick(commonParam: commonParam) {
                    $0.click("timezone")
                    $0.is_device_timezone =  self.viewModel.timezoneDisplayType == .deviceTimezone ? "true" : "false"
                }

                // show dialog
                if self.viewModel.shouldSwitchToEventTimezone {
                    self.confirmSwitchTimezone {
                        EventEdit.logger.info("shouldSwitchToEventTimezone")
                        self.viewModel.switchToEventTimezone()
                        selectTimeZone()
                        CalendarTracerV2.EventFullCreate.traceClick(commonParam: commonParam) {
                            $0.click("switch_to_event_timezone")
                            $0.is_device_timezone = "false"
                        }
                    }
                } else {
                    selectTimeZone()
                }
            }

            viewModel.rxReloadTableView.bind { [weak self] _ in
                guard let self = self else { return }
                self.tableView.reloadData()
                self.timezoneTipDivideLine.isHidden = !viewModel.shouldShowAttendeeTimeZoneTableView && timezoneTipView.text.isEmpty
                self.tableView.snp.updateConstraints {
                    if self.viewModel.shouldShowAttendeeTimeZoneTableView {
                        $0.height.equalTo(CGFloat(self.viewModel.numberOfRows()) * self.cellHeight + self.headerHeight)
                    } else {
                        $0.height.equalTo(0)
                    }
                }
            }.disposed(by: disposeBag)

            viewModel.rxTimezoneTip
                .map { $0 ?? "" }
                .subscribe(onNext: { [weak self] text in
                    guard let self = self else { return }
                    self.timezoneTipDivideLine.isHidden = !self.viewModel.shouldShowAttendeeTimeZoneTableView && text.isEmpty
                    self.timezoneTipcontainerView.isHidden = text.isEmpty
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineBreakMode = .byWordWrapping
                    paragraphStyle.minimumLineHeight = 22
                    paragraphStyle.maximumLineHeight = 22
                    self.timezoneTipView.attributedText = NSAttributedString(string: text, attributes: [.foregroundColor: UDColor.textPlaceholder,
                                                                                                        .font: UIFont.ud.body2(.fixed),
                                                                                                        .paragraphStyle: paragraphStyle])
                })
                .disposed(by: disposeBag)
        }
    }

    // 当日程时区跟设备时区不同时，改变时区需要弹窗确认，确认后会切换为日程时区
    private func confirmSwitchTimezone( completion: @escaping () -> Void) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.Calendar.Calendar_G_EditAfterSwitchZone)
        dialog.addSecondaryButton(text: BundleI18n.Calendar.Calendar_Common_Cancel)
        dialog.addPrimaryButton(text: BundleI18n.Calendar.Calendar_G_SwitchButton, dismissCompletion: completion)
        self.present(dialog, animated: true)
    }

    private func switchDatePicker(
        for state: EventPickDateViewModel.DateSwitchState,
        with date: Date,
        isAllDay: Bool,
        is12HourStyle: Bool,
        displayWidth: CGFloat
    ) {
        let key = "\(state)_\(isAllDay)_\(is12HourStyle)"
        var datePicker: EventEditDatePickerView? = datePickerViews[key]
        if let datePicker = datePicker {
            datePicker.updateDate(date)
            datePicker.isHidden = false
            datePicker.superview?.bringSubviewToFront(datePicker)
        } else {
            let mode: EventEditDatePickerView.Mode
            if isAllDay {
                mode = .allDay
            } else {
                mode = .nonAllDay(hourStyle: is12HourStyle ? .hour12 : .hour24)
            }

            datePicker = EventEditDatePickerView(
                displayWidth: displayWidth,
                initialDate: date,
                mode: mode
            )
            guard let datePicker = datePicker else { return }
            datePicker.onDateSelected = { [unowned self] date in
                switch state {
                case .start: self.viewModel.updateStartDate(date)
                case .end: self.viewModel.updateEndDate(date)
                }

                let commonParam = CommonParamData(event: self.viewModel.pbEvent,
                                                  startTime: Int64(self.viewModel.rxDateRange.value.start.timeIntervalSince1970))
                CalendarTracerV2.EventFullCreate.traceClick(commonParam: commonParam) {
                    $0.click("cross_timezone_event_edit_time")
                    $0.is_device_timezone = self.viewModel.timezoneDisplayType == .deviceTimezone ? "true" : "false"
                }
            }
            datePickerContainerView.addSubview(datePicker)
            datePicker.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }

            datePickerViews[key] = datePicker

            view.setNeedsLayout()
        }

        datePickerViews.values.filter { $0 != datePicker }.forEach { $0.isHidden = true }
    }

    // MARK: UITableViewDataSource & UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.shouldShowAttendeeTimeZoneTableView ? 1 : 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.cellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        guard let attendeeTimeZoneCell = cell as? EventEditDatePickerAttendeeTimeZoneCell else {
            return cell
        }
        attendeeTimeZoneCell.viewData = viewModel.cellData(forRowAt: indexPath.row)
        return attendeeTimeZoneCell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.headerHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let titleLabel = UILabel(frame: CGRect(origin: CGPoint(x: 16, y: 12), size: CGSize(width: view.frame.width, height: 20)))
        titleLabel.textColor = UIColor.ud.textPlaceholder
        titleLabel.text = BundleI18n.Calendar.Calendar_Timezone_LocalTime
        titleLabel.font = UIFont.ud.body2(.fixed)
        headerView.addSubview(titleLabel)
        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        guard let (dateRange, attendees) = viewModel.dateRangeAttendeesPair(at: indexPath.row),
              !attendees.isEmpty else { return }
        let eventEditAttendeeTimeZoneViewModel = EventEditAttendeeTimeZoneViewModel(dateRange: dateRange,
                                                                                    attendees: attendees,
                                                                                    timeZone: viewModel.cellData(forRowAt: indexPath.row)?.timeZone,
                                                                                    is12HourStyle: viewModel.rxIs12HourStyle.value)
        let contentVC = EventEditAttendeeTimeZoneViewController(viewModel: eventEditAttendeeTimeZoneViewModel)
        let popupVC = PopupViewController(rootViewController: contentVC)
        present(popupVC, animated: true, completion: nil)
        Tracer.shared.calClickGuestLocalTime()
    }
}

// MARK: Setup View

extension EventPickDateViewController {

    private func setupTimeZoneTitleView() -> UILabel {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        return titleLabel
    }

    private func setupTimeZoneView() -> EventEditCellLikeView {
        let theView = EventEditCellLikeView()
        theView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        theView.accessory = .type(.next())
        theView.content = .customView(timeZoneTitleView)
        return theView
    }

    private func setupTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .grouped)
        let zeroRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: Double.leastNormalMagnitude)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.tableHeaderView = UIView(frame: zeroRect)
        tableView.tableFooterView = UIView(frame: CGRect(
            origin: .zero,
            size: CGSize(width: view.frame.width, height: view.safeAreaInsets.bottom)
        ))
        tableView.backgroundColor = .clear
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(EventEditDatePickerAttendeeTimeZoneCell.self, forCellReuseIdentifier: cellReuseId)
        tableView.isScrollEnabled = false
        return tableView
    }

    private func setupViews() {
        view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground

        view.addSubview(rootView)
        rootView.addSubview(viewContainer)
        rootView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        viewContainer.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalTo(14)
        }
        // all day switch
        viewContainer.addArrangedSubview(allDayView)
        allDayView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        allDayView.snp.makeConstraints {
            $0.height.equalTo(viewModel.showAllDayView ? 52 : 0)
        }
        allDayView.isHidden = !viewModel.showAllDayView
        viewContainer.addArrangedSubview(allDayViewDivideLine)
        allDayViewDivideLine.isHidden = !viewModel.showAllDayView

        // date range view
        viewContainer.addArrangedSubview(dateRangeView)
        dateRangeView.backgroundColor = EventEditUIStyle.Color.cellBackground

        // date picker
        viewContainer.addArrangedSubview(datePickerContainerView)
        viewContainer.bringSubviewToFront(dateRangeView)

        if CalConfig.isMultiTimeZone {
            // select time zone
            viewContainer.addArrangedSubview(dateRangeViewBottomDivideLine)
            viewContainer.addArrangedSubview(timeZoneView)
            timeZoneView.snp.makeConstraints {
                $0.height.equalTo(48)
            }
            viewContainer.addArrangedSubview(timezoneTipDivideLine)
            timezoneTipcontainerView.addSubview(timezoneTipView)
            timezoneTipView.snp.makeConstraints {
                $0.left.right.equalToSuperview().inset(16)
                $0.top.equalToSuperview()
                $0.bottom.equalToSuperview().inset(26)
            }
            viewContainer.addArrangedSubview(timezoneTipcontainerView)
            // attendee time zones
            viewContainer.addArrangedSubview(tableView)
            tableView.snp.makeConstraints {
                if viewModel.shouldShowAttendeeTimeZoneTableView {
                    $0.height.equalTo(CGFloat(self.viewModel.numberOfRows()) * self.cellHeight + self.headerHeight)
                } else {
                    $0.height.equalTo(0)
                }
            }
        }
    }

    private func setupNaviItems() {
        let backItem = LKBarButtonItem(
            image: UDIcon.getIconByKeyNoLimitSize(.leftOutlined).renderColor(with: .n1).withRenderingMode(.alwaysOriginal)
        )
        backItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.delegate?.didCancelEdit(from: self)
            }
            .disposed(by: disposeBag)
        navigationItem.leftBarButtonItem = backItem

        let doneItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Done, fontStyle: .medium)
        doneItem.button.tintColor = UIColor.ud.primaryContentDefault
        doneItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.updateEventDateComponents()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] saveAction in
                        guard let self = self else { return }
                        switch saveAction {
                        case .undo:
                            self.didUndoEdit()
                        case .update:
                            self.delegate?.didFinishEdit(from: self)
                        case .finishWithoutUpdate:
                            self.delegate?.didCancelEdit(from: self)
                        case .cancel:
                            // Do nothing
                            return
                        }
                    }).disposed(by: self.disposeBag)
            }
            .disposed(by: disposeBag)
        navigationItem.rightBarButtonItem = doneItem
    }
}

extension EventPickDateViewController {

    final class AllDayView: EventEditCellLikeView {

        let disposeBag = DisposeBag()
        var isOn: RxCocoa.ControlProperty<Bool> { sw.rx.isOn }

        private let sw = UISwitch()
        init(isOn: Bool) {
            super.init(frame: .zero)

            sw.isOn = isOn
            sw.onTintColor = UIColor.ud.primaryContentDefault
            addSubview(sw)
            sw.snp.makeConstraints {
                $0.right.equalToSuperview().inset(EventBasicCellLikeView.Style.rightInset)
                $0.height.equalTo(28)
                $0.width.equalTo(46)
                $0.centerY.equalToSuperview()
            }
            content = .title(.init(text: BundleI18n.Calendar.Calendar_Edit_Allday))

        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }

}

// MARK: - Date Range Validation Service
extension EventPickDateViewController {
    enum SaveAction {
        case undo
        case update
        case cancel
        case finishWithoutUpdate
    }

    private func updateEventDateComponents() -> Observable<SaveAction> {
        return Observable<SaveAction>.create { [weak self] observer -> Disposable in
            // 日程开始-结束时间常规检查
            guard let self = self else {
                observer.onNext(.cancel)
                observer.onCompleted()
                return Disposables.create()
            }
            guard self.viewModel.isDateValid() else {
                let alertTexts = EventEditConfirmAlertTexts(
                    title: BundleI18n.Calendar.Calendar_Edit_Alert,
                    message: BundleI18n.Calendar.Calendar_Edit_InvalidEndTime,
                    cancelText: nil
                )
                self.showConfirmAlertController(texts: alertTexts)
                observer.onNext(.cancel)
                observer.onCompleted()
                return Disposables.create()
            }
            guard self.viewModel.hasSomeChange() else {
                observer.onNext(.finishWithoutUpdate)
                observer.onCompleted()
                return Disposables.create()
            }
            observer.onNext(.update)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func didUndoEdit() {
        allDayView.isOn.onNext(viewModel.originalIsAllDay)
        viewModel.resetCellItemsData()
    }
}
