//
//  DictionaryConvertable.swift
//  SKFoundation
//
//  Created by zengsenyuan on 2022/12/12.
//  


import Foundation

public protocol DictionaryConvertable: Codable {
    
}

public extension DictionaryConvertable {
    
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }
}
