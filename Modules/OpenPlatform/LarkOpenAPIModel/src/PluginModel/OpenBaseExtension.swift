//
//  OpenBaseExtension.swift
//  LarkOpenPluginManager
//
//  Created by baojianjun on 2023/7/18.
//

import Foundation

public protocol OpenAPIInjectExtension: AnyObject {
    func configAndCheck(with extensionResolver: ExtensionResolver, context: OpenAPIContext) throws
}

open class OpenBaseExtension {
    
    public required init(extensionResolver: ExtensionResolver, context: OpenAPIContext) throws {
        try self.autoCheckProperties.forEach({ inject in
            try inject.configAndCheck(with: extensionResolver, context: context)
        })
    }
    
    open var autoCheckProperties: [OpenAPIInjectExtension] {
        return []
    }
}
