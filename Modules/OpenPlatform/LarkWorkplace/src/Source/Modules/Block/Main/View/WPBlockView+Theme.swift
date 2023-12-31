//
//  WPBlockView+Theme.swift
//  LarkWorkplace
//
//  Created by doujian on 2022/7/1.
//

import UniverseDesignTheme

extension WPBlockView {
    func themeDidChange() {
        if #available(iOS 13.0, *) {
            let theme: String?
            switch UDThemeManager.getRealUserInterfaceStyle() {
            case .light:
                theme = "light"
                break
            case .dark:
                theme = "dark"
                break
            default:
                theme = nil
                break
            }
            if let str = theme {
                innerBlockContainer?.notifyThemeChange(theme: str)
            }
        }
    }
}
