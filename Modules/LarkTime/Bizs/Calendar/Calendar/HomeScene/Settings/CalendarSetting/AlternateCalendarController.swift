//
//  AlternateCalendarController.swift
//  Calendar
//
//  Created by yantao on 2020/3/3.
//

import UIKit
import Foundation
import CalendarFoundation
import FigmaKit
import LarkUIKit

final class AlternateCalendarController: BaseUIViewController {
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    let pickerView: AlternateCalendarPicker
    init(alternateCalendar: AlternateCalendarEnum,
         selectedCallBack: @escaping ((AlternateCalendarEnum) -> Void)) {
        pickerView = AlternateCalendarPicker(alternateCalendar: alternateCalendar,
                                             doneCallBack: { alternateCalendar in
            selectedCallBack(alternateCalendar)
        })
        super.init(nibName: nil, bundle: nil)
        self.title = BundleI18n.Calendar.Calendar_NewSettings_UseAlternateCalendar
        view.backgroundColor = UIColor.ud.bgFloatBase
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackItem()
        self.view.addSubview(pickerView)
        pickerView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(12)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
