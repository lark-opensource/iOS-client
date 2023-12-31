//
//  LynxTrackerModule.swift
//  ByteViewHybrid
//
//  Created by Tobb Huang on 2022/11/12.
//

import Foundation
import ByteViewTracker

class LynxTrackerModule: NSObject, LynxNativeModule {
    typealias Param = Any

    static var name: String = "Tracker"

    static var methodLookup: [String: String] = [
        "track": NSStringFromSelector(#selector(track))
    ]

    override required init() { super.init() }
    required init(param: Any) {}

    /// 埋点约定数据结构:
    /// - eventName: String 埋点名称
    /// - params: [String: [String: Any]] 埋点参数，[参数名, 参数信息]组成的参数列表，可选
    ///    - 其中，参数信息包含:
    ///       - is_encrypt: Bool 是否需要加密，可选，默认为false。若为true, value必须为String类型
    ///       - value: Any 参数值
    @objc func track(trackInfo: [String: Any]) {
        guard let eventName = trackInfo["eventName"] as? String,
              let trackEventName = TrackEventName(rawValue: eventName) else {
            return
        }
        var trackParams: [String: Any] = [:]
        if let params = trackInfo["params"] as? [String: Any] {
            params.keys.forEach { key in
                guard let valueDict = params[key] as? [String: Any],
                      let value = valueDict["value"] else {
                    return
                }
                if valueDict["encrypted"] as? Bool == true, let valueStr = value as? String {
                    trackParams[key] = EncryptoIdKit.encryptoId(valueStr)
                } else {
                    trackParams[key] = value
                }
            }
        }
        VCTracker.post(name: trackEventName, params: TrackParams(trackParams))
    }
}
