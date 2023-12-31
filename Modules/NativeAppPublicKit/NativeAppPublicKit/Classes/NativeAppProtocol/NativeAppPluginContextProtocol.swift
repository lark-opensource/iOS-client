//
//  NativeAppPluginContextProtocol.swift
//  NativeAppPublicKit
//
//  Created by ByteDance on 2023/3/16.
//

import Foundation

@objc
public protocol NativeAppPluginContextProtocol {
    func fireEvent(event: NativeAppCustomEvent)
}
