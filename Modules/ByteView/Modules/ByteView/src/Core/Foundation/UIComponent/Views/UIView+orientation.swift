//
//  UIView+orientation.swift
//  ByteView
//
//  Created by helijian.666 on 2023/7/26.
//

import Foundation
import ByteViewCommon
import ByteViewUI

extension UIView {
    var isPhoneLandscape: Bool {
        Display.phone && !isPhonePortrait
    }

    var isPhonePortrait: Bool {
        guard Display.phone else { return false }
        // 优先取windowScene的interfaceOrientation
        return orientation?.isPortrait ?? (traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular)
    }

    var isRegular: Bool {
        traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular
    }

    var orientation: UIInterfaceOrientation? {
        if #available(iOS 13.0, *) {
            if let scene = self.window?.windowScene {
                return scene.interfaceOrientation
            } else if let scene = UIApplication.shared.connectedScenes.first(where: { (scene) -> Bool in
                return scene.activationState == .foregroundActive && scene.session.role == .windowApplication
            }) as? UIWindowScene {
                // 尽量给一个相对正确的值
                return scene.interfaceOrientation
            }
            return nil
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }

    var isLandscape: Bool {
        orientation?.isLandscape ?? (Display.pad ? true : false)
    }
}
