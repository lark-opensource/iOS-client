//
//  EventDurationPickerController.swift
//  Calendar
//
//  Created by zc on 2018/5/24.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import CalendarFoundation
import LarkUIKit
final class EventDurationPickerController: BaseUIViewController {
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    var selectCallBack: ((Int) -> Void)?
    let pickerView: EventDurationPicker
    init(duration: Int) {
        pickerView = EventDurationPicker(duration: duration)
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = UIColor.ud.bgFloatBase
        title = BundleI18n.Calendar.Calendar_NewSettings_DefaultEventDuration
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackItem()
        self.view.addSubview(pickerView)
        pickerView.snp.makeConstraints({ $0.edges.equalToSuperview() })
        pickerView.doneCallBack = { [weak self] duration in
            self?.selectCallBack?(duration)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
