//
//  VersionComparator.swift
//  LarkAI
//
//  Created by bytedance on 2021/12/9.
//

import Foundation
import LKCommonsLogging

// 版本号解析流程 ：https://bytedance.feishu.cn/docs/doccnISynBEBaQ0jJFqFRwRlSIb
// disable_option:
// 1. = "*" 该平台不高亮
// 2. = "<4.9.0" 该平台小于4.9.0时不高亮
// 3. = "<4.9.0|=4.11.2|=5.0.2" 这三个版本条件不高亮
// 4. 识别失败，按1处理
public final class Semver {
    private static let logger = Logger.log(Semver.self, category: "EnterpriseEntityWord.Semver")

    public var major: Int
    public var minor: Int
    public var patch: Int

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    static func == (lhs: Semver, rhs: Semver) -> Bool {
        if lhs.major == rhs.major,
           lhs.minor == rhs.minor,
           lhs.patch == rhs.patch {
            return true
        }
        return false
    }

    static func != (lhs: Semver, rhs: Semver) -> Bool {
        if lhs.major == rhs.major,
           lhs.minor == rhs.minor,
           lhs.patch == rhs.patch {
            return false
        }
        return true
    }

    static func >= (lhs: Semver, rhs: Semver) -> Bool {
        if lhs.major < rhs.major {
            return false
        }
        if lhs.major == rhs.major, lhs.minor < rhs.minor {
            return false
        }
        if lhs.major == rhs.major, lhs.minor == rhs.minor, lhs.patch < rhs.patch {
            return false
        }
        return true
    }

    static func <= (lhs: Semver, rhs: Semver) -> Bool {
        if lhs.major > rhs.major {
            return false
        }
        if lhs.major == rhs.major, lhs.minor > rhs.minor {
            return false
        }
        if lhs.major == rhs.major, lhs.minor == rhs.minor, lhs.patch > rhs.patch {
            return false
        }
        return true
    }

    static func > (lhs: Semver, rhs: Semver) -> Bool {
        if lhs.major < rhs.major {
            return false
        }
        if lhs.major == rhs.major, lhs.minor < rhs.minor {
            return false
        }
        if lhs.major == rhs.major, lhs.minor == rhs.minor, lhs.patch < rhs.patch {
            return false
        }
        if lhs.major == rhs.major,
           lhs.minor == rhs.minor,
           lhs.patch == rhs.patch {
            return false
        }
        return true
    }

    static func < (lhs: Semver, rhs: Semver) -> Bool {
        if lhs.major > rhs.major {
            return false
        }
        if lhs.major == rhs.major, lhs.minor > rhs.minor {
            return false
        }
        if lhs.major == rhs.major, lhs.minor == rhs.minor, lhs.patch > rhs.patch {
            return false
        }
        if lhs.major == rhs.major,
           lhs.minor == rhs.minor,
           lhs.patch == rhs.patch {
            return false
        }
        return true
    }

    public static func parseVersionString(_ version: String) -> Semver? {
        Self.logger.info("parseVersionString, version:\(version)")
        // 舍弃后面的小版本号，只判断前面三位大版本号
        let components = version.components(separatedBy: "-")
        guard let baseVersion = components.first else {
            return nil
        }
        let versionComponents = baseVersion.components(separatedBy: ".")
        guard versionComponents.count >= 3 else {
            return nil
        }
        if let major = Int(versionComponents[0]), let minor = Int(versionComponents[1]), let patch = Int(versionComponents[2]) {
            return Semver(major: major, minor: minor, patch: patch)
        }
        return nil
    }

    public static func isVersionDisabled(appVersion: String, disabledVersion: String) -> Bool {
        Self.logger.info("isVersionDisabled, appVersion:\(appVersion), disabledVersion:\(disabledVersion)")
        if disabledVersion == "*" {
            return true
        }
        guard let appVersionSemver = parseVersionString(appVersion) else {
            return false
        }
        var versionRangeList: [String]
        // 先用或符切割开，切分成一段一段的版本范围
        if disabledVersion.contains("|") {
            versionRangeList = disabledVersion.components(separatedBy: "|")
        } else {
            versionRangeList = [disabledVersion]
        }
        for versionRange in versionRangeList {
            var versionExpressionList: [String]
            // 按逗号切割为一个个表达式，例如>4.0.0，versionExpressionList里面的表达式是且的关系
            if versionRange.contains(",") {
                versionExpressionList = versionRange.components(separatedBy: ",")
            } else {
                versionExpressionList = [versionRange]
            }
            var isInRange = true
            for versionExpression in versionExpressionList {
                if versionExpression.starts(with: ">=") {
                    guard let targetVersionSemver = parseVersionString(String(versionExpression.dropFirst(2))) else {
                        return false
                    }
                    isInRange = isInRange && (appVersionSemver >= targetVersionSemver)
                } else if versionExpression.starts(with: "<=") {
                    guard let targetVersionSemver = parseVersionString(String(versionExpression.dropFirst(2))) else {
                        return false
                    }
                    isInRange = isInRange && (appVersionSemver <= targetVersionSemver)
                } else if versionExpression.starts(with: "!=") {
                    guard let targetVersionSemver = parseVersionString(String(versionExpression.dropFirst(2))) else {
                        return false
                    }
                    isInRange = isInRange && (appVersionSemver != targetVersionSemver)
                } else if versionExpression.starts(with: "=") {
                    guard let targetVersionSemver = parseVersionString(String(versionExpression.dropFirst(1))) else {
                        return false
                    }
                    isInRange = isInRange && (appVersionSemver == targetVersionSemver)
                } else if versionExpression.starts(with: ">") {
                    guard let targetVersionSemver = parseVersionString(String(versionExpression.dropFirst(1))) else {
                        return false
                    }
                    isInRange = isInRange && (appVersionSemver > targetVersionSemver)
                } else if versionExpression.starts(with: "<") {
                    guard let targetVersionSemver = parseVersionString(String(versionExpression.dropFirst(1))) else {
                        return false
                    }
                    isInRange = isInRange && (appVersionSemver < targetVersionSemver)
                } else {
                    return false
                }
                //versionExpressionList里面的元素是且的关系，有一个false跳出内层的循环
                if !isInRange {
                    break
                }
            }
            //versionRangeList里面的元素是或的关系，有一个满足了直接返回true
            if isInRange {
                return true
            }
        }
        return false
    }
}
