//
//  EventendDateViewController.swift
//  Calendar
//
//  Created by Miao Cai on 2020/3/26.
//
import UIKit
import RxSwift
import RxCocoa
import LarkUIKit
import UniverseDesignToast
import LarkTimeFormatUtils

/// 编辑重复性规则截止时间

protocol EventRruleEndDateViewControllerDelegate: AnyObject {
    func didCancelEdit(from viewController: EventRruleEndDateViewController)
    func didFinishEdit(from viewController: EventRruleEndDateViewController, needRenewalReminder: Bool)
}

final class EventRruleEndDateViewController: BaseUIViewController, UIAdaptivePresentationControllerDelegate {
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }
    weak var delegate: EventRruleEndDateViewControllerDelegate?
    internal private(set) var rrule: EventRecurrenceRule
    // 用户开始编辑前的 rrule，退出取消编辑时，用于判断是否应该弹窗提醒
    internal private(set) var rruleBeforeEditing: EventRecurrenceRule

    private let disposeBag = DisposeBag()
    private let startDate: Date
    private let meetingRoomMaxEndDateInfo: MeetingRoomEndDateInfo?
    private let meetingRoomAmount: Int
    private let customOptions: Options

    private let rxPickedDate = BehaviorRelay<Date>(value: Date())
    private let rxIsEndlessOn = BehaviorRelay<Bool>(value: false)

    private lazy var warningView = EventDateInvalidWarningView(textFont: UIFont.systemFont(ofSize: 14))
    private var datePickerComponent: EventRruleEndDatePickerView
    // warningView的上一个显隐状态
    private var warningViewLastIsHidden = true
    /// 日程公参
    var eventParam: CommonParamData?
    // 是否发送续订提醒
    private var needRenewalReminder: Bool = false

    private struct DateInvalidWarningViewData: EventEditDateInvalidWarningViewDataType {
        var warningStr: String
        var isClickable: Bool
    }
    private let eventTimezoneId: String

    init(
        rrule: EventRecurrenceRule,
        startDate: Date,
        meetingRoomMaxEndDateInfo: MeetingRoomEndDateInfo? = nil,
        meetingRoomAmount: Int,
        eventTimezoneId: String
    ) {
        self.rrule = (rrule.copy() as? EventRecurrenceRule) ?? rrule
        self.rruleBeforeEditing = (rrule.copy() as? EventRecurrenceRule) ?? rrule
        self.startDate = startDate
        self.meetingRoomMaxEndDateInfo = meetingRoomMaxEndDateInfo
        self.meetingRoomAmount = meetingRoomAmount
        self.eventTimezoneId = eventTimezoneId
        // 使用设备时区
        self.customOptions = Options(
            timeFormatType: .long,
            datePrecisionType: .day
        )

        if let endDate = rrule.recurrenceEnd?.endDate {
            rxPickedDate.accept(endDate)
            rxIsEndlessOn.accept(false)
        } else {
            rxPickedDate.accept(Self.getDefaultEndDate(from: rrule, base: startDate))
            rxIsEndlessOn.accept(true)
        }

        self.datePickerComponent = .init(endDate: rxPickedDate.value)
        self.datePickerComponent.setBgColor(EventEditUIStyle.Color.viewControllerBackground)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.Calendar.Calendar_Edit_EndsDate
        setupView()
        setupNaviItem()

        datePickerComponent.endlessSwitch.isOn = rxIsEndlessOn.value

        datePickerComponent.endlessSwitch.rx.isOn.skip(1)
            .bind(to: rxIsEndlessOn)
            .disposed(by: disposeBag)
        datePickerComponent.datePicker.dateChanged = { [weak self] date in
            guard let self = self else { return }
            self.rxPickedDate.accept(date)
            if self.datePickerComponent.endlessSwitch.isOn {
                self.datePickerComponent.endlessSwitch.isOn = false
                self.rxIsEndlessOn.accept(false)
            }
        }

        rxIsEndlessOn.bind { [weak self] inOn in
            guard let self = self else { return }
            self.datePickerComponent.updateDisableMask(show: inOn)
            self.warningView.snp.remakeConstraints {
                $0.left.right.equalToSuperview()
                if inOn {
                    $0.top.equalTo(self.datePickerComponent.titleCell.snp.bottom).offset(4)
                } else {
                    $0.top.equalTo(self.datePickerComponent.snp.bottom).offset(4)
                }
            }
        }.disposed(by: disposeBag)

        Observable.combineLatest(rxPickedDate, rxIsEndlessOn)
            .bind { [weak self] tuple in
                let (date, isEndlessOn) = tuple
                if isEndlessOn {
                    self?.rrule.recurrenceEnd = nil
                } else {
                    self?.rrule.recurrenceEnd = EventRecurrenceEnd(end: date.dayEnd())
                }
                self?.updateDateRelatedViews(with: self?.rrule.recurrenceEnd?.endDate)
            }
            .disposed(by: disposeBag)

        Observable.combineLatest(rxPickedDate, rxIsEndlessOn)
            .bind { [weak self] _ in
                if #available(iOS 13.0, *) {
                    guard let self = self else { return }
                    let inPresentation = self.rrule.recurrenceEnd != self.rruleBeforeEditing.recurrenceEnd
                    self.isModalInPresentation = inPresentation
                }
            }
            .disposed(by: disposeBag)

        navigationController?.presentationController?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// trigger warningView relayout
        warningView.viewData = warningView.viewData
    }

    private func setupView() {
        view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground

        view.addSubview(warningView)
        view.addSubview(datePickerComponent)
        view.bringSubviewToFront(warningView)
        warningView.backgroundColors = (.clear, .clear)
        warningView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(self.datePickerComponent.snp.bottom).offset(4)
        }

        datePickerComponent.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview().inset(14)
        }
    }

    private func setupNaviItem() {
        let cancelItem = LKBarButtonItem(
            title: BundleI18n.Calendar.Calendar_Common_Cancel
        )
        navigationItem.leftBarButtonItem = cancelItem
        cancelItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.willCancelEdit()
            }
            .disposed(by: disposeBag)

        let doneItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Done, fontStyle: .medium)
        doneItem.button.tintColor = UIColor.ud.primaryContentDefault
        navigationItem.rightBarButtonItem = doneItem
        doneItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.delegate?.didFinishEdit(from: self, needRenewalReminder: self.needRenewalReminder)
            }
            .disposed(by: disposeBag)
    }

    private func updateDateRelatedViews(with endDate: Date?) {
        // 永不截止
        var warningType: RruleInvalidWarningType?
        guard let endDate = endDate else {
            // 未指定截止日期需显示"永不截止"
            if let (name, maxEndDate) = meetingRoomMaxEndDateInfo {
                let dateStr = TimeFormatUtils.formatDate(from: maxEndDate, with: customOptions)
                // 含有会议室，则必含有截止日期
                warningView.isHidden = false
                if warningViewLastIsHidden {
                    CalendarTracerV2.UtiltimeAdjustRemind.traceView {
                        $0.location = CalendarTracerV2.AdjustRemindLocation.editRruleView.rawValue
                        $0.mergeEventCommonParams(commonParam: self.eventParam ?? .init())
                    }
                }
                warningViewLastIsHidden = warningView.isHidden
                if maxEndDate < startDate {
                    warningType = .meetingRoomReservableDateEarlierThanStartDate(
                        meetingRoomAmount > 1 ? .some(name) : .one,
                        dateStr
                    )
                    warningView.viewData = DateInvalidWarningViewData(
                        warningStr: warningType?.readableStr ?? "",
                        isClickable: false
                    )
                } else {
                    warningType = .meetingRoomReservableDateEarlierThanDueDate(
                        meetingRoomAmount > 1 ? .some(name) : .one,
                        dateStr
                    )
                    warningView.onClickHandler = { [weak self] in
                        guard let self = self else { return }
                        self.datePickerComponent.datePicker.select(date: maxEndDate)
                        if FG.calendarRoomsReservationTime {
                            self.autoJustTimeHandler(maxEndDate: maxEndDate)
                        }
                    }
                    warningView.viewData = DateInvalidWarningViewData(
                        warningStr: warningType?.readableStr ?? "",
                        isClickable: true
                    )
                }
            } else {
                warningView.isHidden = true
                warningViewLastIsHidden = warningView.isHidden
            }
            navigationItem.rightBarButtonItem?.isEnabled = warningView.isHidden
            datePickerComponent.updateWarningState(isWarning: !warningView.isHidden)
            return
        }

        let dayEnd = endDate.dayEnd()

        if let (name, maxEndDate) = meetingRoomMaxEndDateInfo {
            // 日程含有会议室
            let dateStr = TimeFormatUtils.formatDate(from: maxEndDate, with: customOptions)
            let isEndDateValid: Bool
            // 优先判断会议室可预定最远范围是否早于日程开始时间
            if maxEndDate < startDate {
                isEndDateValid = false
                warningType = .meetingRoomReservableDateEarlierThanStartDate(
                    meetingRoomAmount > 1 ? .some(name) : .one,
                    dateStr
                )
            } else if dayEnd < startDate {
                // 截止时间早于开始时间
                isEndDateValid = false
                warningType = .startDateLaterThanDueDate
            } else if maxEndDate.dayEnd() < dayEnd {
                isEndDateValid = false
                warningType = .meetingRoomReservableDateEarlierThanDueDate(
                    meetingRoomAmount > 1 ? .some(name) : .one,
                    dateStr
                )
                warningView.onClickHandler = { [weak self] in
                    guard let self = self else { return }
                    self.datePickerComponent.datePicker.select(date: maxEndDate)
                    if FG.calendarRoomsReservationTime {
                        self.autoJustTimeHandler(maxEndDate: maxEndDate)
                    }
                }
            } else {
                // 时间合法
                isEndDateValid = true
            }
            warningView.isHidden = isEndDateValid
            if warningViewLastIsHidden, warningView.isHidden == false  {
                CalendarTracerV2.UtiltimeAdjustRemind.traceView {
                    $0.location = CalendarTracerV2.AdjustRemindLocation.editRruleView.rawValue
                    $0.mergeEventCommonParams(commonParam: self.eventParam ?? .init())
                }
            }
            warningViewLastIsHidden = warningView.isHidden
        } else {
            // 日程不含会议室
            if dayEnd < startDate {
                // 截止时间早于开始时间
                warningView.isHidden = false
                if warningViewLastIsHidden, warningView.isHidden == false  {
                    CalendarTracerV2.UtiltimeAdjustRemind.traceView {
                        $0.location = CalendarTracerV2.AdjustRemindLocation.editRruleView.rawValue
                        $0.mergeEventCommonParams(commonParam: self.eventParam ?? .init())
                    }
                }
                warningViewLastIsHidden = warningView.isHidden
                warningType = .startDateLaterThanDueDate
            } else {
                // 时间合法
                warningView.isHidden = true
            }
        }

        let warningStr = warningType?.readableStr ?? ""
        let isClickable: Bool
        if let type = warningType {
            switch type {
            case .meetingRoomReservableDateEarlierThanDueDate: isClickable = true
            default: isClickable = false
            }
        } else {
            isClickable = false
        }

        warningView.viewData = DateInvalidWarningViewData(
            warningStr: warningStr,
            isClickable: isClickable
        )
        navigationItem.rightBarButtonItem?.isEnabled = warningView.isHidden
        datePickerComponent.updateWarningState(isWarning: !warningView.isHidden)
    }
    
    private func autoJustTimeHandler(maxEndDate: Date) {
        self.needRenewalReminder = true
        CalendarTracerV2.UtiltimeAdjustRemind.traceClick {
            $0.click("adjust")
            $0.location = CalendarTracerV2.AdjustRemindLocation.editRruleView.rawValue
            $0.mergeEventCommonParams(commonParam: self.eventParam ?? .init())
        }
        // 展示toast
        let timezone = TimeZone(identifier: self.eventTimezoneId) ?? .current
        let customOptions = Options(
            timeZone: timezone,
            timeFormatType: .long,
            datePrecisionType: .day
        )
        let dateDesc = TimeFormatUtils.formatDate(from: maxEndDate, with: customOptions)
        UDToast.showTips(with: I18n.Calendar_G_AvailabilitySuggestion_TimeChanged_Popup(eventEndTime: dateDesc), on: self.view, delay: 5.0)
    }

    private func willCancelEdit() {
        if rrule.recurrenceEnd != rruleBeforeEditing.recurrenceEnd {
            let alertTexts = EventEditConfirmAlertTexts(
                message: BundleI18n.Calendar.Calendar_Edit_UnSaveTip
            )
            self.showConfirmAlertController(
                texts: alertTexts,
                confirmHandler: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.didCancelEdit(from: self)
                }
            )
        } else {
            self.delegate?.didCancelEdit(from: self)
        }
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        willCancelEdit()
    }
}

extension EventRruleEndDateViewController {
    private static func getDefaultEndDate(from rRule: EventRecurrenceRule, base: Date) -> Date {
        /// https://bytedance.feishu.cn/docx/WD7JdAqMxoKfA0xlvZKc3tMvnub
        var defaultPicked = base
        switch rRule.frequency {
        case .daily:
            defaultPicked = defaultPicked.adding(.month, value: 1)
        case .weekly:
            defaultPicked = defaultPicked.adding(.month, value: 3)
        case .monthly:
            defaultPicked = defaultPicked.adding(.month, value: 12)
        case .yearly:
            defaultPicked = defaultPicked.adding(.year, value: 5)
        }
        return defaultPicked
    }
}

extension EventRruleEndDateViewController: EventEditConfirmAlertSupport {}
