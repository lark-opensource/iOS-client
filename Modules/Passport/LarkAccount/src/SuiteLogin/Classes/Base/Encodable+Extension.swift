//
//  Encodable+Extension.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/22.
//

import Foundation

enum EncodableError: Error, CustomStringConvertible {
    case castToDictFail

    var description: String {
        switch self {
        case .castToDictFail:
            return "EncodableError.castToDictFail"
        }
    }
}

extension Decodable {
    static func from(_ data: Data) throws -> Self {
        return try JSONDecoder().decode(Self.self, from: data)
    }
}

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try asData()
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        guard let dict = jsonObject as? [String: Any] else {
            throw EncodableError.castToDictFail
        }
        return dict
    }

    func asData() throws -> Data {
        let data = try JSONEncoder().encode(self)
        return data
    }
}

extension Dictionary {
    func asData() throws -> Data {
        let data = try JSONSerialization.data(withJSONObject: self, options: .init())
        return data
    }

}
