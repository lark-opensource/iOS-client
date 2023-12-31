//
//  Extension+Dictionary.swift
//  EENavigator
//
//  Created by liuwanlin on 2019/1/11.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    public init<T: Body>(body: T) {
        let dict: Dictionary = [:]
        self = dict.merging(body: body)
    }

    public init(naviParams: NaviParams) {
        let dict: Dictionary = [:]
        self = dict.merging(naviParams: naviParams)
    }

    public func merging(naviParams: NaviParams) -> Dictionary {
        var dict = self
        dict[ContextKeys.naviParams] = naviParams
        return dict
    }

    public func merging<T: Body>(body: T) -> Dictionary {
        var dict = self
        dict[ContextKeys.body] = body
        return dict
    }

    public var naviParams: NaviParams? {
        return self[ContextKeys.naviParams] as? NaviParams
    }

    public func body<T: Body>() -> T? {
        return self[ContextKeys.body] as? T
    }

    public func from() -> NavigatorFrom? {
        return self[ContextKeys.from] as? NavigatorFrom
    }

    public func openType() -> OpenType? {
        return self[ContextKeys.openType] as? OpenType
    }
}
