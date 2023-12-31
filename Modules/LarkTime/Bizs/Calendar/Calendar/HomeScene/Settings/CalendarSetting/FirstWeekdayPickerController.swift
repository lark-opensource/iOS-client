//
//  FirstWeekdayPickerController.swift
//  Calendar
//
//  Created by harry zou on 2019/2/15.
//

import UIKit
import Foundation
import CalendarFoundation
import FigmaKit
import LarkUIKit

final class FirstWeekdayPickerController: BaseUIViewController {
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }
    let pickerView: FirstWeekdayPicker
    init(firstWeekday: DaysOfWeek, selectedCallBack: @escaping ((DaysOfWeek) -> Void)) {
        pickerView = FirstWeekdayPicker(firstWeekday: firstWeekday, doneCallBack: { firstWeekday in
            selectedCallBack(firstWeekday)
        })
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = UIColor.ud.bgFloatBase
        title = BundleI18n.Calendar.Calendar_NewSettings_FirstDayOfWeek
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackItem()
        self.view.addSubview(pickerView)
        pickerView.snp.makeConstraints({ $0.edges.equalToSuperview() })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
