//
//  OpenNativeAppProtocol.swift
//  NativeAppPublicKit
//
//  Created by ByteDance on 2023/1/10.
//

import Foundation

@objc
public protocol OpenNativeAppProtocol: NativeAppExtensionProtocol {
    
    @objc
    func setupVC(url: String) -> UIViewController
    
}
