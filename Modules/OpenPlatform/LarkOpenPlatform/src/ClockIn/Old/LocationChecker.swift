//
//  LocationChecker.swift
//  Action
//
//  Created by tujinqiu on 2019/8/11.
//

import Foundation
import CoreLocation
import LKCommonsLogging
import EEMicroAppSDK
import LarkOPInterface
import LarkSetting
import LarkCoreLocation

class LocationChecker: NSObject {
    var config: UploadInfoConfig?
    var locationTask: SingleLocationTask?
    private static let logger = Logger.oplog(LocationChecker.self, category: "LocationChecker")

    private enum ErrorType: Int {
        case none = 0
        case statusClosed = 1
        case geofencesEmpty = 2
        case unauthorized = 3
        case getFail = 4
        case timeout = 5
        case notInGeofence = 6
    }
    
    /// 安全合规 禁止后台定位
    static func requestLocationEnabled() -> Bool {
        // 如果造成极速打卡成功率下降，造成大量oncall，考虑打开此fg
        // 极速打开后台定位治理，fg默认关闭
        if FeatureGatingManager.shared.featureGatingValue(with: "openplatform.speedclockin.old.allow_bg_location") {
            Self.logger.warn("openplatform.speedclockin.old.allow_bg_location fg open allow bgLocaiton")
            return true
        }
        if UIApplication.shared.applicationState != .background {
            return true
        }
        Self.logger.error("Background positioning is not allowed")
        return false
    }
    
    //  FIXME：不要把强业务逻辑耦合到端上，建议下沉后端灵活调整
    //  外边保证不要同一时间连续调用该方法
    func checkLocation(location: Location?, callback: @escaping (LocationInfo?, Bool) -> Void) {
        let monitorEvent = MonitorEvent(name: MonitorEvent.terminalinfo_location)
        monitorEvent.setSnapshotId(config?.rule_snapshot_id)
        guard Self.requestLocationEnabled() else {
            Self.logger.error("not allow bgLocaiton fetchGPSInfo fail!")
            callback(nil,false)
            return
        }
        guard let lc = location, lc.status == true else {
            LocationChecker.logger.info("location status closed, location is nil or status is false")
            monitorEvent.addFail().addError(ErrorType.statusClosed.rawValue, "location status closed, location is nil or status is false").flush()
            callback(nil, false)
            return
        }
        guard let geofences = lc.geofences,
            !geofences.isEmpty,
            !geofences.filter({ (gf) -> Bool in
                gf.type == .circle
            }).isEmpty else {
                LocationChecker.logger.info("geofences empty, geofences is nil or geofences.isEmpty or geofences.circle.isEmpty")
                monitorEvent.addFail().addError(ErrorType.geofencesEmpty.rawValue, "geofences empty, geofences is nil or geofences.isEmpty or geofences.circle.isEmpty").flush()
                callback(nil, false)
                return
        }

        let authorizedStatus = CLLocationManager.authorizationStatus()
        if !(authorizedStatus == .authorizedAlways || authorizedStatus == .authorizedWhenInUse) {
            LocationChecker.logger.info("authorizedStatus is not authorizedAlways or authorizedWhenInUse, cannot location")
            monitorEvent.addFail().addError(ErrorType.unauthorized.rawValue, "authorizedStatus is not authorizedAlways or authorizedWhenInUse, cannot location").flush()
            callback(nil, false)
            return
        }
        LocationChecker.logger.error("use EMALocationTool get gps")
        let params: [String: Any] = ["timeout": 10, "type": "wgs84"]
        EMALocationTool.getLocationWithParams(params) { [weak self] (location) in
            var locationInfo: LocationInfo?
            guard let `self` = self else {
                callback(nil, false)
                LocationChecker.logger.error("self have not")
                return
            }
            var inScope = false
            if let lo = location {
                LocationChecker.logger.info("EMALocationTool success")
                if self.checkInLocation(location: lo, inRegion: lc) {
                    monitorEvent.addDuration().addSuccess().flush()
                    //对齐getlocation接口
                    let coord = CoordInfo(clCoord: lo.coordinate, acc: lo.horizontalAccuracy)
                    locationInfo = LocationInfo(coord: coord)
                    inScope = true
                } else {
                    LocationChecker.logger.error("not in geo fence")
                    monitorEvent.addDuration().addFail().addError(ErrorType.notInGeofence.rawValue, "not in geo fence").flush()
                }
            } else {
                LocationChecker.logger.error("EMALocationTool fail, EMALocationTool return nil location")
                monitorEvent.addDuration().addFail().addError(ErrorType.getFail.rawValue, "EMALocationTool fail, EMALocationTool return nil location").flush()
            }
            callback(locationInfo, inScope)
        }
    }

    private func checkInLocation(location: CLLocation, inRegion configLocation: Location) -> Bool {
        if configLocation.status, let geofences = configLocation.geofences {
            for gf in geofences where gf.type == .circle {
                if let center = gf.center?.toCLCoord(), let radius = gf.radius {
                    let region = CLCircularRegion(center: center, radius: radius, identifier: "LocationCheckerCircleRegion")
                    if region.contains(location.coordinate) {
                        return true
                    }
                }
            }
        }
        return false
    }
}
// swiftlint:enable all
