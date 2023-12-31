//
//  OPRuntimeType.swift
//  OPFoundation
//
//  Created by justin on 2022/12/20.
//

import Foundation

// From: OPJSEngine  中的 GeneralJSRuntime.swift
// JS虚拟机类型
@objc public enum OPRuntimeType: Int {
    case unknown = -1
    case jscore = 0 // jscore
    // case falconJSCore = 1 已下线
    // case oldJsCore = 2 // BDPJSRuntime 已下线
    case vmsdkJscore = 3 // vmsdk 提供的 jscore
    case vmsdkQjs = 4 // vmsdk 提供的 quickjs
}
