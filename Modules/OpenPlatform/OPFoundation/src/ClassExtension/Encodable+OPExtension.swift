//
//  Encodable+OPExtension.swift
//  OPFoundation
//
//  Created by 刘焱龙 on 2023/3/1.
//

import Foundation

public enum EncodableError: Error {
    case castToDictFail

    var localizedDescription: String {
        switch self {
        case .castToDictFail:
            return "EncodableError.castToDictFail"
        }
    }
}

public extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        guard let dict = jsonObject as? [String: Any] else {
            throw EncodableError.castToDictFail
        }
        return dict
    }
}
