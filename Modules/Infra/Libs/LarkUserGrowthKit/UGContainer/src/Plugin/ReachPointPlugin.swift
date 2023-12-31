//
//  ReachPointPlugin.swift
//  UGContainer
//
//  Created by mochangxing on 2021/1/22.
//

import Foundation

public protocol ReachPointPlugin: AnyObject {

    func onShow(reachPointId: String, data: Data)

    func onHide(reachPointId: String)

    func onEnterForground()

    func onEnterBackground()

    func obtainReachPoint<R: ReachPoint>(reachPointId: String) -> R?

    func recycleReachPoint(reachPointId: String)

    var curReachPointIds: [String] { get }
}

protocol ContainerServiceProvider {
    var containerSevice: PluginContainerService? { get set }
}
