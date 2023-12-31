//
//  Dictionary+Extension.swift
//  ECOInfra
//
//  Created by 刘焱龙 on 2023/5/25.
//

import Foundation

extension Dictionary {
    func toJSONString() -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return nil
        }
        guard let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }
}
