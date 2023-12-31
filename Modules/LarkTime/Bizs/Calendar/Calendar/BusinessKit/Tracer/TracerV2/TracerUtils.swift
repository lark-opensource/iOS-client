//
//  TracerUtils.swift
//  Calendar
//
//  Created by Rico on 2021/6/25.
//

import Foundation

extension String {
    func appendViewIfNeeded() -> String {
        hasSuffix("_view") ? self : appending("_view")
    }

    func appendClickIfNeeded() -> String {
        hasSuffix("_click") ? self : appending("_click")
    }
}

extension Encodable {

    /// 抹除层级
    var toTracerFlatDic: [String: Any] {
        if let data = try? JSONEncoder().encode(self),
           let dic = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            let flatMapSeq = dic.flatMap { (key: String, value: Any) -> [(String, Any)] in
                if let a = value as? [String: Any] {
                    return a.map { $0 }
                }
                return [(key, value)]
            }
            return .init(flatMapSeq) { $1 }
        }
        assertionFailure("\(self) could not convert to Dic")
        return [:]
    }
}
