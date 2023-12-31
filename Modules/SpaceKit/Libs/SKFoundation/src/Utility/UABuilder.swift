//
//  UABuilder.swift
//  NonWVApp-SWIFT
//
//  Included OSS: OASDK
//  Copyright (c) 2020 OASDK
//  spdx license identifier: MIT

import Foundation
import UIKit

//eg. Darwin/16.3.0
public func darwinVersion() -> String {
    var sysinfo = utsname()
    uname(&sysinfo)
    let dv = String(bytes: Data(bytes: &sysinfo.release, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    return "Darwin/\(dv)"
}
//eg. CFNetwork/808.3
public func CFNetworkVersion() -> String {
//    let dictionary = Bundle(identifier: "com.apple.CFNetwork")?.infoDictionary!
    let version = "unknown"
    return "CFNetwork/\(version)"
}

//eg. iOS/10_1
public func deviceVersion() -> String {
    let currentDevice = UIDevice.current
    return "\(currentDevice.systemName)/\(currentDevice.systemVersion)"
}
//eg. iPhone5,2
public func deviceName() -> String {
    var sysinfo = utsname()
    uname(&sysinfo)
    return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
}
//eg. MyApp/1
public func appNameAndVersion() -> String {
    let dictionary = Bundle.main.infoDictionary!
    let version = dictionary["CFBundleShortVersionString"] as? String ?? "unknown"
    let name = dictionary["CFBundleName"] as? String ?? "unknown"
    return "\(name)/\(version)"
}
