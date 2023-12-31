//
//  Topic.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/13.
//

import Foundation
import LarkMeegoLogger

public struct Topic {
    // 数据类型
    public let topicType: Int
    // 数据标识
    public let topicName: String
    let params: [String: String]
    // 订阅成功后对应id
    public var ssbId: Int

    public init(topicType: Int, topicName: String, params: [String: String] = [:], ssId: Int = 0) {
        self.topicType = topicType
        self.topicName = Self.composeTopicName(topicName, params: params)
        self.params = params
        self.ssbId = ssId
    }
}

private extension Topic {
    /// 由外部传入的端侧原始topicName和params，生成与后端交互所需的topicName。
    /// - Parameters:
    ///   - topicName: 传入Topic的 topicName.   eg.  "config/:project_key/info"
    ///   - params: Topic的parmas.   eg.  {  "project_key": projectKey };
    /// - Returns: 与后端交互所需的topicName
    static func composeTopicName(_ topicName: String, params: [String: String]) -> String {
        if params.isEmpty || !topicName.contains("/") {
            return topicName
        }

        var subStrList = topicName.split(separator: "/")
        var resultList: [String] = []

        subStrList.forEach { subStr in
            var value = subStr.substring(from: subStr.startIndex)
            if !subStr.isEmpty && subStr.starts(with: ":") {
                let range = subStr.index(after: subStr.startIndex)..<subStr.endIndex
                let paramsKey = subStr.substring(with: range)
                if paramsKey.isEmpty {
                    MeegoLogger.error("Parameter key invalid, topicName=\(topicName).")
                } else if params.keys.contains(paramsKey) {
                    value = params[paramsKey] ?? ""
                    if value.isEmpty {
                        MeegoLogger.error("Parameter value isEmpty, topicName=\(topicName), paramsKey=\(paramsKey)")
                    }
                }
            }
            resultList.append(value)
        }

        return resultList.joined(separator: "/")
    }
}
