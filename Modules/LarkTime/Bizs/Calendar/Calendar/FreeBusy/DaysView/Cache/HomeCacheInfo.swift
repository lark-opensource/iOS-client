//
//  HomeCacheInfo.swift
//  Calendar
//
//  Created by zhuheng on 2020/7/7.
//

import Foundation

final class HomeCacheInfoObject: NSObject, NSCoding {
    func encode(with coder: NSCoder) {
        coder.encode(self.userId, forKey: "userId")
        coder.encode(self.tenantId, forKey: "tenantId")
        coder.encode(self.timeZoneId, forKey: "timeZoneId")
        coder.encode(self.julianDays, forKey: "julianDays")
    }

    required init?(coder: NSCoder) {
        self.userId = coder.decodeObject(forKey: "userId") as? String
        self.tenantId = coder.decodeObject(forKey: "tenantId") as? String
        self.timeZoneId = coder.decodeObject(forKey: "timeZoneId") as? String
        self.julianDays = coder.decodeObject(forKey: "julianDays") as? Set<Int32>
    }

    private(set) var userId: String?
    private(set) var tenantId: String?
    private(set) var timeZoneId: String?
    private(set) var julianDays: Set<Int32>?

    init(userId: String, tenantId: String, timeZoneId: String? = nil, julianDays: Set<Int32>? = nil) {
        self.userId = userId
        self.tenantId = tenantId
        self.timeZoneId = timeZoneId
        self.julianDays = julianDays
    }
}

final class InstanceCacheObject: NSObject, NSCoding {
    func encode(with coder: NSCoder) {
        coder.encode(self.instance, forKey: "instance")
        coder.encode(self.info, forKey: "info")
    }

    required init?(coder: NSCoder) {
        self.instance = coder.decodeObject(forKey: "instance") as? String
        self.info = coder.decodeObject(forKey: "info") as? Data
    }

    private(set) var instance: String?
    private(set) var info: Data?

    init(instance: String, info: Data) {
        self.instance = instance
        self.info = info
    }
}

final class SettingCacheObject: NSObject, NSCoding {
    func encode(with coder: NSCoder) {
        coder.encode(self.setting, forKey: "setting")
        coder.encode(self.info, forKey: "info")
    }

    required init?(coder: NSCoder) {
        self.setting = coder.decodeObject(forKey: "setting") as? Data
        self.info = coder.decodeObject(forKey: "info") as? Data
    }

    private(set) var setting: Data?
    private(set) var info: Data?

    init(setting: Data, info: Data) {
        self.setting = setting
        self.info = info
    }
}
