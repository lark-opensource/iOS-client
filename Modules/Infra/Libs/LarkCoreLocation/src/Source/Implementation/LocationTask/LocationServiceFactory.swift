//
//  LocationServiceProviderImp.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 3/31/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LKCommonsLogging
import LarkPrivacySetting

struct LocationServiceFactory: LocationTaskSetting {
    private static let logger = Logger.log(LocationServiceFactory.self, category: "LarkCoreLocation")

    func isAdminAllowAmap() -> Bool {
        let result = LarkLocationAuthority.checkAmapAuthority()
        Self.logger.info("LocationServiceFactory isAdminAllowAmap result:\(result)")
        return result
    }

    func getRightLocationServiceType(_ type: LocationServiceType?) -> LocationServiceType {
        // type 优先级判定 isAdminAllowAmap优先级最高，如果isAdminAllowAmap为false强制使用apple
        //settings.forceServiceType > user-type > settings.defaultServiceType
        guard isAdminAllowAmap() else {
            return .apple
        }
        let aType: LocationServiceType
        if let forceServiceType = self.forceServiceType {
            aType = forceServiceType
            Self.logger.info("getRightLocationServiceType use settings force type: \(forceServiceType) origin type is: \(String(describing: type))")
        } else {
            aType = type ?? defaultServiceType
            Self.logger.info("getRightLocationServiceType origin type is: \(String(describing: type)) defaultType is: \(defaultServiceType)")
        }
        return aType
    }
    func getLocationService(type: LocationServiceType?) -> LocationService {
        let aType: LocationServiceType = getRightLocationServiceType(type)
        // Lark没有 aMap(高德地图)
        #if canImport(AMapLocationKit)
            switch aType {
            case .aMap:
                return AMapLocationService()
            case .apple:
                return AppleLocationService()
            }
        #else
            return AppleLocationService()
        #endif
    }

}
