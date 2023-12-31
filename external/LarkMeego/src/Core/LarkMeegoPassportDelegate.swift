//
//  LarkMeegoPassportDelegate.swift
//  LarkMeego
//
//  Created by shizhengyu on 2022/12/12.
//

import Foundation
import LarkAccountInterface
import LarkMeegoInterface
import Swinject
import LarkContainer
import LarkMeegoPush
import LarkMeegoNetClient
import LarkMeegoLogger

class LarkMeegoPassportDelegate: PassportDelegate {
    /// online 的原因可能是 login、switch、fastLogin，请注意按需要排除 fastLogin 的场景，避免不需要的逻辑
    func userDidOnline(state: LarkAccountInterface.PassportState) {
        guard let userId = state.user?.userID,
              let userResolver = try? Container.shared.getUserResolver(userID: userId) else {
            MeegoLogger.error("userDidOnline handle failed, userId = \(state.user?.userID ?? "")")
            return
        }
        switch state.action {
        case .fastLogin:
            if let meegoService = try? userResolver.resolve(assert: LarkMeegoService.self) {
                (meegoService as? LarkMeegoServiceImpl)?.fetchMeegoEnableIfNeeded()
            }
        case .login:
            if let meegoService = try? userResolver.resolve(assert: LarkMeegoService.self) {
                (meegoService as? LarkMeegoServiceImpl)?.fetchMeegoEnableIfNeeded()
            }
        case .switch:
            if let meegoService = try? userResolver.resolve(assert: LarkMeegoService.self) {
                (meegoService as? LarkMeegoServiceImpl)?.fetchMeegoEnableIfNeeded()
            }
        case .initialized, .logout: break
        @unknown default: break
        }
    }

    /// offline 的原因可能是 switch、logout
    func userDidOffline(state: LarkAccountInterface.PassportState) {
        switch state.action {
        case .logout:
            MeegoLogger.info("old user did logout, stopPushService")
            MeegoPushNativeService.stopPushService()
            MeegoLogger.info("old user did logout, cleanChannelCookie")
            LarkMeegoNetClient.cleanChannelCookie()
        case .switch:
            MeegoLogger.info("old user did switch, stopPushService")
            MeegoPushNativeService.stopPushService()
            MeegoLogger.info("old user did switch, cleanChannelCookie")
            LarkMeegoNetClient.cleanChannelCookie()
        case .initialized, .login, .fastLogin: break
        @unknown default: break
        }
    }

    /// 用户状态发生变化，包含所有状态的变化
    /// 用户状态分为 online、offline 两种
    func stateDidChange(state: LarkAccountInterface.PassportState) {
        MeegoLogger.info("lark user(\(state.user?.userID ?? "")) \(state.action.rawValue) to \(state.loginState.rawValue)")
    }
}
