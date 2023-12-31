//
//  SBUtils.swift
//  LarkStorage
//
//  Created by 7Up on 2023/2/26.
//

import Foundation
import LKCommonsLogging

public enum SBUtils { }

// @available(*, deprecated, message: "Please use SBUtils")
public typealias SBUtil = SBUtils

extension SBUtils {

    public enum AssertEvent: String {
        case unexpectedLogic
        case migration
        case wrongDomain
        case wrongSpace
        case unsupportedCipher
        case unexpectedParseFailure
        case decryptNotExistsPath
        case decryptPath
        /// 不清晰的 abs path. eg: "~/a/b/c"
        case unclearAbsPath
        /// 非法的 abs path. eg: "a/b/c", ""
        case invalidAbsPath
    }

    public static func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> String = String(),
        event: AssertEvent,
        extra: [AnyHashable: Any]? = nil,
        file: String = #fileID,
        line: Int = #line
    ) {
        guard !condition() else { return }
        let msg = message()
        sandboxLogger.error("msg: \(msg), extra: \(extra ?? [:])", file: file, line: line)
        let config = AssertReporter.AssertConfig(scene: "sandbox", event: event.rawValue)
        AssertReporter.report(msg, config: config, extra: extra, file: file, line: line)
        // if !isSwiftAssertDisabled {
        //     assertionFailure("message: \(msg), config: \(config)")
        // }
    }

    public static func assertionFailure(
        _ message: @autoclosure () -> String = String(),
        extra: [AnyHashable: Any]? = nil,
        file: String = #fileID,
        line: Int = #line
    ) {
        self.assert(false, message(), event: .unexpectedLogic, extra: extra, file: file, line: line)
    }

}

// MARK: - Free disk space
// 精确查询可用磁盘空间: https://bytedance.feishu.cn/wiki/VFRCwCtrViJXOfkSaCXccZDpndh
public extension SBUtils {

    /// 系统设置中展示的剩余空间
    static var importantDiskSpace: Int64 {
        do {
            return try URL(fileURLWithPath: NSHomeDirectory())
                .resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                .volumeAvailableCapacityForImportantUsage ?? 0
        } catch {
            sandboxLogger.error("get importantDiskSpace failed: \(error)")
            return 0
        }
    }

    static var opportunisticDiskSpace: Int64 {
        do {
            return try URL(fileURLWithPath: NSHomeDirectory())
                .resourceValues(forKeys: [.volumeAvailableCapacityForOpportunisticUsageKey])
                .volumeAvailableCapacityForOpportunisticUsage ?? 0
        } catch {
            sandboxLogger.error("get opportunisticDiskSpace failed: \(error)")
            return 0
        }
    }

    /// 传统接口获得的剩余空间
    static var directDiskSpace: Int64 {
        do {
            return Int64(try URL(fileURLWithPath: NSHomeDirectory())
                .resourceValues(forKeys: [.volumeAvailableCapacityKey])
                .volumeAvailableCapacity ?? 0)
        } catch {
            sandboxLogger.error("get directDiskSpace failed: \(error)")
            return 0
        }
    }
}

extension SBUtils {
    public static var log: Log { sandboxLogger }
}
