//
//  NetworkTipsConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

public struct NetworkTipsConfig: Decodable {
    public let localNetworkDisconnectTipsDelayTime: Double
    public let meetingWeakNetworkAbtest: MeetingWeakNetworkAbtest

    static let `default` = NetworkTipsConfig(localNetworkDisconnectTipsDelayTime: 200.0, meetingWeakNetworkAbtest: .default)

    func isABTestEnabled(deviceId: String) -> Bool {
        if !meetingWeakNetworkAbtest.enable {
            return true
        } else {
            if meetingWeakNetworkAbtest.userInBlackList {
                return false
            }
            if meetingWeakNetworkAbtest.userInWhiteList {
                return true
            }
            if deviceId.count > 1 {
                let start = deviceId.index(deviceId.endIndex, offsetBy: -2)
                let end = deviceId.index(deviceId.endIndex, offsetBy: -1)
                let s = String(deviceId[start..<end])
                return meetingWeakNetworkAbtest.did.contains(s)
            }
        }
        return false
    }
}

public struct MeetingWeakNetworkAbtest: Decodable {
    public let enable: Bool
    public let did: Set<String>
    public let userInWhiteList: Bool
    public let userInBlackList: Bool

    static let `default` = MeetingWeakNetworkAbtest(enable: false, did: [], userInWhiteList: false, userInBlackList: false)
}
