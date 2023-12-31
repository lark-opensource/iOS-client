//
//  BTJSService+CTA.swift
//  SKBitable
//
//  Created by X-MAN on 2023/2/9.
//

import Foundation
import SKCommon
import SKFoundation
import UniverseDesignToast
import LarkReleaseConfig
import SKResource
import EENavigator
import SKUIKit
import SKInfra

extension BTJSService {

    func contactService(_ params: [String: Any]) {
        if let hostVC = navigator?.currentBrowserVC {
            let service = LarkOpenEvent.customerService(controller: hostVC)
            NotificationCenter.default.post(name: Notification.Name(DocsSDK.mediatorNotification), object: service)
        } else {
            DocsLogger.error("contactService error, navigator?.currentBrowserVC is nil")
        }
    }
    
    func goToProfile(_ params: [String: Any]) {
        if let token = params["token"] as? String {
            if let hostVC = navigator?.currentBrowserVC {
                BTUtil.forceInterfaceOrientationIfNeed(to: .portrait)
                HostAppBridge.shared.call(ShowUserProfileService(userId: token, fromVC: hostVC))
            } else {
                DocsLogger.error("goToProfile error, navigator?.currentBrowserVC is nil")
            }
        } else {
            DocsLogger.error("goToProfile error, token is nil")
        }
        
    }
}
