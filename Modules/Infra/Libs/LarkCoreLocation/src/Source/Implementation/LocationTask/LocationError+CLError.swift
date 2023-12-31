//
//  LocationError+CLError.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 4/1/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import CoreLocation
#if canImport(AMapLocationKit)
import AMapLocationKit
#endif

extension LocationError {
    static func crateFrom(error: Error) -> LocationError {
        let result: LocationError
#if canImport(AMapLocationKit)
        if let clError = error as? CLError {
            result = apple(clerror: clError)
        } else if let nsError = error as? NSError, let errorCode = AMapLocationErrorCode(rawValue: nsError.code) {
            result = amap(errorCode: errorCode, error: nsError)
        } else {
            result = LocationError(rawError: error, errorCode: .unknown, message: "location server received error: \(error)")
        }
#else
        if let clError = error as? CLError {
            result = apple(clerror: clError)
        } else {
            result = LocationError(rawError: error, errorCode: .unknown, message: "location server received error: \(error)")
        }

#endif
        return result
    }
}

/// CLError 到 LocationError 的映射
private extension LocationError {
    private static let unknownCodeAndMessage = (ErrorCode.unknown, "CLError error: unknow error")
    static func apple(clerror: CLError) -> LocationError {
        let errCode: ErrorCode
        let message: String
        switch clerror.code {
            // location is currently unknown, but CL will keep trying
        case .locationUnknown:
            errCode = .locationUnknown
            message = "CLError error: location is updating, location is currently unknown"
            // Access to location or ranging has been denied by the user
        case .denied:
            errCode = .authorization
            message = "CLError error: location is updating, Access to location or ranging has been denied by the user"
            // general, network-related error
        case .network:
            errCode = .network
            message = "CLError error: location is updating, network-related error"
            // heading could not be determined
        case .headingFailure:
            (errCode, message) = unknownCodeAndMessage
            // Location region monitoring has been denied by the user
        case .regionMonitoringDenied:
            (errCode, message) = unknownCodeAndMessage
            // A registered region cannot be monitored
        case .regionMonitoringFailure:
            (errCode, message) = unknownCodeAndMessage
            // CL could not immediately initialize region monitoring
        case .regionMonitoringSetupDelayed:
            (errCode, message) = unknownCodeAndMessage
            // While events for this fence will be delivered, delivery will not occur immediately
        case .regionMonitoringResponseDelayed:
            (errCode, message) = unknownCodeAndMessage
            // A geocode request yielded no result
        case .geocodeFoundNoResult:
            (errCode, message) = unknownCodeAndMessage
            // A geocode request yielded a partial result
        case .geocodeFoundPartialResult:
            (errCode, message) = unknownCodeAndMessage
            // A geocode request was cancelled
        case .geocodeCanceled:
            (errCode, message) = unknownCodeAndMessage
            // Deferred mode failed
        case .deferredFailed:
            (errCode, message) = unknownCodeAndMessage
            // Deferred mode failed because location updates disabled or paused
        case .deferredNotUpdatingLocation:
            (errCode, message) = unknownCodeAndMessage
            // Deferred mode not supported for the requested accuracy
        case .deferredAccuracyTooLow:
            (errCode, message) = unknownCodeAndMessage
            // Deferred mode does not support distance filters
        case .deferredDistanceFiltered:
            (errCode, message) = unknownCodeAndMessage
            // Deferred mode request canceled a previous request
        case .deferredCanceled:
            (errCode, message) = unknownCodeAndMessage
            // Ranging cannot be performed 测距相关
        case .rangingUnavailable:
            (errCode, message) = unknownCodeAndMessage
            // General ranging failure
        case .rangingFailure:
            (errCode, message) = unknownCodeAndMessage
            // Authorization request not presented to user
        case .promptDeclined:
            (errCode, message) = unknownCodeAndMessage
        case .historicalLocationError: // use unknown default setting to fix warning
            (errCode, message) = unknownCodeAndMessage
            // 未知错误
        @unknown default:
            (errCode, message) = unknownCodeAndMessage
        }
        return LocationError(rawError: clerror, errorCode: errCode, message: message)
    }
}
#if canImport(AMapLocationKit)
private extension LocationError {
    static func amap(errorCode: AMapLocationErrorCode, error: NSError) -> LocationError {
        let errCode: ErrorCode
        let message: String
        switch errorCode {
        case .unknown:
            errCode = .unknown
            message = "aMap error: unknown"
            // AMapLocationErrorLocateFailed = 2,          ///<定位错误
        case .locateFailed:
            errCode = .unknown
            message = "aMap error: unknown"
        case .reGeocodeFailed:
            errCode = .unknown
            message = "aMap error: reGeocodeFailed"
        case .timeOut:
            errCode = .timeout
            message = "aMap error: timeout"
        case .canceled:
            errCode = .unknown
            message = "aMap error: canceled"
        case .cannotFindHost:
            errCode = .network
            message = "aMap error: cannotFindHost"
        case .badURL:
            errCode = .network
            message = "aMap error: badURL"
        case .notConnectedToInternet:
            errCode = .network
            message = "aMap error: notConnectedToInternet"
        case .cannotConnectToHost:
            errCode = .network
            message = "aMap error: cannotConnectToHost"
        case .regionMonitoringFailure:
            errCode = .unknown
            message = "aMap error: regionMonitoringFailure"
        case .riskOfFakeLocation:
            errCode = .riskOfFakeLocation
            message = "aMap error: riskOfFakeLocation"
        case .noFullAccuracyAuth:
            errCode = .authorization
            message = "aMap error: noFullAccuracyAuth"
        @unknown default:
            errCode = .unknown
            message = "aMap error: unknown error"
        }
        return LocationError(rawError: error, errorCode: errCode, message: message)
    }
}
#endif
