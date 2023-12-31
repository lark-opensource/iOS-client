//
//  UnsubscribeAlert.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/11.
//  Copyright © 2019 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkActionSheet
import LarkAlertController

protocol UnsubscribeAlert {
    func showAlert(in controller: UIViewController, confirmAction: @escaping () -> Void)
}

extension UnsubscribeAlert {
    func showAlert(in controller: UIViewController, confirmAction: @escaping () -> Void) {
        let title = BundleI18n.Calendar.Calendar_SubscribeCalendar_OwnerUnsubscribePopUpWindowTitle
        let message = BundleI18n.Calendar.Calendar_Setting_OwnerUnsubscribePopUpWindow

        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.setContent(text: message)
        alertController.addSecondaryButton(text: BundleI18n.Calendar.Calendar_Common_Cancel)
        alertController.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Common_Confirm, dismissCompletion:  {
            confirmAction()
        })
        controller.present(alertController, animated: true)
    }
}
