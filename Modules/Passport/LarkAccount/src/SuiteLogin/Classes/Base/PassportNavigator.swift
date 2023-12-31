//
//  PassportNavigator.swift
//  LarkAccount
//
//  Created by bytedance on 2022/4/27.
//

import Foundation
import UIKit
import EENavigator
import LarkContainer
import LarkAccountInterface

struct PassportNavigator {


    static var usePassportNavigator: Bool {
        PassportStore.shared.configInfo?.config().getEnablePassportNavigator() ?? V3NormalConfig.defaultEnablePassportNavigator
    }

    // MARK: - Global Scope Navigator

    static var keyWindow: UIWindow? {

        guard usePassportNavigator else {
            return Navigator.shared.mainSceneWindow // user:checked (navigator)
        }
        //如果存在条件访问控制的 window，使用条件访问的window
        if let scWindow = implicitResolver?.resolve(SecurityComplianceDependency.self)?.securityComplianceWindow() { // user:checked
            return scWindow
        } else {
            return Navigator.shared.mainSceneWindow // user:checked (navigator)
        }
    }

    static var topMostVC: UIViewController? {

        guard usePassportNavigator else {
            return Navigator.shared.mainSceneTopMost // user:checked (navigator)
        }
        return UIViewController.topMost(of: keyWindow?.rootViewController, checkSupport: true)
    }

    // MARK: - User Scope Navigator

    static func getUserScopeKeyWindow(userResolver: UserResolver) -> UIWindow? {
        guard PassportUserScope.enableUserScopeTransitionAccount else {
            // 用户态关闭
            return keyWindow
        }

        guard usePassportNavigator else {
            return userResolver.navigator.mainSceneWindow
        }
        // 如果存在条件访问控制的 window，使用条件访问的window
        // 需要确认是否有用户态的 window
        if let scWindow = implicitResolver?.resolve(SecurityComplianceDependency.self)?.securityComplianceWindow() { // user:checked (global-resolve)
            return scWindow
        } else {
            return userResolver.navigator.mainSceneWindow
        }
    }

    static func getUserScopeTopMostVC(userResolver: UserResolver) -> UIViewController? {
        guard PassportUserScope.enableUserScopeTransitionAccount else {
            // 用户态关闭
            return topMostVC
        }

        guard usePassportNavigator else {
            return userResolver.navigator.mainSceneTopMost
        }
        return UIViewController.topMost(of: keyWindow?.rootViewController, checkSupport: true)
    }
}
