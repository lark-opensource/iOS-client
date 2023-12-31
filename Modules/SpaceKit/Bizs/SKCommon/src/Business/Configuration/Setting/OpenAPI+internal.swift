//
//  OpenAPI+internal.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2021/12/9.
//  


import Foundation
import UIKit
import SKInfra

extension OpenAPI {
    
    public static var enableOptimizateLoadUrl: Bool {
        // 打开文档loadURL放下个runloop, 只针对iPhone7以下机型GA，其他机型不处理
        // https://bytedance.feishu.cn/wiki/wikcnDLvxEBiFTTniVlnY5X34sg
        if UIDevice.isPerformanceWeakerThanIphone7 {
            return true
        } else {
            return false
        }
    }
}

private extension UIDevice {
    
    /// 性能低于iPhone7
    static var isPerformanceWeakerThanIphone7: Bool {
        let identifierList = ["iPhone3,1", "iPhone3,2", "iPhone3,3",    // "iPhone 4"
                              "iPhone4,1",                              // "iPhone 4s"
                              "iPhone5,1", "iPhone5,2",                 // "iPhone 5"
                              "iPhone5,3", "iPhone5,4",                 // "iPhone 5c"
                              "iPhone6,1", "iPhone6,2",                 // "iPhone 5s"
                              "iPhone7,2",                              // "iPhone 6"
                              "iPhone7,1",                              // "iPhone 6 Plus"
                              "iPhone8,1",                              // "iPhone 6s"
                              "iPhone8,2",                              // "iPhone 6s Plus"
                              "iPhone8,4",                              // "iPhone SE"
                              "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4",   // "iPad 2"
                              "iPad3,1", "iPad3,2", "iPad3,3",              // "iPad (3rd generation)"
                              "iPad3,4", "iPad3,5", "iPad3,6",              // "iPad (4th generation)"
                              "iPad6,11", "iPad6,12",                       // "iPad (5th generation)"
                              "iPad4,1", "iPad4,2", "iPad4,3",          // "iPad Air"
                              "iPad5,3", "iPad5,4",                     // "iPad Air 2"
                              "iPad2,5", "iPad2,6", "iPad2,7",          // "iPad mini"
                              "iPad4,4", "iPad4,5", "iPad4,6",          // "iPad mini 2"
                              "iPad4,7", "iPad4,8", "iPad4,9",          // "iPad mini 3"
                              "iPad5,1", "iPad5,2",                     // "iPad mini 4"
                              "iPad6,3", "iPad6,4",                         // "iPad Pro (9.7-inch)"
                              "iPad7,3", "iPad7,4",                         // "iPad Pro (10.5-inch)"
                              "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4",   // "iPad Pro (11-inch) (1st generation)"
                              "iPad6,7", "iPad6,8"                          // "iPad Pro (12.9-inch) (1st generation)"
                              ]
        return identifierList.contains(modelName)
    }
    
    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let result = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return result
    }()
}
