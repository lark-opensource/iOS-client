//
//  GadgetUniversalRouteCustomImpl.swift
//  EEMicroAppSDK
//
//  Created by 刘洋 on 2021/4/28.
//

import Foundation
import TTMicroApp
import OPGadget

/// 小程序统一路由代理的实现
@objc
public final class GadgetUniversalRouteCustomImpl: NSObject, GadgetUniversalRouteDelegate {
    public func push(viewController: BDPBaseContainerController, from window: UIWindow, animated: Bool, complete: @escaping (OPError?) -> ()) {
        GadgetNavigator.shared.push(viewController: viewController, from: window, animated: animated, complete: complete)
    }

    public func pop(viewController: BDPBaseContainerController, animated: Bool, complete: @escaping (OPError?) -> ()) {
        GadgetNavigator.shared.pop(viewController: viewController, animated: animated, complete: complete)
    }

    public static func sharedPlugin() -> BDPBasePluginDelegate! {
        return Self.shared
    }

    private override init() {
        super.init()
    }

    private static let shared = GadgetUniversalRouteCustomImpl()
}

