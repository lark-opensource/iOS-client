//
//  ClientVarCacheMetaInfo.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/12/27.
//

import SKFoundation
import SKInfra

/// 用于统计clientVar缓存命中率
public final class ClientVarCacheMetaInfo: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool = true

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.key, forKey: "key")
        aCoder.encode(lastUpdateTime, forKey: "lastUpdateTime")
        aCoder.encode(source.rawValue, forKey: "source")
    }

    required convenience public init?(coder aDecoder: NSCoder) {
        guard let k = aDecoder.decodeObject(forKey: "key") as? String,
            let sr = aDecoder.decodeObject(forKey: "source") as? String,
            let s = Source(rawValue: sr) else {
                return nil
        }
        let t = aDecoder.decodeDouble(forKey: "lastUpdateTime")
        self.init(key: k, source: s, lastUpdateTime: t)
    }

    public let key: String
    public let lastUpdateTime: TimeInterval
    public var source: Source

    public enum Source: String {
        case web
        case preload
    }

    public init(key: String, source: Source, lastUpdateTime: TimeInterval) {
        self.key = key
        self.source = source
        self.lastUpdateTime = lastUpdateTime
    }

    override public var description: String {
        return "key is \(key), from \(source.rawValue) at \(Date(timeIntervalSinceReferenceDate: lastUpdateTime)) to now \(secondsToNow) seconds"
    }

    public var secondsToNow: TimeInterval {
        return Date.timeIntervalSinceReferenceDate - lastUpdateTime
    }
}

public final class ClientVarCacheInfoManager {
    public static let shared = ClientVarCacheInfoManager()
    private var infos: [String: Data]
    private let userDefaultKey: String
    private let userdefault: UserDefaults

    init(userdefaultKey: String = UserDefaultKeys.clientVarCacheMetaInfoKey, userdefault: UserDefaults = UserDefaults.standard) {
        self.infos = (CCMKeyValue.globalUserDefault.dictionary(forKey: userdefaultKey) as? [String: Data]) ?? [:]
        self.userDefaultKey = userdefaultKey
        self.userdefault = userdefault
    }

//    public func setCacheWith(source: ClientVarCacheMetaInfo.Source, for key: String) {
//        let info = ClientVarCacheMetaInfo(key: key, source: source, lastUpdateTime: Date.timeIntervalSinceReferenceDate)
//        var data: Data?
//        data = try? NSKeyedArchiver.archivedData(withRootObject: info, requiringSecureCoding: true)
//        synchronized(self) {
//            infos[key] = data
//        }
//        userdefault.set(infos, forKey: userDefaultKey)
//    }

//    public func clearCacheFor(_ key: String) {
//        synchronized(self) {
//            infos[key] = nil
//        }
//        userdefault.set(infos, forKey: userDefaultKey)
//    }

    public func getInfoFor(_ key: String) -> ClientVarCacheMetaInfo? {
        var data: Data?
        synchronized(self) {
            data = infos[key]
        }
        guard data != nil else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: ClientVarCacheMetaInfo.self, from: data!)
        } catch {
            return nil
        }
    }
}
