//
//  MonitorConfig.swift
//  CryptoSwift
//
//  Created by PGB on 2020/3/17.
//

import Foundation

public class MonitorConfig {
    let configName: String
    let maxLevel: Int?
    var conditions: [Condition]
    let operations: [String: String]
    var extra: [String: Any]?

    // 防止多个分类的正则匹配到同一个FileItem导致item_name字段失效 [classification: [path: itemName]]
    var itemNames: [String: [String: String]] = [:]

    public convenience init?(rawConfig: RawMonitorConfig) {
        guard rawConfig.config_name != nil,
            rawConfig.operations != nil,
            rawConfig.classifications != nil else { return nil }
        var conditions: [Condition] = []
        for (classification, rawConditions) in rawConfig.classifications {
            for rawCondition in rawConditions {
                if let condition = Condition(classification: classification, rawCondition: rawCondition) {
                    conditions.append(condition)
                } else {
                    return nil
                }
            }
        }
        self.init(configName: rawConfig.config_name,
                  maxLevel: rawConfig.max_level,
                  conditions: conditions,
                  operations: rawConfig.operations,
                  extra: rawConfig.extra)
    }

    public init(configName: String,
                maxLevel: Int?,
                conditions: [Condition] = [],
                operations: [String: String] = [:],
                extra: [String: Any]? = nil) {
        self.configName = configName
        self.maxLevel = maxLevel
        self.conditions = conditions
        self.operations = operations
        self.extra = extra
    }

    func classify(files: [FileItem]) -> [String: [FileItem]] {
        var result: [String: [FileItem]] = [:]
        var files: [FileItem] = files
        if let maxLevel = maxLevel {
            files = files.filter { $0.level < maxLevel }
        }
        for condition in conditions {
            for file in files {
                let ignoreFileType = condition.type == .all
                let fileTypeMatch = (condition.type == .folder) == file.isDir
                if condition.matches(file.path) && (ignoreFileType || fileTypeMatch) {
                    result[condition.classification] = result[condition.classification, default: []] + [file]
                    if let itemName = condition.itemName {
                        var mapping = itemNames[condition.classification] ?? [:]
                        mapping[file.path] = itemName
                        itemNames[condition.classification] = mapping
                    }
                }
            }
        }
        return result
    }

    func reassemble(classifiedFiles: [String: [FileItem]]) -> [String: [FileItem]] {
        var result: [String: [FileItem]] = [:]
        for classification in operations.keys {
            let parts = classification.split(separator: ",")
            if parts.count == 3 {
                let leftSet = Set<FileItem>(classifiedFiles["\(parts[0])"] ?? [])
                let rightSet = Set<FileItem>(classifiedFiles["\(parts[2])"] ?? [])
                switch parts[1] {
                case "subtracting": result[classification] = Array(leftSet.subtracting(rightSet))
                case "intersection": result[classification] = Array(leftSet.intersection(rightSet))
                case "union": result[classification] = Array(leftSet.union(rightSet))
                case "symmetric_difference": result[classification] = Array(leftSet.symmetricDifference(rightSet
                ))
                default: ()
                }
            } else {
                result[classification] = classifiedFiles[classification]
            }
        }
        return result
    }

    func operate(on reassembledFiles: [String: [FileItem]]) {
        for (classification, operation) in operations {
            var monitorOperation: MonitorOperation? = nil
            switch operation {
            case "log_file": monitorOperation = LogFiles()
            case "slardar_event": monitorOperation = TrackEvent()
            case "custom_exception": monitorOperation = RaiseCustomException()
            default: ()
            }
            if let files = reassembledFiles[classification] {
                let mapping = itemNames[classification] ?? [:]
                for file in files {
                    file._trackName = mapping[file.path]
                }
                monitorOperation?.operate(files: files)
            }
        }
    }
}

public class Condition {
    let classification: String
    let regex: String
    let type: ConditionType
    let itemName: String?

    public convenience init?(classification: String, rawCondition: RawCondition) {
        guard rawCondition.regex != nil else { return nil }
        self.init(classification: classification,
                  regex: rawCondition.regex,
                  type: rawCondition.type ?? .all,
                  itemName: rawCondition.item_name)
    }

    public init(classification: String, regex: String, type: ConditionType = .all, itemName: String? = nil) {
        self.classification = classification
        self.regex = regex
        self.type = type
        self.itemName = itemName
    }

    func matches(_ string: String) -> Bool {
        return string.exactlyMatches(regex)
    }
}

public enum ConditionType: String, ExpressibleByStringLiteral, Decodable {
    public typealias StringLiteralType = String

    case file = "file"
    case folder = "folder"
    case all = "all"
    public init(stringLiteral value: Self.StringLiteralType) {
        switch value {
        case "all": self = .all
        case "folder": self = .folder
        case "file": self = .file
        default: self = .all
        }
    }
}
