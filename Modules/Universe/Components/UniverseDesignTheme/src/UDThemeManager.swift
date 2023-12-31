//
//  UDThemeManager.swift
//  UniverseDesignTheme
//
//  Created by Hayden on 2021/3/31.
//

import Foundation
import UIKit

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
public final class UDThemeManager: NSObject {

    private static var currentClientId: String = "default"
    private static var storeKey: String { "userIterfaceStyle_\(currentClientId)" }

    public static let didChangeNotification = NSNotification.Name("didChangeNotification")

    static func changeClient(id: String) {
        currentClientId = id
        userInterfaceStyle = getUserInterfaceStyleForCurrentClientOnce()
        overrideUserInterfaceStyle(userInterfaceStyle)
        // TODO: Set theme for client
        // changeTheme()
        // TODO: Set dark mode for client
        postNotification()
    }

    /// The default user interface style.
    public static let defaultUserInterfaceStyle: UIUserInterfaceStyle = .light

    /// The current user interface style adopted by all windows.
    public private(set) static var userInterfaceStyle: UIUserInterfaceStyle =
        getUserInterfaceStyleForCurrentClientOnce()
    
    /// Update `unserInterfaceStyle` of current traitCollection shared by thread to sync with app setting.
    public static func refreshCurrentUserInterfaceStyleIfNeeded() {
        let currentTheme = getSettingUserInterfaceStyle()
        let settingTheme = UITraitCollection.current.userInterfaceStyle
        if currentTheme != settingTheme {
            UITraitCollection.current = .init(userInterfaceStyle: currentTheme)
        }
    }

    private static func getUserInterfaceStyleForCurrentClientOnce() -> UIUserInterfaceStyle {
        // lint:disable lark_storage_check
        let defaults = UserDefaults.standard
        if let value = defaults.object(forKey: storeKey),
           let intValue = value as? Int,
           let style = UIUserInterfaceStyle(rawValue: intValue) {
            return style
        } else {
            return defaultUserInterfaceStyle
        }
        // lint:enable lark_storage_check
    }

    /// The app setting user interface style.
    @objc
    public static func getSettingUserInterfaceStyle() -> UIUserInterfaceStyle {
        return userInterfaceStyle
    }

    /// The real user interface style the app currently use. No 'unspecfied' value.
    @objc
    public static func getRealUserInterfaceStyle() -> UIUserInterfaceStyle {
        switch userInterfaceStyle {
        case .unspecified:
            return UIScreen.main.traitCollection.userInterfaceStyle
        default:
            return userInterfaceStyle
        }
    }

    public static func setUserInterfaceStyle(_ style: UIUserInterfaceStyle) {
        userInterfaceStyle = style
        overrideUserInterfaceStyle(style)
        postNotification()
        // lint:disable lark_storage_check
        let defaults = UserDefaults.standard
        defaults.set(style.rawValue, forKey: storeKey)
        // lint:enable lark_storage_check
    }

    private static func postNotification() {
        NotificationCenter.default.post(name: didChangeNotification, object: userInterfaceStyle)
    }

    public static func overrideUserInterfaceStyle(_ style: UIUserInterfaceStyle) {
        UIApplication.shared.override(style)
    }
}
