//
//  Dependencies.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

public protocol ZipArchiver {
    static func createZipFile(atPath: String, withFilesAtPaths paths: [String], password: String?) throws
    static func createZipFile(atPath: String, withContentsOfDirectory directoryPath: String, password: String?) throws
    static func unzipFile(atPath: String, toPath: String, overwrite: Bool, password: String?) throws
}

// 声明对账号相关的依赖
public protocol PassportDependency: AnyObject {
    var foregroundUserId: String? { get }
    var userIdList: [String] { get }
    var deviceId: String { get }
    func tenantId(forUser userId: String) -> String?
}

@objc
final public class ObjcDependency: NSObject {
    public typealias LoadOnce = (_ key: String) -> Void

    public static var loadOnce: LoadOnce = { _ in
        #if DEBUG || ALPHA
        assertionFailure("This default implementation should be replaced as early as possible")
        #endif
    }

    @objc(setLoadOnce:)
    public class func setLoadOnce(_ loadOnce: @escaping LoadOnce) {
        self.loadOnce = loadOnce
    }
}

public struct Dependencies {

    /// 埋点
    public typealias EventTracker = (_ event: TrackerEvent) -> Void

    public static var customTracker: EventTracker?

    public typealias DomainChecker = (DomainType) -> Bool

    public static var domainChecker: DomainChecker?
    public static var zipArchiver: ZipArchiver.Type?

    public static var injectedAppGroupId: String?
    public static var appGroupId: String {
        injectedAppGroupId ?? (Bundle.main.infoDictionary?["EXTENSION_GROUP"] as? String ?? "")
    }
    public static var passport: PassportDependency?

    static var loadOnce: ObjcDependency.LoadOnce { ObjcDependency.loadOnce }

    // 后台迁移任务白名单
    public static var backgroundTaskWhiteList: [DomainType]?
}

extension Dependencies {
    private static let defaultTracker: EventTracker = {
        NSLog("LarkStorage.event: \($0)")
    }

    static func post(_ event: TrackerEvent) {
        let tracker = customTracker ?? defaultTracker
        tracker(event)
    }
}
