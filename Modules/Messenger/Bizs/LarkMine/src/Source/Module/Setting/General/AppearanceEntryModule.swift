//
//  AppearanceEntryModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/29.
//

import Foundation
import UIKit
import EENavigator
import UniverseDesignTheme
import LarkOpenSetting
import LarkSettingUI
import LarkContainer

@available(iOS 13.0, *)
final class AppearanceEntryModule: BaseModule {

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        NotificationCenter.default.rx
            .notification(UDThemeManager.didChangeNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.context?.reload()
            })
            .disposed(by: disposeBag)
    }

    override func createCellProps(_ key: String) -> [CellProp]? {
        var currentTheme = BundleI18n.LarkMine.Lark_Settings_DisplayFollowSystem
        switch UDThemeManager.userInterfaceStyle {
        case .unspecified:
            currentTheme = BundleI18n.LarkMine.Lark_Settings_DisplayFollowSystem
        case .light:
            currentTheme = BundleI18n.LarkMine.Lark_Settings_DisplayLight
        case .dark:
            currentTheme = BundleI18n.LarkMine.Lark_Settings_DisplayDark
        @unknown default:
            break
        }
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_Settings_DisplayAppearanceSubtitle, accessories: [.text(currentTheme), .arrow()]) { [weak self] _ in
            guard let vc = self?.context?.vc else { return }
            self?.userResolver.navigator.push(ThemeSettingViewController(), from: vc)
        }
        return [item]
    }
}
