//
//  URL.swift
//  SuiteCodable
//
//  Created by liuwanlin on 2019/5/4.
//

import Foundation

extension URL: Transformable {
    static func transform(from object: Any) -> URL? {
        guard let str = String.transform(from: object) else {
            return nil
        }
        if let url = URL(string: str) {
            return url
        }
        // 防止url含有中文无法转换
        let urlStr = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? str
        if let url = URL(string: urlStr) {
            return url
        }
        return nil
    }
}
