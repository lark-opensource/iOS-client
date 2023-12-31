//
//  EventCheckInSettingViewController.swift
//  Calendar
//
//  Created by huoyunjie on 2022/9/13.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignColor

protocol EventCheckInSettingViewControllerDelegate: AnyObject {
    func didFinishEdit(from viewController: EventCheckInSettingViewController)
    func didCancelEdit(from viewController: EventCheckInSettingViewController)
}

class EventCheckInSettingViewController: BaseUIViewController {

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }

    typealias CheckInConfig = Rust.CheckInConfig
    typealias CheckInTime = CheckInConfig.CheckInTime

    weak var delegate: EventCheckInSettingViewControllerDelegate?

    private let disposeBag = DisposeBag()

    // 暴露给外部获取
    let viewModel: EventCheckInSettingViewModel

    // 签到开关
    let checkInCell = CheckInConfigSwitchCell()

    var bottomContainer: UIView?
    let doneItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Done, fontStyle: .medium)

    // view 相关
    let startTimeGoToCell = CheckInConfigGoToCell()
    let endTimeGoToCell = CheckInConfigGoToCell()
    let absoluteTimeTitleCell = CheckInConfigTitleCell()
    let notificationSwitchCell = CheckInConfigSwitchCell()

    init(viewModel: EventCheckInSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = I18n.Calendar_Event_CheckInSettingsTitle
        view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground
        setupNaviBar()
        setupView()
        updateContent()
        bindViewAction()

        CalendarTracerV2.CheckInSetting.traceView {
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.viewModel.eventModel.getPBModel()))
        }
    }

    private func setupNaviBar() {
        let cancelItem = LKBarButtonItem(
            title: BundleI18n.Calendar.Calendar_Common_Cancel
        )
        navigationItem.leftBarButtonItem = cancelItem
        cancelItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.delegate?.didCancelEdit(from: self)
            }.disposed(by: disposeBag)

        let doneItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Done, fontStyle: .medium)
        doneItem.button.tintColor = UIColor.ud.primaryContentDefault
        navigationItem.rightBarButtonItem = doneItem
        doneItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.doneTrace()
                self.delegate?.didFinishEdit(from: self)
            }.disposed(by: disposeBag)
    }

    private func setupView() {
        view.addSubview(checkInCell)
        checkInCell.layer.cornerRadius = 10
        checkInCell.layer.masksToBounds = true
        checkInCell.setTitle(title: I18n.Calendar_MeetingRoom_CheckInButton)
        checkInCell.snp.makeConstraints { make in
            make.top.equalTo(12)
            make.left.right.equalToSuperview()
            make.height.equalTo(48)
        }

        let stackView = UIStackView(arrangedSubviews: [
            EventBasicDivideView(),
            startTimeGoToCell,
            endTimeGoToCell,
            absoluteTimeTitleCell,
            EventBasicDivideView(),
            notificationSwitchCell]
        )
        self.bottomContainer = stackView
        stackView.axis = .vertical

        startTimeGoToCell.setTitle(title: I18n.Calendar_Edit_StartTime)
        endTimeGoToCell.setTitle(title: I18n.Calendar_Edit_EndTime)
        absoluteTimeTitleCell.setTitle(title: I18n.Calendar_Event_CheckInTimeDuration(timeString: self.viewModel.getAbsoluteTimeStr()))
        notificationSwitchCell.setTitle(title: I18n.Calendar_Event_SendCheckInNotify)
        notificationSwitchCell.setSubTitle(title: I18n.Calendar_Event_CheckInInfoSentNote)

        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalTo(checkInCell.snp.bottom)
            make.left.right.equalToSuperview()
        }
    }

    private func bindViewAction() {
        startTimeGoToCell.click = { [weak self] in
            self?.goToTimeSelectVC(type: .startTime)
        }

        endTimeGoToCell.click = { [weak self] in
            self?.goToTimeSelectVC(type: .endTime)
        }

        // 切换签到cell的开关，显示/隐藏底部的设置项
        checkInCell.rxIsOn
            .bind { [weak self] isOn in
                self?.bottomContainer?.isHidden = !isOn
                self?.viewModel.checkInConfig.checkInEnable = isOn
            }.disposed(by: disposeBag)

        notificationSwitchCell.rxIsOn.skip(1)
            .bind { [weak self] isOn in
                self?.viewModel.checkInConfig.needNotifyAttendees = isOn
            }.disposed(by: disposeBag)
    }

    private func goToTimeSelectVC(type: EventCheckInTimeSelectViewModel.TimeSelectType) {
        let checkInTime: CheckInConfig.CheckInTime
        let timeIsValid: (CheckInTime) -> Bool
        var checkInConfig = self.viewModel.checkInConfig
        let sourceView: UIView
        switch type {
        case .startTime:
            sourceView = startTimeGoToCell
            checkInTime = checkInConfig.checkInStartTime
            timeIsValid = { [weak self] startTime in
                guard let self = self else { return false }
                checkInConfig.checkInStartTime = startTime
                return checkInConfig.startAndEndTimeIsValid(startDate: self.viewModel.startDate, endDate: self.viewModel.endDate)
            }
        case .endTime:
            sourceView = endTimeGoToCell
            checkInTime = checkInConfig.checkInEndTime
            timeIsValid = { [weak self] endTime in
                guard let self = self else { return false }
                checkInConfig.checkInEndTime = endTime
                return checkInConfig.startAndEndTimeIsValid(startDate: self.viewModel.startDate, endDate: self.viewModel.endDate)
            }
        }

        let vm = EventCheckInTimeSelectViewModel(timeSelectType: type, checkInTime: checkInTime, timeIsValid: timeIsValid)
        let vc = EventCheckInTimeSelectViewController(sourceView: sourceView, viewModel: vm)
        vc.delegate = self
        self.present(vc, animated: true)

    }

    private func updateContent() {
        checkInCell.switchView.setOn(viewModel.checkInConfig.checkInEnable, animated: false)
        startTimeGoToCell.setSubTitle(title: viewModel.checkInStartTimeStr)
        endTimeGoToCell.setSubTitle(title: viewModel.checkInEndTimeStr)
        notificationSwitchCell.switchView.setOn(viewModel.checkInConfig.needNotifyAttendees, animated: false)
        if self.viewModel.checkInConfigIsValid() {
            self.absoluteTimeTitleCell.setTitle(title: I18n.Calendar_Event_CheckInTimeDuration(timeString: self.viewModel.getAbsoluteTimeStr()), color: UDColor.textPlaceholder)
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            self.absoluteTimeTitleCell.setTitle(title: I18n.Calendar_Event_CheckNoEarlyThanStartHover, color: UDColor.functionDangerContentDefault)
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
}

extension EventCheckInSettingViewController: EventCheckInTimeSelectViewControllerDelegate {
    func didCancelEdit(from: EventCheckInTimeSelectViewController) {
        self.dismiss(animated: true)
    }

    func didFinishEdit(from: EventCheckInTimeSelectViewController) {
        switch from.viewModel.timeSelectType {
        case .startTime:
            self.viewModel.checkInConfig.checkInStartTime = from.viewModel.currentCheckInTime
        case .endTime:
            self.viewModel.checkInConfig.checkInEndTime = from.viewModel.currentCheckInTime
        }
        self.updateContent()
        self.dismiss(animated: true)
    }
}

// MARK: 埋点
extension EventCheckInSettingViewController {

    // 点击完成
    private func doneTrace() {
        let checkInConfig = self.viewModel.checkInConfig
        let checkInStartTime = checkInConfig.checkInStartTime
        let checkInEndTime = checkInConfig.checkInEndTime

        let typeMapStr: [CheckInTime.TypeEnum: String] = [
            .beforeEventStart: "before_event_start",
            .afterEventStart: "after_event_start",
            .afterEventEnd: "after_event_end"
        ]

        CalendarTracerV2.CheckInSetting.traceClick {
            $0.begin_check_in_type = typeMapStr[checkInStartTime.type]
            $0.begin_check_in_time = checkInStartTime.duration
            $0.finish_check_in_type = typeMapStr[checkInEndTime.type]
            $0.finish_check_in_time = checkInEndTime.duration
            $0.is_send = checkInConfig.needNotifyAttendees.description
            $0.is_check = checkInConfig.checkInEnable ? "true" : "false"
            $0.click("done").target("none")
        }
    }
}
