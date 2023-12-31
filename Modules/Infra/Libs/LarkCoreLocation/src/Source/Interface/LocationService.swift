//
//  LocationService.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 3/29/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import CoreLocation
/// 服务类型
public enum LocationServiceType: String, Codable {
    /// 高德地图 仅在飞书上起作用, lark是飞书在海外发行的版本。由于合规需求，lark上是没有高德地图的
    case aMap
    /// Apple 地图
    case apple

}
/// 坐标类型
public enum LocationFrameType {
    /// 地球坐标系 国际标准通用 https://zh.wikipedia.org/wiki/%E4%B8%96%E7%95%8C%E5%A4%A7%E5%9C%B0%E6%B5%8B%E9%87%8F%E7%B3%BB%E7%BB%9F
    case wjs84
    /// 火星坐标系 在中国大陆/港/澳门 使用 海外只有 wjs84， 在中国大陆/港/澳门 不允许将wjs84 转化为 gcj02 https://zh.wikipedia.org/wiki/%E4%B8%AD%E5%8D%8E%E4%BA%BA%E6%B0%91%E5%85%B1%E5%92%8C%E5%9B%BD%E5%9C%B0%E7%90%86%E6%95%B0%E6%8D%AE%E9%99%90%E5%88%B6#GCJ-02
    case gcj02
}
/// 坐标来源类型
public enum LarkLocationSourceType {
    /// 正常类型
    case normal
    /// 缓存 单次定位使用
    case cache
    /// 备选 在单次中再timeout的时间内没有发生错误,没有找到用户期望的精度,会使用本次定位中收到的最优结果。
    case backup
}
/// LarkCoreLocation组件封装的定位Model
public struct LarkLocation: CustomStringConvertible {
    /// 定位坐标
    public let location: CLLocation
    /// 坐标系类型
    public let locationType: LocationFrameType
    /// 定位服务类型
    public let serviceType: LocationServiceType
    /// 收到Location的时间
    public let time: Date
    /// iOS 系统对当前APP的精度授权 （iOS 13以上：模糊权限，精确定位权限， iOS13一下为unknown 默认为精确授权）
    public let authorizationAccuracy: AuthorizationAccuracy

    public init(location: CLLocation, locationType: LocationFrameType, serviceType: LocationServiceType, time: Date, authorizationAccuracy: AuthorizationAccuracy) {
        self.location = location
        self.locationType = locationType
        self.serviceType = serviceType
        self.time = time
        self.authorizationAccuracy = authorizationAccuracy
    }

    /// location 来源
    internal var sourceType: LarkLocationSourceType = .normal
    private let dateFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .full
        return formatter
    }()

    public var description: String {
        let timeString = "@ \(dateFormatter.string(from: Date()))"
        let isProducedByAccessory: String
        let isSimulatedBySoftware: String
        if #available(iOS 15.0, *) {
            let sourceInformation = location.sourceInformation
            isSimulatedBySoftware = String(describing: sourceInformation?.isSimulatedBySoftware)
            isProducedByAccessory = String(describing: sourceInformation?.isProducedByAccessory)
        } else {
            isSimulatedBySoftware = ""
            isProducedByAccessory = ""
        }
        return """
        LarkLocation: \
        { \
        sourceType: \(sourceType), \
        serviceType: \(serviceType), \
        locationType: \(locationType), \
        authorizationAccuracy: \(authorizationAccuracy), \
        location: { [ \(location) ], \
        isSimulatedBySoftware: \(isSimulatedBySoftware), \
        isProducedByAccessory: \(isProducedByAccessory) \
        }, \
        time: \(timeString) \
        }
        """
    }

}

/// 定位SDK的统一协议
public protocol LocationService {
    /// 服务类型
    var serviceType: LocationServiceType { get }
    /// 设定定位的最小更新距离。单位米，默认为 kCLDistanceFilterNone，表示只要检测到设备位置发生变化就会更新位置信息。
    var distanceFilter: CLLocationDistance { get set }
    /// 设定期望的定位精度。单位米，默认为 kCLLocationAccuracyBest。
    /// 定位服务会尽可能去获取满足desiredAccuracy的定位结果，但不保证一定会得到满足期望的结果。
    /// 注意：设置为kCLLocationAccuracyBest或kCLLocationAccuracyBestForNavigation时，
    /// 单次定位会在达到locationTimeout设定的时间后，将时间内获取到的最高精度的定位结果返回。
    /// ⚠️ 当iOS14及以上版本，模糊定位权限下可能拿不到设置精度的经纬度
    var desiredAccuracy: CLLocationAccuracy { get set }
    /// 指定定位是否会被系统自动暂停。默认为NO。
    var pausesLocationUpdatesAutomatically: Bool { get set }
    /// 回调代理 在主线程触发 delegate 回调
    var delegate: LocationServiceDelegate? { get set }
    /// 开始持续定位。
    func startUpdatingLocation()
    /// 停止持续定位。
    func stopUpdatingLocation()

}
/// 定位服务的回调
public protocol LocationServiceDelegate: AnyObject {
    /**
     *  @brief 当定位发生错误时，会调用代理的此方法。
     *  @param manager 定位 LocationService 类。
     *  @param error 返回的错误，参考 CLError 。
     */
    func locationService(_ manager: LocationService, didFailWithError error: Error)
    /**
     *  @brief 连续定位回调函数.
     *  @param manager 定位 LocationService 类。
     *  @param location 定位结果。
     */
    func locationService(_ manager: LocationService, didUpdate locations: [LarkLocation])
    /**
     *  @brief 定位权限状态改变时回调函数。
     *  @param manager 定位 LocationService 类。
     *  @param locationManager  定位CLLocationManager类，
     *  可通过locationManager.authorizationStatus获取定位权限，
     *  通过locationManager.accuracyAuthorization获取定位精度权限
     */
    func locationService(_ manager: LocationService,
                         locationManagerDidChangeAuthorization locationManager: CLLocationManager)

}
