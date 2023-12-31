//
//  POISearchTracker.swift
//  LarkLocationPicker
//
//  Created by Fan Hui on 2022/6/12.
//

import UIKit
import Foundation
import Homeric
import LKCommonsTracker
import AppReciableSDK
import CoreLocation
import MapKit
#if canImport(AMapSearchKit)
import AMapSearchKit
#endif

public enum POIScene: String {
    case searchKeyword = "search"
    case searchAround = "nearby"
    case unknown = "unknown"
}

public enum POIMapType: String {
    case apple = "apple"
    case amap = "amap"
}

public enum POISearchResult: String {
    case success = "success"
    case fail = "fail"
}

public enum POIAuthorizationAccuracy: String {
    case full = "fine_location"
    case reduced = "coarse_location"
}

public final class POISearchTracker {
    private static var isFirstRequest: Bool = true
    private static var isFirstResult: Bool = true
    private var searchKeywordStartTime: CFTimeInterval?
    private var searchAroundStartTime: CFTimeInterval?
    private var latestRequestScene: POIScene = .unknown
    private lazy var locationManager = CLLocationManager()

    public func searchKeyword(mapType: POIMapType) {
        searchPOI(scene: .searchKeyword, mapType: mapType)
    }

    public func searchKeywordResult(mapType: POIMapType, count: Int, result: POISearchResult, error: Error? = nil) {
        searchPOIResult(scene: .searchKeyword, mapType: mapType, count: count, result: result, error: error)
    }

    public func searchAround(mapType: POIMapType) {
        searchPOI(scene: .searchAround, mapType: mapType)
    }

    public func searchAroundResult(mapType: POIMapType, count: Int, result: POISearchResult, error: Error? = nil) {
        searchPOIResult(scene: .searchAround, mapType: mapType, count: count, result: result, error: error)
    }

    public func searchPOI(scene: POIScene, mapType: POIMapType) {
        let netStatus = AppReciableSDK.shared.getActualNetStatus(start: CACurrentMediaTime(), end: CACurrentMediaTime())
        latestRequestScene = scene
        switch scene {
        case .searchKeyword:
            searchKeywordStartTime = CACurrentMediaTime()
        case .searchAround:
            searchAroundStartTime = CACurrentMediaTime()
        case .unknown:
            break
        default:
            break
        }
        var params: [AnyHashable: Any] = [ "net_status": String(netStatus),
                                           "is_first_poi": POISearchTracker.isFirstRequest ? "1" : "0",
                                           "map_type": mapType.rawValue,
                                           "location_accuracy_type": authroizationAccuracy().rawValue,
                                           "query_type": scene.rawValue ]
        Tracker.post(TeaEvent(Homeric.CORE_LOCATION_POI_SDK_DEV, params: params))
        POISearchTracker.isFirstRequest = false
    }

    public func searchPOIResult(scene: POIScene, mapType: POIMapType, count: Int, result: POISearchResult, error: Error? = nil) {
        var curScene = scene
        /// 如果传入unknow类型的场景，则选取最近一次请求的场景类型上报
        if curScene == .unknown {
            curScene = latestRequestScene
        }
        guard curScene != .unknown else { return }
        let startTime = (curScene == .searchKeyword) ? searchKeywordStartTime : searchAroundStartTime
        guard let preTime = startTime else { return }
        let currentTime = CACurrentMediaTime()
        let netStatus = AppReciableSDK.shared.getActualNetStatus(start: preTime, end: currentTime)
        let costTime = Int((currentTime - preTime) * 1000)
        var params: [AnyHashable: Any] = [ "net_status": String(netStatus),
                                           "is_first_poi": POISearchTracker.isFirstResult ? "1" : "0",
                                           "map_type": mapType.rawValue,
                                           "location_accuracy_type": authroizationAccuracy().rawValue,
                                           "query_type": curScene.rawValue,
                                           "sdk_cost": costTime,
                                           "data_size": String(count),
                                           "result_status": result.rawValue ]
        if result == .fail {
            params["result_code"] = self.getErrorCode(error: error)
        }
        Tracker.post(TeaEvent(Homeric.CORE_LOCATION_POI_DEV, params: params))
        POISearchTracker.isFirstResult = false
    }

    private func authroizationAccuracy() -> POIAuthorizationAccuracy {
        if #available(iOS 14.0, *) {
            switch locationManager.accuracyAuthorization {
            case .fullAccuracy:
                return .full
            case .reducedAccuracy:
                return .reduced
            }
        }
        /// iOS14之前不区分模糊定位，默认精确定位
        return .full
    }

    private func getErrorCode(error: Error?) -> String {
        var rawErrorCode = "Unknown"
        if let mkError = error as? MKError {
            rawErrorCode = String(mkError.code.rawValue)
        }
#if canImport(AMapSearchKit)
        if let amapError = error as? NSError, let errorCode = AMapSearchErrorCode(rawValue: amapError.code) {
            rawErrorCode = String(errorCode.rawValue)
        }
#endif
        return rawErrorCode
    }
}
