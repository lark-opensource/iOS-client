//
//  DataConvertible.swift
//  LarkResource
//
//  Created by 李晨 on 2020/2/20.
//

import Foundation

extension Data: ResourceConvertible {
    public static var convertEntry: ConvertibleEntryProtocol = ConvertibleEntry<Data> { (result: MetaResource, _: OptionsInfoSet) throws -> Data in
        switch result.index.value {
        case .string(let value):
            if let path = result.index.bundle.path(forResource: value, ofType: nil),
                let url = URL(string: path),
                // lint:disable:next lark_storage_check - 读 bundle 数据
                let data = try? Data(contentsOf: url) {
                return data
            }
        case .data(let data):
            return data
        default:
            break
        }
        throw ResourceError.transformFailed
    }
}
