//
//  SearchNoPermissionPreviewAlert.swift
//  LarkSearchCore
//
//  Created by ByteDance on 2022/9/14.
//

import UIKit
import Foundation
import LarkAlertController
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast
import LKCommonsLogging
import UniverseDesignDialog
import LarkModel
import LarkAccountInterface
import LarkFeatureGating

public struct SearchNoPermissionPreviewAlert {
    public enum NoPermissionLayerType {
        case image
        case video
        case file
    }

    public static func getAlertViewController(_ type: SearchNoPermissionPreviewAlert.NoPermissionLayerType) -> LarkAlertController {
        let alertController = LarkAlertController()
        let contentText: String
        switch type {
        case .image: contentText = BundleI18n.LarkSearchCore.Lark_IM_UnableToPreviewImage_PopUpDesc
        case .video: contentText = BundleI18n.LarkSearchCore.Lark_IM_UnableToPreviewVideo_PopUpDesc
        case .file: contentText = BundleI18n.LarkSearchCore.Lark_IM_UnableToPreviewFile_PopUpDesc
        }
        alertController.setTitle(text: BundleI18n.LarkSearchCore.Lark_IM_UnableToPreview_PopUpTitle)
        alertController.setContent(text: contentText)
        alertController.addPrimaryButton(text: BundleI18n.LarkSearchCore.Lark_IM_UnableToPreview_PopUpButton, dismissCompletion: nil)
        return alertController
    }
}
