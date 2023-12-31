//
//  OPNetStatusHelperBridge.swift
//  OPFoundation
//
//  Created by MJXin on 2021/8/26.
//

import Foundation
import LarkContainer

@objcMembers

/// 此类为解决 OC - Swift - OC 循环引用导致编译错误问题, ⚠️ 请不要在此类中引用 OC
public final class OPNetStatusHelperBridge: NSObject {
    
    private static var service: OPNetStatusHelper? {
        InjectedOptional<OPNetStatusHelper>().wrappedValue
    }
    
    @objc public static var opNetStatus: String {
        service?.status.rawValue ?? "unknown"
    }
    @objc public static var rustNetStatus: Int {
        // 默认值为 Rust unknown
        service?.rustNetStatus.rawValue ?? 0
    }
    @objc public static var ttNetStatus: Int {
        // 默认值为 TTNet unknown
        service?.ttNetStatus.rawValue ?? 0
    }
}

