//
//  SettingReminderPickerController.swift
//  Calendar
//
//  Created by zc on 2018/5/24.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CalendarFoundation
import LarkUIKit
import FigmaKit

final class SettingReminderPickerController: BaseUIViewController {
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    var selectCallBack: ((Reminder?) -> Void)?

    private let pickerView: NewEventReminderPicker
    init(reminder: Reminder?, isAllday: Bool, is12HourStyle: BehaviorRelay<Bool>) {
        let title = isAllday ? BundleI18n.Calendar.Calendar_NewSettings_EventReminderAllDayMobile : BundleI18n.Calendar.Calendar_NewSettings_EventReminderNotAllDayMobile
        var reminders = [Reminder]()
        if let reminder = reminder {
            reminders.append(reminder)
        }

        pickerView = NewEventReminderPicker(
                            reminders: reminders,
                            isAllDay: isAllday,
                            allowsMultipleSelection: false,
                            is12HourStyle: is12HourStyle)
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackItem()
        self.view.addSubview(pickerView)
        pickerView.snp.makeConstraints({ $0.edges.equalToSuperview() })
        pickerView.doneCallBack = { [weak self] reminders in
            self?.selectCallBack?(reminders.first)
        }
        view.backgroundColor = UIColor.ud.bgFloatBase
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
