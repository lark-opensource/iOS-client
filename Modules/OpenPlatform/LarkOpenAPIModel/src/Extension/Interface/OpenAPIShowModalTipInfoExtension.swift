//
//  OpenAPIShowModalTipInfoExtension.swift
//  LarkOpenPluginManager
//
//  Created by baojianjun on 2023/8/14.
//

import Foundation

open class OpenAPIShowModalTipInfoExtension: OpenBaseExtension {
    open func applicationName() -> String { "" }
    
    @OpenAPIRequiredExtension
    public var commonExtension: OpenAPICommonExtension
    
    public override var autoCheckProperties: [OpenAPIInjectExtension] {
        [_commonExtension]
    }
}
