//
//  UserDeniedOrLocationDisableAlert.swift
//  OPPlugin
//
//  Created by zhangxudong on 5/6/22.
//

import OPSDK
import OPPluginManagerAdapter
import OPFoundation
import UniverseDesignDialog
import LarkOpenPluginManager
import LarkOpenAPIModel

protocol UserDeniedOrLocationDisableAlert: AnyObject {
    var didShowAlertDenied: Bool { get set }
    var didShowAlertEnabled: Bool  { get set }
}

extension UserDeniedOrLocationDisableAlert {
    func alertUserDeniedOrLocDisable(context: OpenAPIContext, isUserDenied: Bool, fromController: UIViewController?) {
            context.apiTrace.info("alertUserDeniedOrLocDisable, isUserDenied=\(isUserDenied)", tag: "Location", additionalData: nil, error: nil)
            let title = BDPI18n.permissions_no_access
            var description = BDPI18n.permissions_location_services_on
            if isUserDenied {
                if didShowAlertDenied {
                    return
                }
                didShowAlertDenied = true
                let appName = OPSafeObject(BDPSandBoxHelper.appDisplayName(), "")
                description = String(format: BDPI18n.permissions_location_services_access, appName)
            } else {
                if (didShowAlertEnabled) {
                    return
                }
                didShowAlertEnabled = true
            }

            // 适配DarkMode:使用主端提供的UDDilog
            let alertController = UDDialog()
            alertController.setTitle(text: title ?? "")
            alertController.setContent(text: description ?? "")
            alertController.addSecondaryButton(text: BDPI18n.cancel)
            alertController.addPrimaryButton(text: BDPI18n.microapp_m_permission_go_to_settings, dismissCompletion: {
                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                UIApplication.shared.open(url)
            })
            executeOnMainQueueAsync {
                let window = fromController?.view.window ?? OPWindowHelper.fincMainSceneWindow()
                if BDPDeviceHelper.isPadDevice() {
                    if let popPresenter = alertController.popoverPresentationController {
                        popPresenter.sourceView = window
                        if let window = window {
                            popPresenter.sourceRect = window.bounds
                        }
                    }
                }
                let topVC = BDPResponderHelper.topViewController(for: BDPResponderHelper.topmostView(window))
                alertController.isAutorotatable = UDRotation.isAutorotate(from: topVC)
                topVC?.present(alertController, animated: true, completion: nil)
            }
        }
}
