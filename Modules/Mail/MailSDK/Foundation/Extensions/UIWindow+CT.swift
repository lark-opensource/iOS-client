//
//  Window+CT.swift
//  DocsSDK
//
//  Created by nine on 2019/1/29.
//

import Foundation

extension UIWindow: MailExtensionCompatible {}

extension MailExtension where BaseType == UIWindow {
    // 包含rootVC的windows
    @available(*, deprecated, message: "deprecated! get ui context first")
    class var rootWindow: UIWindow? {
        let validRootWindows = UIApplication.shared.windows.filter { $0.rootViewController != nil }
        return validRootWindows.first
    }
}
