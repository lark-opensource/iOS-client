//
//  Utils.swift
//  LarkOpenAPIModel
//
//  Created by Meng on 2021/12/20.
//

import Foundation
import ECOInfra
import LarkContainer
import LarkSetting

public struct OpenAPIUtils {
    
    // TODOZJX
    @RealTimeFeatureGating(key: "openplatform.api.new_params_validation_enabled") public static var useNewParamsValidation: Bool
    
    /// API 多端一致 feature 开关
    public static func isEnable(feature: String) -> Bool {
        let configService = Injected<ECOConfigService>().wrappedValue
        guard let config = configService.getDictionaryValue(for: "api_crossplatform_refactor"),
              let enableFeatures = config["enable_features"] as? [String] else {
            return false
        }

        return enableFeatures.contains(feature)
    }
    
    public static func isBoolNSNumberType(_ num: NSNumber?) -> Bool {
        guard let number = num else {
            return false
        }
        
        return CFNumberGetType(number) == .charType
    }
    
    static func convertAPIParamsWeakTypeValue<T>(val: Any?, type: T.Type) -> T? {
        guard let value = val else { return nil }
        
        func str2Bool(str: String) -> Bool? {
            if str.isEmpty || str == "0" {
                return false
            } else if str == "1" {
                return true
            }
            
            return nil
        }
        func num2Bool(num: NSNumber) -> Bool? {
            if num == 0 {
                return false
            } else if num == 1 {
                return true
            }
            
            return nil
        }
        func forceCast2Str(_ value: Any) -> String {
            return (value as! String).trimmingCharacters(in: .whitespaces)
        }
        
        if T.self is Bool.Type {
            if value is String {
                return str2Bool(str:forceCast2Str(value)) as? T
            } else if value is NSNumber {
                return num2Bool(num:value as! NSNumber) as? T
            }
            
            return nil
        }
        
        if T.self is Int.Type {
            if value is String, let doubleVal = Double(forceCast2Str(value)) {
                return Int(doubleVal) as? T
            } else if value is NSNumber, !isBoolNSNumberType(value as? NSNumber) {
                return (value as! NSNumber).intValue as? T
            }
            
            return nil
        }
        if T.self is Int8.Type {
            if value is String, let doubleVal = Double(forceCast2Str(value)) {
                return Int8(doubleVal) as? T
            } else if value is NSNumber, !isBoolNSNumberType(value as? NSNumber) {
                return (value as! NSNumber).int8Value as? T
            }
            
            return nil
        }
        if T.self is Int16.Type {
            if value is String, let doubleVal = Double(forceCast2Str(value)) {
                return Int16(doubleVal) as? T
            } else if value is NSNumber, !isBoolNSNumberType(value as? NSNumber) {
                return (value as! NSNumber).int16Value as? T
            }
            
            return nil
        }
        if T.self is Int32.Type {
            if value is String, let doubleVal = Double(forceCast2Str(value)) {
                return Int32(doubleVal) as? T
            } else if value is NSNumber, !isBoolNSNumberType(value as? NSNumber) {
                return (value as! NSNumber).int32Value as? T
            }
            
            return nil
        }
        if T.self is Int64.Type {
            if value is String, let doubleVal = Double(forceCast2Str(value)) {
                return Int64(doubleVal) as? T
            } else if value is NSNumber, !isBoolNSNumberType(value as? NSNumber) {
                return (value as! NSNumber).int64Value as? T
            }
            
            return nil
        }
        if T.self is Float.Type {
            if value is String, let doubleVal = Double(forceCast2Str(value)) {
                return Float(doubleVal) as? T
            } else if value is NSNumber, !isBoolNSNumberType(value as? NSNumber) {
                return (value as! NSNumber) as? T
            }
            
            return nil
        }
        if T.self is CGFloat.Type {
            if value is String, let doubleVal = Double(forceCast2Str(value)) {
                return CGFloat(doubleVal) as? T
            } else if value is NSNumber, !isBoolNSNumberType(value as? NSNumber) {
                return (value as! NSNumber) as? T
            }
            
            return nil
        }
        if T.self is Double.Type {
            if value is String {
                return Double(forceCast2Str(value)) as? T
            } else if value is NSNumber, !isBoolNSNumberType(value as? NSNumber) {
                return (value as! NSNumber) as? T
            }
            
            return nil
        }
        
        if T.self is String.Type {
            if value is NSNumber, !isBoolNSNumberType(value as? NSNumber) {
                return "\(value as! NSNumber)" as? T
            }
            
            return nil
        }
        
        return nil
    }
}
