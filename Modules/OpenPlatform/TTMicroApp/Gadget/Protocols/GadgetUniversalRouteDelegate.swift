//
//  GadgetUniversalRouteDelegate.swift
//  TTMicroApp
//
//  Created by 刘洋 on 2021/4/27.
//
//
import Foundation
import UIKit
import LarkOPInterface

@objc
public protocol GadgetUniversalRouteDelegate: BDPBasePluginDelegate {
    @objc
    func push(viewController: BDPBaseContainerController, from window: UIWindow, animated: Bool, complete: @escaping (OPError?) -> ())

    @objc
    func pop(viewController: BDPBaseContainerController, animated: Bool, complete: @escaping (OPError?) -> ())
}
