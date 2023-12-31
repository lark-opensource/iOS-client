//
//  LarkMagicService.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/11/8.
//

import Foundation
import UIKit

public typealias ContainerProvider = () -> UIViewController?
public protocol LarkMagicService {
    var currentScenarioID: String? { get }

    func register(scenarioID: String,
                  interceptor: ScenarioInterceptor,
                  containerProvider: @escaping ContainerProvider)

    func register(scenarioID: String,
                  params: [String: String]?,
                  interceptor: ScenarioInterceptor,
                  containerProvider: @escaping ContainerProvider)

    func register(scenarioID: String,
                  params: [String: String]?,
                  delegate: LarkMagicDelegate?,
                  interceptor: ScenarioInterceptor,
                  containerProvider: @escaping ContainerProvider)

    func unregister(scenarioID: String)

    func triggerEvent(eventName: String, extraParams: [AnyHashable: Any]?)
}

public protocol LarkMagicDelegate: AnyObject {
    func taskWillOpen(_ taskID: String)
    func taskDidOpen(_ taskID: String)
    func taskDidClosed(_ taskID: String)
}
