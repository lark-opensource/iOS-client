//
//  OPHeartBeatMonitorBizSource.swift
//  ECOProbe
//
//  Created by lixiaorui on 2021/7/9.
//

import Foundation

// 后续可扩充其他状态： 如前台/后台等
@objc
public enum OPHeartBeatMonitorSourceStatus: Int {

    // 活跃态
    case active

    // 未知态
    case unknown

}

// 心跳埋点的数据源
@objcMembers
public final class OPHeartBeatMonitorBizSource: NSObject {
    // 需要加入心跳埋点的数据源
    public let monitorData: OPMonitorEvent

    // 该心跳埋点的唯一ID
    public let heartBeatID: String

    public init(heartBeatID: String, monitorData: OPMonitorEvent) {
        self.heartBeatID = heartBeatID
        self.monitorData = monitorData
        super.init()
    }
}

// 接入方需要遵循此协议, 以提供轮询时source的状态
@objc
public protocol OPHeartBeatMonitorBizProvider {
  // 获取当前活跃状态,给heartBeatID方便接入方按需做校验和判断
  func getCurrentStatus(of heartBeatID: String) -> OPHeartBeatMonitorSourceStatus
}
