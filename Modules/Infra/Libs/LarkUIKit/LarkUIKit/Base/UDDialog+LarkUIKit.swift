//
//  UDDialog+LarkUIKit.swift
//  LarkUIKit
//
//  Created by bytedance on 202/01/25.
//  Copyright © 2022年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignDialog

extension UDDialog {
    public static func noPermissionDialog(title: String, detail: String,
                                   onClickCancel: (() -> Void)? = nil,
                                   onClickGoToSetting: (() -> Void)? = nil) -> UDDialog {
        let dialog = UDDialog()
        dialog.setTitle(text: title)
        dialog.setContent(text: detail)
        dialog.addSecondaryButton(text: BundleI18n.LarkUIKit.Lark_Legacy_Cancel,
                                  dismissCompletion: {
            onClickCancel?()
        })
        dialog.addPrimaryButton(text: BundleI18n.LarkUIKit.Lark_Legacy_Setting, dismissCompletion: {
            onClickGoToSetting?()
            if let appSettings = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.open(appSettings)
            }
        })
        return dialog
    }
}
