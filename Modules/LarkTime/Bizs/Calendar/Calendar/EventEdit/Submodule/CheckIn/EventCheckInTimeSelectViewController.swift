//
//  EventCheckInTimeSelectViewController.swift
//  Calendar
//
//  Created by huoyunjie on 2022/9/13.
//

import Foundation
import RxSwift
import LarkUIKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignDatePicker
import CalendarFoundation
import UniverseDesignToast
import UIKit
import UniverseDesignPopover

protocol EventCheckInTimeSelectViewControllerDelegate: AnyObject {
    func didCancelEdit(from: EventCheckInTimeSelectViewController)
    func didFinishEdit(from: EventCheckInTimeSelectViewController)
}

class EventCheckInTimeSelectViewController: UIViewController {

    typealias CheckInTime = Rust.CheckInConfig.CheckInTime

    weak var delegate: EventCheckInTimeSelectViewControllerDelegate?

    private var popoverTransition = UDPopoverTransition(sourceView: nil)

    let viewModel: EventCheckInTimeSelectViewModel

    private let disposeBag = DisposeBag()

    private lazy var subTitle: UILabel = {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 11)
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.title3
        switch self.viewModel.timeSelectType {
        case .startTime:
            label.text = I18n.Calendar_Edit_StartTime
        case .endTime:
            label.text = I18n.Calendar_Edit_EndTime
        }
        return label
    }()

    private lazy var titleBar = UIView()

    private lazy var wheelPicker: UDWheelPickerView = {
        let pickerView = UDWheelPickerView(pickerHeight: 240, showSepLine: true, gradientColor: EventEditUIStyle.Color.viewControllerBackground)
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground
        view.layer.cornerRadius = 10
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
        return view
    }()

    init(sourceView: UIView, viewModel: EventCheckInTimeSelectViewModel) {
        popoverTransition = UDPopoverTransition(
            sourceView: sourceView,
            permittedArrowDirections: [.up]
        )
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = popoverTransition
        self.preferredContentSize = CGSize(width: 375, height: 310)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleBar.backgroundColor = EventEditUIStyle.Color.viewControllerBackground
        wheelPicker.backgroundColor = EventEditUIStyle.Color.viewControllerBackground
        layoutTitleBar()
        layoutViews()
        updateSubTitle()

        let tapBg = UITapGestureRecognizer(target: self, action: #selector(didTapBackgroundView))
        self.view.addGestureRecognizer(tapBg)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        redirectWheelPicker()
    }

    @objc
    private func didTapBackgroundView(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if contentView.frame.contains(location) {
            return
        }
        self.presentingViewController?.dismiss(animated: true)
    }

    private func layoutTitleBar() {
        let cancelButton = UIButton()
        let titleView = UIStackView()
        let completeButton = UIButton()
        let divideLine = UIView()

        titleBar.addSubview(cancelButton)
        titleBar.addSubview(titleView)
        titleBar.addSubview(completeButton)
        titleBar.addSubview(divideLine)

        cancelButton.setTitle(I18n.Calendar_Common_Cancel, for: .normal)
        cancelButton.setTitleColor(UDColor.textTitle, for: .normal)
        cancelButton.setTitleColor(UDColor.textDisabled, for: .highlighted)
        cancelButton.titleLabel?.font = UDFont.body0
        cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)

        titleView.addArrangedSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.height.equalTo(24)
        }
        titleView.addArrangedSubview(subTitle)
        subTitle.snp.makeConstraints {
            $0.height.equalTo(14)
        }
        titleView.axis = .vertical
        titleView.alignment = .center

        completeButton.setTitle(I18n.Calendar_Common_Done, for: .normal)
        completeButton.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        completeButton.setTitleColor(UDColor.textDisabled, for: .highlighted)
        completeButton.titleLabel?.font = UDFont.body0
        completeButton.addTarget(self, action: #selector(completeAction), for: .touchUpInside)

        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        titleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        completeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        divideLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        divideLine.backgroundColor = UDColor.lineBorderCard

    }

    private func layoutViews() {
        contentView.addSubview(titleBar)
        contentView.addSubview(wheelPicker)

        wheelPicker.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }

        titleBar.snp.makeConstraints { make in
            make.height.equalTo(56)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(wheelPicker.snp.top)
            make.top.equalToSuperview()
        }

        addWheelPickerUnitLabel()

        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func addWheelPickerUnitLabel() {
        let hourLabel = UILabel()
        let minuteLabel = UILabel()

        hourLabel.text = I18n.Calendar_SubscribeCalendar_TimeToNextEventHour
        hourLabel.font = UDFont.caption1
        hourLabel.textColor = UDColor.textTitle

        minuteLabel.text = I18n.Calendar_SubscribeCalendar_TimeToNextEventMinute
        minuteLabel.font = UDFont.caption1
        minuteLabel.textColor = UDColor.textTitle

        wheelPicker.addSubview(hourLabel)
        wheelPicker.addSubview(minuteLabel)

        let unit = Display.pad ? self.preferredContentSize.width / 8.0 : self.view.bounds.width / 8.0
        let offset: CGFloat = 12
        let hourLabelLeftOffset = unit * 5 + offset
        let minuteLabelLeftOffset = unit * 7 + offset

        hourLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(hourLabelLeftOffset)
        }

        minuteLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(minuteLabelLeftOffset)
        }
    }

    private func updateSubTitle() {
        // 更新文案
        let isStart: Bool = viewModel.timeSelectType == .startTime
        let timeMode = viewModel.currentTimeMode
        self.subTitle.text = viewModel.transformToCheckInTime(timeMode).getReadableStr(isStart: isStart)

        // 校验
        if viewModel.getCheckInError() != nil {
            self.subTitle.textColor = UDColor.functionDangerContentDefault
        } else {
            self.subTitle.textColor = UDColor.textCaption
        }
    }

    @objc
    private func cancelAction() {
        self.delegate?.didCancelEdit(from: self)
    }

    @objc
    private func completeAction() {
        if let error = viewModel.getCheckInError() {
            switch error {
            case .outOfRange:
                UDToast.showWarning(with: I18n.Calendar_Event_TimeUpperLimit, on: view)
            case .notSupported:
                UDToast.showWarning(with: I18n.Calendar_Event_ThisNoZeroMin, on: view)
            case .startEndError:
                UDToast.showWarning(with: I18n.Calendar_Event_CheckNoEarlyThanStartHover, on: view)
            }
        } else {
            self.delegate?.didFinishEdit(from: self)
        }
    }
}

extension EventCheckInTimeSelectViewController: UDWheelPickerViewDelegate, UDWheelPickerViewDataSource {

    var startText: String {
        switch viewModel.timeSelectType {
        case .startTime: return I18n.Calendar_Event_StartNowDropMenu
        case .endTime: return I18n.Calendar_Event_EndNowDropMenu
        }
    }

    private func redirectWheelPicker() {
        let timeMode = viewModel.currentTimeMode

        for column in viewModel.wheelMode {
            switch column {
            case .timeEnum: // redirect timeEnum
                if let index = viewModel.timeEnumsColumn.firstIndex(of: timeMode.timeEnum) {
                    self.wheelPicker.select(in: 0, at: index, animated: true)
                } else {
                    self.wheelPicker.select(in: 0, at: 1, animated: true)
                    assertionFailureLog("redirect timeEnum error")
                }
            case .timeHour: // redirect hour
                if let index = viewModel.timeHoursColumn.firstIndex(of: timeMode.hour) {
                    self.wheelPicker.select(in: 1, at: index, animated: true)
                } else {
                    self.wheelPicker.select(in: 1, at: 0, animated: true)
                    assertionFailureLog("redirect timeScale error")
                }
            case .timeMinutes: // redirect minutes
                if let index = viewModel.timeMinutesColumn.firstIndex(of: timeMode.minutes) {
                    self.wheelPicker.select(in: 2, at: index, animated: true)
                } else {
                    self.wheelPicker.select(in: 2, at: 0, animated: true)
                    assertionFailureLog("redirect timeGranularity error")
                }
            }
        }
    }

    public func wheelPickerView(_ wheelPicker: UDWheelPickerView, widthForColumn column: Int) -> CGFloat {
        // 比例为 timeEnum : timeHour : timeMinutes = 2 : 1 : 1
        switch viewModel.wheelMode[column] {
        case .timeEnum:
            return view.bounds.width / 2.0
        case .timeHour, .timeMinutes:
            return view.bounds.width / 4.0
        }
    }

    func wheelPickerView(_ wheelPicker: UDWheelPickerView, modeOfColumn column: Int) -> UDWheelCircelMode {
        if case .timeEnum = viewModel.wheelMode[column] {
            return .limited
        }
        return .circular
    }

    func wheelPickerView(_ wheelPicker: UDWheelPickerView, viewForRow row: Int, atColumn column: Int) -> UDWheelPickerCell {
        guard column < viewModel.wheelMode.count else {
            return CheckInPickerCell()
        }
        let cell = CheckInPickerCell()
        var text: NSAttributedString
        switch viewModel.wheelMode[column] {
        case .timeEnum:
            let count = self.viewModel.timeEnumsColumn.count
            text = NSAttributedString(string: viewModel.timeEnumsColumn[row]?.description ?? "",
                                      attributes: [.font: UDFont.systemFont(ofSize: 17)])
        case .timeHour:
            let count = self.viewModel.timeHoursColumn.count
            let hour = viewModel.timeHoursColumn[row % count]
            text = NSAttributedString(string: String(hour),
                                      attributes: [.font: UDFont.systemFont(ofSize: 17)])
        case .timeMinutes:
            let count = self.viewModel.timeMinutesColumn.count
            let minutes = viewModel.timeMinutesColumn[row % count]
            text = NSAttributedString(string: String(minutes),
                                      attributes: [.font: UDFont.systemFont(ofSize: 17)])
        }
        cell.labelAttributedString = text
        return cell
    }

    func wheelPickerView(_ wheelPicker: UDWheelPickerView, numberOfRowsInColumn column: Int) -> Int {
        switch viewModel.wheelMode[column] {
        case .timeEnum:
            return viewModel.timeEnumsColumn.count
        case .timeHour:
            return viewModel.timeHoursColumn.count
        case .timeMinutes:
            return viewModel.timeMinutesColumn.count
        }
    }

    func numberOfCloumn(in wheelPicker: UDWheelPickerView) -> Int {
        return viewModel.wheelMode.count
    }

    func wheelPickerView(_ wheelPicker: UniverseDesignDatePicker.UDWheelPickerView, didSelectIndex index: Int, atColumn column: Int) {
        let columnType = viewModel.wheelMode[column]
        switch columnType {
        case .timeEnum:
            self.viewModel.updateTimeEnumWith(index: index + 2) // index 偏移 2，因 datePicker 顶部设置 2 行空白
            redirectWheelPicker()
        case .timeHour:
            let count = self.viewModel.timeHoursColumn.count
            self.viewModel.updateTimeHourWith(index: (index + 2) % count)
        case .timeMinutes:
            let count = self.viewModel.timeMinutesColumn.count
            self.viewModel.updateTimeMinutesWith(index: (index + 2) % count)
        }

        // 更新副标题
        updateSubTitle()
    }
}
