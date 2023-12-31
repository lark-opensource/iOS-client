//
//  URLConvertible.swift
//  LarkResource
//
//  Created by 李晨 on 2020/3/25.
//

import Foundation

extension URL: ResourceConvertible {
    public static var convertEntry: ConvertibleEntryProtocol = ConvertibleEntry<URL> { (result: MetaResource, _: OptionsInfoSet) throws -> URL in
        guard case let .string(value) = result.index.value,
            let url = result.index.bundle.url(forResource: value, withExtension: nil) else {
            throw ResourceError.transformFailed
        }

        return url
    }
}
