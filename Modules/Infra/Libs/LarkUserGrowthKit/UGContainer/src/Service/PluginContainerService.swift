//
//  PluginContainerService.swift
//  UGContainer
//
//  Created by mochangxing on 2021/1/22.
//

import Foundation

public protocol PluginContainerService: AnyObject {

    func reportEvent(event: ReachPointEvent)

    func obtainReachPoint<T: ReachPoint>(reachPointId: String) -> T?

    func recycleReachPoint(reachPointId: String, reachPointType: String)

    func showReachPoint(reachPointId: String, reachPointType: String, data: Data)

    func hideReachPoint(reachPointId: String, reachPointType: String)

    var reachPointsInfo: [String: [String]] { get }
}
