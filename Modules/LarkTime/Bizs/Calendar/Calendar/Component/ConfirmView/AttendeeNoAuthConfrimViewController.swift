//
//  AttendeeNoAuthConfrimViewController.swift
//  Calendar
//
//  Created by harry zou on 2018/12/9.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkAlertController

final class AttendeeNoAuthConfrimViewController {
    class func getViewController() -> UIViewController {
        let alertVC = LarkAlertController()
        alertVC.setTitle(text: BundleI18n.Calendar.Calendar_Common_Notice)
        alertVC.setContent(text: BundleI18n.Calendar.Calendar_Detail_GroupHiddedTip, color: UIColor.ud.N600)
        alertVC.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Common_Confirm)
        return alertVC
    }
}
