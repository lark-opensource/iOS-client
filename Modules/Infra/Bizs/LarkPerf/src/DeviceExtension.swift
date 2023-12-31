//
//  DeviceExtension.swift
//  LarkMessageCore
//
//  Created by bytedance on 2021/3/23.
//

import Foundation

/*
  区分不同机型
 */
public final class DeviceExtension {
    //低端iphone机型
    static let iPhone7: String      = "iPhone7"
    static let iPhone7P: String     = "iPhone7P"
    static let iPhoneSE: String     = "iPhoneSE"
    static let iPhone6SP: String    = "iPhone6SP"
    static let iPhone6S: String     = "iPhone6S"
    static let iPhone6P: String     = "iPhone6P"
    static let iPhone6: String      = "iPhone6"
    static let iPhone5S: String     = "iPhone5S"
    static let iPhone5C: String     = "iPhone5C"
    static let iPhone5: String      = "iPhone5"
    static let iPhone4: String      = "iPhone4"
    static let iPhone4S: String     = "iPhone4S"

    //中端iphone机型
    static let iPhone8: String      = "iPhone8"
    static let iPhone8Plus: String  = "iPhone8Plus"
    static let iPhoneX: String      = "iPhoneX"

    //高端iphone机型
    static let iPhoneXS: String         = "iPhoneXS"
    static let iPhoneXSMax: String      = "iPhoneXSMax"
    static let iPhoneXR: String         = "iPhoneXR"
    static let iPhone11: String         = "iPhone11"
    static let iPhone11Pro: String      = "iPhone11Pro"
    static let iPhone11ProMax: String   = "iPhone11ProMax"
    static let iPhone12mini: String     = "iPhone12mini"
    static let iPhone12: String         = "iPhone12"
    static let iPhone12Pro: String      = "iPhone12Pro"
    static let iPhone12ProMax: String   = "iPhone12ProMax"

    //其它机型
    static let iPodTouch5: String               = "iPodTouch5"
    static let iPodTouch6: String               = "iPodTouch6"
    static let iPad2: String                    = "iPad2"
    static let iPad3: String                    = "iPad3"
    static let iPad4: String                    = "iPad4"
    static let iPadAir: String                  = "iPadAir"
    static let iPadAir2: String                 = "iPadAir2"
    static let iPad5: String                    = "iPad5"
    static let iPadMini: String                 = "iPadMini"
    static let iPadMini2: String                = "iPadMini2"
    static let iPadMini3: String                = "iPadMini3"
    static let iPadMini4: String                = "iPadMini4"
    static let iPadPro97Inch: String            = "iPadPro_9_7_Inch"
    static let iPadPro129Inch: String           = "iPadPro_12_9_Inch"
    static let iPadPro129Inch2: String          = "iPadPro_12_9_Inch2"
    static let Generation: String               = "Generation"
    static let iPadPro105Inch: String           = "iPadPro_10_5_Inch"
    static let AppleTV: String                  = "AppleTV"
    static let AppleTV4K: String                = "AppleTV4K"
    static let HomePod: String                  = "HomePod"
    static let Simulator: String                = "Simulator"

    //机型分类
   public enum DeviceClassify {
        case unknownClassify    //未知机型
        case lowIphone          //低端iphone
        case middleIphone       //中端iphone
        case hightIphone        //高端iphone
        case otherClassify      //其它机型
    }

    //当前机型的名称
   static var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        switch identifier {
        case "iPod5,1":                                 return iPodTouch5
        case "iPod7,1":                                 return iPodTouch6
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return iPhone4
        case "iPhone4,1":                               return iPhone4S
        case "iPhone5,1", "iPhone5,2":                  return iPhone5
        case "iPhone5,3", "iPhone5,4":                  return iPhone5C
        case "iPhone6,1", "iPhone6,2":                  return iPhone5S
        case "iPhone7,2":                               return iPhone6
        case "iPhone7,1":                               return iPhone6P
        case "iPhone8,1":                               return iPhone6S
        case "iPhone8,2":                               return iPhone6SP
        case "iPhone9,1", "iPhone9,3":                  return iPhone7
        case "iPhone9,2", "iPhone9,4":                  return iPhone7P
        case "iPhone8,4":                               return iPhoneSE
        case "iPhone10,1", "iPhone10,4":                return iPhone8
        case "iPhone10,2", "iPhone10,5":                return iPhone8Plus
        case "iPhone10,3", "iPhone10,6":                return iPhoneX

        case "iPhone11,2":                              return iPhoneXS
        case "iPhone11,4", "iPhone11,6":                return iPhoneXSMax
        case "iPhone11,8":                              return iPhoneXR
        case "iPhone12,1":                              return iPhone11
        case "iPhone12,3":                              return iPhone11Pro
        case "iPhone12,5":                              return iPhone11ProMax
        case "iPhone13,1":                              return iPhone12mini
        case "iPhone13,2":                              return iPhone12
        case "iPhone13,3":                              return iPhone12Pro
        case "iPhone13,4":                              return iPhone12ProMax

        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return iPad2
        case "iPad3,1", "iPad3,2", "iPad3,3":           return iPad3
        case "iPad3,4", "iPad3,5", "iPad3,6":           return iPad4
        case "iPad4,1", "iPad4,2", "iPad4,3":           return iPadAir
        case "iPad5,3", "iPad5,4":                      return iPadAir2
        case "iPad6,11", "iPad6,12":                    return iPad5
        case "iPad2,5", "iPad2,6", "iPad2,7":           return iPadMini
        case "iPad4,4", "iPad4,5", "iPad4,6":           return iPadMini2
        case "iPad4,7", "iPad4,8", "iPad4,9":           return iPadMini3
        case "iPad5,1", "iPad5,2":                      return iPadMini4
        case "iPad6,3", "iPad6,4":                      return iPadPro97Inch
        case "iPad6,7", "iPad6,8":                      return iPadPro129Inch
        case "iPad7,1", "iPad7,2":                      return iPadPro129Inch2
        case "iPad7,3", "iPad7,4":                      return Generation
        case "AppleTV5,3":                              return AppleTV
        case "AppleTV6,2":                              return AppleTV4K
        case "AudioAccessory1,1":                       return HomePod
        case "i386", "x86_64":                          return Simulator
        default:                                        return identifier
        }
    }

    /*
     判断当前机型分类
     */
    static func checkDeviceClassify() -> DeviceClassify {
        let modelName = DeviceExtension.modelName
        //低端机
        if modelName == iPhone7 || modelName == iPhone7P
            || modelName == iPhoneSE || modelName == iPhone6SP
            || modelName == iPhone6S || modelName == iPhone6P
            || modelName == iPhone6 || modelName == iPhone5S
            || modelName == iPhone5 || modelName == iPhone5C
            || modelName == iPhone4 || modelName == iPhone4S {
            return .lowIphone
        }
        //中端机
        if modelName == iPhone8 || modelName == iPhone8Plus
            || modelName == iPhoneX {
            return .middleIphone
        }
        return .otherClassify
    }

    //当前机型
    public static let currentDeviceClassify: DeviceClassify = {
        return DeviceExtension.checkDeviceClassify()
    }()

    /*
     判断是否是低端机型
     */
    public static let isLowDeviceClassify: Bool = {
        if DeviceExtension.checkDeviceClassify() == .lowIphone {
            return true
        }
        return false
    }()

    /*
     判断是否是中端机型
     */
    public static let isMiddleDeviceClassify: Bool = {
        if DeviceExtension.checkDeviceClassify() == .middleIphone {
            return true
        }
        return false
    }()
}
