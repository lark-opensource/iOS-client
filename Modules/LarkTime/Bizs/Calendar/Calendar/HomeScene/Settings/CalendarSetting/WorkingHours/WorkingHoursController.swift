//
//  WorkingHoursController.swift
//  Calendar
//
//  Created by zhouyuan on 2019/5/14.
//
import UIKit
import RxSwift
import RxCocoa
import Foundation
import LarkLocalizations
import LarkTimeFormatUtils
import FigmaKit
import LarkUIKit

final class WorkingHoursController: BaseUIViewController {
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    private lazy var enableWorkingHoursView: SettingView = {
        let view = SettingView(switchSelector: #selector(enableWorkingHours(sender:)),
                               target: self,
                               title: BundleI18n.Calendar.Calendar_Workinghours_Enablewh)
        return view
    }()
    private lazy var enableTipsLabel: UILabel = {
        return WorkingHoursController.getTipLabel(text: BundleI18n.Calendar.Calendar_NewSettings_EnableMyWorkingHoursDescriptionMobile)
    }()
    private var isFirstPickTime = true
    private lazy var setWorkingHoursView: SetWorkingHoursView = {
        let view = SetWorkingHoursView(firstWeekday: workingHoursModel.firstWeekday)
        view.enableDaysOfWeek = { [unowned self] (enable, daysOfWeek) in
            if enable {
                self.workingHoursModel.addWorkHourItem(daysOfWeek: daysOfWeek)
            } else {
                self.workingHoursModel.deleteWorkHourItem(daysOfWeek: daysOfWeek)
            }
            self.loadData(workingHoursModel: self.workingHoursModel)
        }
        view.spanTimeTaped = { [unowned self] (daysOfWeek, span: SettingModel.WorkHourSpan) in
            self.pickWorkTime(weekdayText: TimeFormatUtils.weekdayShortString(weekday: daysOfWeek.rawValue),
                              startTime: Int(span.startMinute),
                              endTime: Int(span.endMinute),
                              is12HourStyle: self.workingHoursModel.is12HourStyle,
                              isMeridiemIndicatorAheadOfTime: self.isMeridiemIndicatorAheadOfTime,
                              completed: { (startMinute, endMinute) in
                self.workingHoursModel.updateWorkHourItem(daysOfWeek: daysOfWeek,
                                                          startMinute: startMinute,
                                                          endMinute: endMinute)
                self.loadData(workingHoursModel: self.workingHoursModel)
                if self.isFirstPickTime {
                    self.copyWorkTimeToOtherWeekdays(startMinute: startMinute,
                                                     endMinute: endMinute)
                }
                self.isFirstPickTime = false

            })
        }
        return view
    }()

    private var workingHoursModel: WorkingHoursModel
    var workingHoursSettingChanged: ((SettingModel.WorkHourSetting,
    _ onError: @escaping (SettingModel.WorkHourSetting) -> Void) -> Void)?
    private let disposeBag = DisposeBag()
    private let is12HourStyle: BehaviorRelay<Bool>
    /// AM/PM 时间区分缩写统称为 Meridiem Indicator
    private let isMeridiemIndicatorAheadOfTime = TimeFormatUtils.languagesListForAheadMeridiemIndicator.contains(LanguageManager.currentLanguage)
    init(firstWeekday: DaysOfWeek,
         is12HourStyle: BehaviorRelay<Bool>,
         workHourSetting: SettingModel.WorkHourSetting) {
        self.workingHoursModel = WorkingHoursModel(firstWeekday: firstWeekday,
                                                   is12HourStyle: is12HourStyle.value,
                                                   workHourSetting: workHourSetting)
        self.is12HourStyle = is12HourStyle
        super.init(nibName: nil, bundle: nil)
        self.title = BundleI18n.Calendar.Calendar_NewSettings_WorkingHoursMobile
        is12HourStyle.asDriver().skip(1).drive(onNext: { [weak self] (is12HourStyle) in
            guard let `self` = self else { return }
            self.workingHoursModel.changeIs12HourStyle(is12HourStyle: is12HourStyle)
            self.loadData(workingHoursModel: self.workingHoursModel)
        }).disposed(by: disposeBag)
        addBackItem()
        view.backgroundColor = UIColor.ud.bgFloatBase
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        layoutEnableWorkingHoursView(enableWorkingHoursView)
        view.addSubview(enableTipsLabel)
        enableTipsLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalTo(enableWorkingHoursView.snp.bottom).offset(14)
        }

        view.addSubview(setWorkingHoursView)
        setWorkingHoursView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(enableTipsLabel.snp.bottom).offset(2)
        }

        workingHoursModel.settingChanged = { [weak self] (workHourSetting) in
            self?.workingHoursSettingChanged?(workHourSetting) { [weak self] oldWorkHourSetting in
                guard let self = self else { return }
                self.workingHoursModel.resetWorkHourSetting(oldWorkHourSetting)
                self.loadData(workingHoursModel: self.workingHoursModel)
            }
        }
        loadData(workingHoursModel: self.workingHoursModel)

        enableWorkingHoursView.layer.cornerRadius = 10
        setWorkingHoursView.layer.cornerRadius = 10
    }

    private func copyWorkTimeToOtherWeekdays(startMinute: Int32,
                                             endMinute: Int32) {
        let alert = UIAlertController(title: BundleI18n.Calendar.Calendar_Workinghours_Popup, message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: BundleI18n.Calendar.Calendar_Common_Confirm, style: .default) { [unowned self] (_) in
            CalendarTracer.shareInstance.calSettingCopyWorkTime()
            self.workingHoursModel.resetAllWorkItem(startMinute: startMinute,
                                                     endMinute: endMinute)
            self.loadData(workingHoursModel: self.workingHoursModel)
        }
        alert.addAction(confirmAction)
        let cancelAction = UIAlertAction(title: BundleI18n.Calendar.Calendar_Common_Cancel, style: .cancel) { _ in
        }
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }

    class func getTipLabel(text: String) -> UILabel {
        let label = UILabel.cd.textLabel(fontSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = text
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }

    private func pickWorkTime(weekdayText: String,
                              startTime: Int,
                              endTime: Int,
                              is12HourStyle: Bool,
                              isMeridiemIndicatorAheadOfTime: Bool,
                              completed: @escaping (Int32, Int32) -> Void) {
        let picker = WorkTimePicker(weekDay: weekdayText,
                                    startTime: startTime,
                                    endTime: endTime,
                                    is12HourStyle: is12HourStyle,
                                    isMeridiemIndicatorAheadOfTime: isMeridiemIndicatorAheadOfTime,
                                    displayWidth: self.view.frame.width,
                                    selection: { (startTime: Int, endTime: Int) in
                                        completed(Int32(startTime), Int32(endTime))
        }, errorSelection: { (currentVC) in
            let alert = UIAlertController(title: BundleI18n.Calendar.Calendar_Edit_Alert,
                                          message: BundleI18n.Calendar.Calendar_Edit_InvalidEndTime,
                                          preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: BundleI18n.Calendar.Calendar_Common_OK, style: .default)
            alert.addAction(confirmAction)
            currentVC.present(alert, animated: true, completion: nil)
        })
        picker.show(in: self)
    }

    private func loadData(workingHoursModel: WorkingHoursModel) {
        enableWorkingHoursView.update(switchIsOn: workingHoursModel.enableWorkHour())
        setWorkingHoursView.isHidden = !workingHoursModel.enableWorkHour()
        setWorkingHoursView.setContent(workingHoursModel.getSetWorkingHoursViewContent(),
                                       is12HourStyle: workingHoursModel.is12HourStyle)
    }

    private func layoutEnableWorkingHoursView(_ enableWorkingHoursView: SettingView) {
        view.addSubview(enableWorkingHoursView)
        enableWorkingHoursView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(26)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(52)
        }
    }

    @objc
    private func enableWorkingHours(sender: UISwitch) {
        workingHoursModel.changeEnableWorkHour(sender.isOn)
        loadData(workingHoursModel: workingHoursModel)
        CalendarTracer.shareInstance.calSettingWorkHour(actionTargetStatus: .init(isOn: sender.isOn))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
