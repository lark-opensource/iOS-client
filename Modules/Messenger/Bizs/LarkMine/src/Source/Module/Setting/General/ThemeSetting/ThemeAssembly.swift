//
//  ThemeAssembly.swift
//  LarkMine
//
//  Created by bytedance on 2021/4/28.
//

import UIKit
import Foundation
import Swinject
import RxSwift
import BootManager
import Homeric
import LKCommonsTracker
import UniverseDesignTheme
import UniverseDesignColor
import LarkAssembler

public final class ThemeAssembly: LarkAssemblyInterface {

    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(NewThemeAnalyticsTask.self)
    }
}

final class NewThemeAnalyticsTask: UserFlowBootTask, Identifiable {

    static var identify: TaskIdentify = "ThemeAnalyticsTask"

    override var scheduler: Scheduler { return .main }

    override func execute(_ context: BootContext) {
        UDColor.registerToken()

        // Analytics
        Tracker.post(TeaEvent(Homeric.SETTING_OS_APPR_MODE_VIEW, params: [
            "os_mode": systemAppearance,
            "is_mode": isDarkModeSupported
        ]))
        // Analytics
        Tracker.post(TeaEvent(Homeric.SETTING_APP_APPR_MODE_VIEW, params: [
            "real_mode": realAppearance,
            "os_mode": systemAppearance,
            "app_mode": appAppearance,
            "upload_type": "open"  // 上报类型：冷启动上报
        ]))
    }

    private var systemAppearance: String {
        if #available(iOS 13.0, *) {
            switch UIScreen.main.traitCollection.userInterfaceStyle {
            case .dark: return "dark"
            default:    return "light"
            }
        }
        return "light"
    }

    private var isDarkModeSupported: String {
        if #available(iOS 13.0, *) {
            return "true"
        } else {
            return "false"
        }
    }

    private var appAppearance: String {
        if #available(iOS 13.0, *) {
            switch UDThemeManager.userInterfaceStyle {
            case .light:    return "light"
            case .dark:     return "dark"
            default:        return "default"
            }
        }
        return "light"
    }

    private var realAppearance: String {
        guard let keyWindow = UIApplication.shared.keyWindow else {
            return "light"
        }
        if #available(iOS 13.0, *) {
            switch keyWindow.traitCollection.userInterfaceStyle {
            case .dark: return "dark"
            default:    return "light"
            }
        } else {
            return "light"
        }
    }
}
