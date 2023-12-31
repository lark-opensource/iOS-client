//
//  UserInfo.swift
//  NotificationUserInfo
//
//  Created by 姚启灏 on 2018/12/18.
//

import Foundation

public struct UserInfo: JSONCodable {
    public var group: String
    public var identifier: String
    //单位 ms
    public let pushTime: Int64
    public let sid: String?
    public var alert: Alert?
    public var extra: Extra?
    public var nseExtra: LarkNSEExtra?

    public init(group: String = "",
                identifier: String = "",
                pushTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
                sid: String? = nil,
                alert: Alert? = nil,
                extra: Extra? = nil) {
        self.group = group
        self.identifier = identifier
        self.pushTime = pushTime
        self.sid = sid
        self.alert = alert
        self.extra = extra
    }

    public init?(dict: [String: Any]) {
        guard let pushTime = dict["pushTime"] as? Int64 else {
                return nil
        }
        self.group = dict["group"] as? String ?? ""
        self.identifier = dict["identifier"] as? String ?? ""
        self.sid = dict["sid"] as? String
        self.pushTime = pushTime

        if let info = dict["alert"] as? [String: Any] {
            self.alert = Alert(dict: info)
        }
        if let info = dict["extra"] as? [String: Any] {
            self.extra = Extra(dict: info)
        }
        self.nseExtra = LarkNSEExtra.getExtraDict(from: dict)
    }

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]

        dict["group"] = self.group
        dict["identifier"] = self.identifier
        dict["pushTime"] = self.pushTime
        dict["sid"] = self.sid
        dict["alert"] = self.alert?.toDict()
        dict["extra"] = self.extra?.toDict()
        dict["extra_str"] = LarkNSEExtra.extraToString(from: self.nseExtra)

        return dict
    }
}
