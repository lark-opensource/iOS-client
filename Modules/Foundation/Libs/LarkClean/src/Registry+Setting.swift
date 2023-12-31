//
//  Registry+Setting.swift
//  LarkClean
//
//  Created by 7Up on 2023/7/18.
//

import Foundation
import LarkStorage

enum SettingParams: String {
    case userId = "{uid}"
    case tenantId = "{tenantId}"
}

extension CleanRegistry {

    /// See more: https://bytedance.feishu.cn/wiki/TWI7we6k8igfclkx0azcZ0kjnzf
    public static func parseIndexes(with setting: [String: Any], context: CleanContext) -> [CleanIndex] {
        var indexes = [CleanIndex]()
        if setting["path"] != nil {
            if let pathList = setting["path"] as? [String] {
                let pathIndexes = _parsePartialPath(with: pathList, context: context).map {
                    return CleanIndex.path(.abs((AbsPath.home + $0).absoluteString))
                }
                indexes.append(contentsOf: pathIndexes)
            } else {
                logger.error("unexpected setting: \(setting)")
            }
        }
        if setting["kv_store"] != nil {
            if let vkeyList = setting["kv_store"] as? [[String: Any]] {
                let vkeyIndexes = _parseUnifiedVkey(with: vkeyList, context: context).map {
                    CleanIndex.vkey(CleanIndex.Vkey.unified($0))
                }
                indexes.append(contentsOf: vkeyIndexes)
            } else {
                logger.error("unexpected setting: \(setting)")
            }
        }
        return indexes
    }

    private static func _parsePartialPath(with pathList: [String], context: CleanContext) -> [String] {
        return
            context.userList.flatMap { user -> [String] in
                return pathList.map { path in
                    var fixed = path.replacingOccurrences(of: SettingParams.userId.rawValue, with: user.userId)
                    fixed = fixed.replacingOccurrences(of: SettingParams.tenantId.rawValue, with: user.tenantId)
                    return fixed
                }
            }
            .lark_clean_uniqued()
    }

    private static func _parseUnifiedVkey(with vkeyList: [[String: Any]], context: CleanContext) -> [CleanIndex.Vkey.Unified] {
        var ret = [CleanIndex.Vkey.Unified]()
        for dict in vkeyList {
            guard let typeStr = dict["type"] as? String, let type = KVStoreType(rawValue: typeStr) else {
                logger.error("unexpected type field: \(dict["type"] ?? "")")
                continue
            }
            guard let spaceStr = dict["space"] as? String else {
                logger.error("unexpected space field: \(dict["space"] ?? "")")
                continue
            }
            guard let domainStr = dict["domain"] as? String else {
                logger.error("unexpected domain field: \(dict["domain"] ?? "")")
                continue
            }
            let tmpDomain = Domain.makeDomain(from: domainStr.components(separatedBy: "."))
            guard let domain = tmpDomain else {
                logger.error("unexpected domain value: \(domainStr)")
                continue
            }
            let spaces: [Space]
            if spaceStr == SettingParams.userId.rawValue {
                spaces = context.userList.map { .user(id: $0.userId) }
            } else if spaceStr == "global" {
                spaces = [.global]
            } else {
                logger.error("unexpected space value: \(spaceStr)")
                spaces = []
            }
            ret.append(contentsOf: spaces.map { space in
                CleanIndex.Vkey.Unified(space: space, domain: domain, type: type)
            })
        }
        return ret.lark_clean_uniqued()
    }

}

extension Array where Element: Hashable {
    fileprivate func lark_clean_uniqued() -> [Element] {
        var set = Set<Element>()
        var values = [Element]()
        forEach {
            if set.insert($0).inserted {
                values.append($0)
            }
        }
        return values
    }
}

/// For Unit Test in DEBUG env
#if DEBUG
extension CleanRegistry {

    static func debugParsePartialPath(with pathList: [String], context: CleanContext) -> [String] {
        _parsePartialPath(with: pathList, context: context)
    }

    static func debugParseUnifiedVkey(with vkeyList: [[String: Any]], context: CleanContext) -> [CleanIndex.Vkey.Unified] {
        _parseUnifiedVkey(with: vkeyList, context: context)
    }

}
#endif
