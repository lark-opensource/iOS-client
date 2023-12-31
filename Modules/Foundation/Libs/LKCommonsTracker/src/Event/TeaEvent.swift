//
//  TeaEvent.swift
//  LKCommonsTracker
//
//  Created by 李晨 on 2019/3/25.
//

import Foundation

public final class TeaEvent: Event {
    public var category: String?
    /// the user which produce this event, used for ensure user isolation
    public var userID: String?
    public var params: [AnyHashable: Any]
    /**
     md5AllowList:需要加密的keys数组 即params中:需要对value进行MD5加密的keys
     MD5加密方式：lark定制化的id加密方法，常用于userID的加密
     */
    public var md5AllowList: [AnyHashable]

    public init(
        _ name: String,
        userID: String? = nil,
        category: String? = nil,
        params: [AnyHashable: Any] = [:],
        md5AllowList: [AnyHashable] = [],
        timestamp: Timestamp = Tracker.currentTime()) {
        self.params = params
        self.userID = userID
        self.category = category
        self.md5AllowList = Self.checkNoneForMd5(params, md5AllowList: md5AllowList)
        super.init(name: name, timestamp: timestamp)
    }

    public init(
        _ name: String,
        userID: String? = nil,
        params: [AnyHashable: Any] = [:],
        md5AllowList: [AnyHashable] = [],
        bizSceneModels: [TeaBizSceneProtocol] = []) {
        self.params = params
        self.userID = userID
        var md5List = md5AllowList
        for sceneModel in bizSceneModels {
            self.params.merge(sceneModel.toDict(), uniquingKeysWith: { (first, _) in first })
            md5List.append(contentsOf: sceneModel.md5AllowList)
        }
        self.md5AllowList = Self.checkNoneForMd5(params, md5AllowList: md5List)
        super.init(name: name, timestamp: Tracker.currentTime())
    }

    /// 检查md5AllowList中需要加密的字段，如果params里对应的value为none，则不能加密
    static func checkNoneForMd5(_ params: [AnyHashable: Any], md5AllowList: [AnyHashable]) -> [AnyHashable] {
        md5AllowList.filter({
            guard let value = params[$0] else { return false }
            if let theValue = value as? String, theValue == "none" {
                return false
            }
            if let list = value as? Array<String> {
                return list.filter({ $0 == "none" }).count != list.count
            }
            // params["key"] = ["abc", "none"]，这种情况不容易兜住。这里只简单兜下，主要靠上层业务去保证，而且这种情况也不应该存在
            return true
        })
    }
}

/// 给字典新增+=操作符，方便使用
public func += <KeyType, ValueType>(left: inout [KeyType: ValueType], right: [KeyType: ValueType]) {
    for (key, value) in right {
        left.updateValue(value, forKey: key)
    }
}

/// 因为 Tea 不支持 Boolean，提供便利方法方便转换
public extension Bool {
    /// Bool 对应的 String 值，"true" or "false"
    var stringValue: String {
        self.description
    }
    /// Bool 对应的 Int 值，1 or 0
    var intValue: Int {
        self ? 1 : 0
    }
}
