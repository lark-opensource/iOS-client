//
//  StringConvertible.swift
//  LarkResource
//
//  Created by 李晨 on 2020/2/20.
//

import Foundation

extension String: ResourceConvertible {
    public static var convertEntry: ConvertibleEntryProtocol = ConvertibleEntry<String> { (result: MetaResource, _: OptionsInfoSet) throws -> String in
        guard case let .string(value) = result.index.value else {
            throw ResourceError.transformFailed
        }
        switch result.index.type {
        case .table:
            let baseKey = result.key.baseKey.key as String
            let localizeValue = "\0"
            var str = NSLocalizedString(baseKey, tableName: value, bundle: result.index.bundle, value: localizeValue, comment: "")
            if str != localizeValue {
                return str
            }
        default:
            break
        }
        return value
    }
}
