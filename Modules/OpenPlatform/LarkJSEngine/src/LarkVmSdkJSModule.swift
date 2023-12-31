//
//  LarkVmSdkJSModule.swift
//  LarkJSEngine
//
//  Created by bytedance on 2022/11/8.
//

import Foundation
import vmsdk

@objc public protocol LarkVmSdkJSModule: JSModule {
    func setup()
}
