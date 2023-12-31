import CoreLocation
import Foundation
import LarkContainer
import LarkCoreLocation
import LarkOpenAPIModel
import LKCommonsLogging
import SKFoundation

// MARK: - GetLocation Model
final class FormsGetLocationParams: OpenAPIBaseParams {
    
    private static let timoutRange = 3...180
    
    private static let cacheTimeoutRange = 0...60
    
    // 由于swift语法严格，配合API框架想做到 optional 并且 nil 时按规范解析比较难，这里需要用 ! 规避一下
    // swiftlint:disable ImplicitlyUnwrappedOptionalRule
    @OpenAPIOptionalParam(jsonKey: "timeout")
    var timeout: Int!
    
    // 由于swift语法严格，配合API框架想做到 optional 并且 nil 时按规范解析比较难，这里需要用 ! 规避一下
    // swiftlint:disable ImplicitlyUnwrappedOptionalRule
    @OpenAPIOptionalParam(jsonKey: "cacheTimeout")
    var cacheTimeout: Int!
    
    // 由于swift语法严格，配合API框架想做到 optional 并且 nil 时按规范解析比较难，这里需要用 ! 规避一下
    // swiftlint:disable ImplicitlyUnwrappedOptionalRule
    @OpenAPIOptionalParam(jsonKey: "accuracy")
    var accuracy: FormsAPILocationAccuracy!
    
    // 需要在这保障上边 ! 的属性被正确赋值
    required init(with params: [AnyHashable : Any]) throws {
        let accuracyKey = _accuracy.jsonKey
        if params[accuracyKey] is NSNull {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setOuterMessage("parameter type invalid: \(accuracyKey)")
        }
        
        try super.init(with: params)
        
        accuracy = accuracy ?? .high
        timeout = timeout ?? 15
        cacheTimeout = cacheTimeout ?? 0
        
        if !Self.timoutRange.contains(self.timeout) {
            switch accuracy {
            case .high:
                timeout = 15
            case .best:
                timeout = 30
            case .none:
                break
            }
        }
        
        if !Self.cacheTimeoutRange.contains(cacheTimeout) {
            cacheTimeout = 0
        }
    }
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_timeout, _cacheTimeout, _accuracy]
    }
}

enum FormsAPILocationAccuracy: String, OpenAPIEnum {
    
    /// 当指定 high 时，期望精度值为100m
    case high
    
    /// 当指定 best 时期望精度值为20m
    case best
    
    var coreLocationAccuracy: CLLocationAccuracy {
        switch self {
        case .best:
            return kCLLocationAccuracyNearestTenMeters
        case .high:
            return kCLLocationAccuracyHundredMeters
        }
    }
}

enum FormsLocationType: String, OpenAPIEnum {
    
    case wgs84 = "wgs84"
    
    case gcj02 = "gcj02"
}

final class FormsGetLocationResult: OpenAPIBaseResult {
    
    enum AuthorizationAccuracy: String {
        
        case full
        
        case reduced
        
        case unknown
    }
    
    /// 纬度
    let latitude: CLLocationDegrees
    
    /// 经度
    let longitude: CLLocationDegrees
    
    /// 高度
    var altitude: CLLocationDistance
    
    /// 水平方向精度
    let horizontalAccuracy: CLLocationDistance
    
    /// 垂直方向精度
    let verticalAccuracy: CLLocationDistance
    
    /// 用户授予的精度
    let authorizationAccuracy: AuthorizationAccuracy
    
    /// 时间戳 毫秒
    let timestamp: Int64
    
    /// 坐标系类型
    let locationType: FormsLocationType
    
    init(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        altitude: CLLocationDistance,
        horizontalAccuracy: CLLocationDistance,
        verticalAccuracy: CLLocationDistance,
        authorizationAccuracy: AuthorizationAccuracy,
        time: Date,
        locationType: FormsLocationType
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        
        self.authorizationAccuracy = authorizationAccuracy
        self.timestamp =  Int64(time.timeIntervalSince1970 * 1000)
        self.locationType = locationType
    }
    
    override func toJSONDict() -> [AnyHashable : Any] {
        return [
            "latitude": latitude,
            "longitude": longitude,
            "altitude": altitude,
            "horizontalAccuracy": horizontalAccuracy,
            "verticalAccuracy": verticalAccuracy,
            "authorizationAccuracy": authorizationAccuracy.rawValue,
            "timestamp": timestamp,
            "type": locationType.rawValue
        ]
    }
}

/// 定位 API 传输给前端的错误码 双端一致
private enum FormsGetLocationErrorCode: Int {
    
    case unknown = -9999
    
    case denied = -1
    
    case restricted = -2
    
    case serviceDisabled = -3
    
    case adminDisabledGPS = -4
    
    case notDetermined = -5
    
    case psdaRestricted = -6
    
    case timeout = -7
    
    case authorization = -8
    
    case locationUnknown = -9
    
    case network = -10
    
    case riskOfFakeLocation = -11
    
}

// MARK: - getLocation
extension FormsLocation {
    
    func getLocation(
        params: FormsGetLocationParams,
        success: @escaping (FormsGetLocationResult) -> Void,
        failure: @escaping (OpenAPIError) -> Void
    ) {
        startLocationAuthCheck { error in
            if let error = error {
                let openErr = self.convertToOpenAPIError(error)
                failure(openErr)
                return
            }
            let request = SingleLocationRequest(
                desiredAccuracy: params.accuracy.coreLocationAccuracy,
                desiredServiceType: nil,
                timeout: TimeInterval(params.timeout),
                cacheTimeout: TimeInterval(params.cacheTimeout)
            )
            
            guard let task = implicitResolver?.resolve(SingleLocationTask.self, argument: request) else {
                let msg = "resolve SingleLocationTask error"
                let code = -9998
                Self.logger.error(msg)
                let e = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage(msg)
                    .setOuterMessage(msg)
                    .setOuterCode(code)
                failure(e)
                return
            }
            
            self.locationTasks[task.taskID] = task
            task.locationCompleteCallback = { [weak self] locationTask, result in
                guard let self = self else {
                    // 走到这里说明网页容器释放了
                    Self.logger.error("self is nil return, id: \(locationTask.taskID)")
                    return
                }
                switch result {
                case .success(let location):
                    let res = FormsGetLocationResult(
                        latitude: location.location.coordinate.latitude,
                        longitude: location.location.coordinate.longitude,
                        altitude: location.location.altitude,
                        horizontalAccuracy: location.location.horizontalAccuracy,
                        verticalAccuracy: location.location.verticalAccuracy,
                        authorizationAccuracy: self.convertAuthorizationAccuracy(location.authorizationAccuracy),
                        time: location.time,
                        locationType: self.convertLocationFrameType(location.locationType)
                    )
                    var extraInfo = [
                        "taskID": locationTask.taskID,
                        "locationType": res.locationType.rawValue,
                        "serviceType": location.serviceType == .apple ? "system" : "amap",
                        "timestamp": res.timestamp,
                        "authorizationAccuracy": res.authorizationAccuracy.rawValue,
                        "horizontalAccuracy": res.horizontalAccuracy,
                        "verticalAccuracy": res.verticalAccuracy,
                        "course": location.location.course, // 设备行驶的方向，以度数和相对于正北测量
                        "speed": location.location.speed, // 设备的瞬时速度，以米/秒为单位。
                        "speedAccuracy": location.location.speedAccuracy,
                    ]
                    if #available(iOS 13.4, *) {
                        extraInfo["courseAccuracy"] = location.location.courseAccuracy
                    }
                    if #available(iOS 15, *) {
                        extraInfo["sourceInformation"] = [
                            "isSimulatedBySoftware": location.location.sourceInformation?.isSimulatedBySoftware,
                            "isProducedByAccessory": location.location.sourceInformation?.isProducedByAccessory
                        ]
                    }
                    Self.logger.info("SingleLocationTask success, id: \(locationTask.taskID), extraInfo: \(extraInfo)")
                    success(res)
                case .failure(let error):
                    Self.logger.error("SingleLocationTask failure, id: \(locationTask.taskID)", error: error)
                    let openAPIErr = self.convertLocationError(error)
                    failure(openAPIErr)
                }
                self.locationTasks[locationTask.taskID] = nil
            }
            
            do {
                Self.logger.info("SingleLocationTask resume, id: \(task.taskID), timeout: \(params.timeout), cacheTimeout: \(params.cacheTimeout), accuracy: \(params.accuracy)")
                try task.resume(forToken: PSDAToken("LARK-PSDA-bitable_form_auto_location_field", type: .location))
            } catch {
                if let error = error as? LocationAuthorizationError {
                    Self.logger.error("SingleLocationTask catch LocationAuthorizationError", error: error)
                    let openAPIErr = self.convertToOpenAPIError(error)
                    failure(openAPIErr)
                } else {
                    Self.logger.error("SingleLocationTask catch Error", error: error)
                    let code = -9997
                    let e = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setMonitorMessage("task.resume error")
                        .setOuterMessage("task.resume error")
                        .setOuterCode(code)
                        .setError(error)
                    failure(e)
                }
                self.locationTasks[task.taskID] = nil
            }
        }
    }
    
    private func startLocationAuthCheck(completion: @escaping (LocationAuthorizationError?) -> Void) {
        Self.logger.info("LocationAuthCheck start")
        if let error = locationAuth.checkWhenInUseAuthorization() {
            if error == .notDetermined {
                Self.logger.info("LocationAuthCheck notDetermined, requestWhenInUseAuthorization start")
                locationAuth.requestWhenInUseAuthorization(forToken: PSDAToken("LARK-PSDA-bitable_form_auto_location_field_auth", type: .location)) { err in
                    Self.logger.error("requestWhenInUseAuthorization finish", error: err)
                    completion(err)
                }
            } else {
                Self.logger.error("LocationAuthCheck error", error: error)
                completion(error)
            }
        } else {
            Self.logger.info("LocationAuthCheck success")
            completion(nil)
        }
    }
    
    private func convertToOpenAPIError(_ error: LocationAuthorizationError) -> OpenAPIError {
        let msg = error.description
        Self.logger.error("getLocation error", error: error)
        let e = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setError(error)
            .setMonitorMessage(msg)
            .setOuterMessage(msg)
        switch error {
        case .denied:
            e.setOuterCode(FormsGetLocationErrorCode.denied.rawValue)
        case .restricted:
            e.setOuterCode(FormsGetLocationErrorCode.restricted.rawValue)
        case .serviceDisabled:
            e.setOuterCode(FormsGetLocationErrorCode.serviceDisabled.rawValue)
        case .adminDisabledGPS:
            e.setOuterCode(FormsGetLocationErrorCode.adminDisabledGPS.rawValue)
        case .notDetermined:
            e.setOuterCode(FormsGetLocationErrorCode.notDetermined.rawValue)
        case .psdaRestricted:
            e.setOuterCode(FormsGetLocationErrorCode.psdaRestricted.rawValue)
        }
        
        return e
    }
    
    private func convertLocationError(_ error: LocationError) -> OpenAPIError {
        let msg = error.description
        Self.logger.error("getLocation error", error: error.rawError)
        let e = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setError(error.rawError)
            .setMonitorMessage(msg)
            .setOuterMessage(msg)
        
        switch error.errorCode {
        case .unknown:
            e.setOuterCode(FormsGetLocationErrorCode.unknown.rawValue)
        case .timeout:
            e.setOuterCode(FormsGetLocationErrorCode.timeout.rawValue)
        case .authorization:
            e.setOuterCode(FormsGetLocationErrorCode.authorization.rawValue)
        case .locationUnknown:
            e.setOuterCode(FormsGetLocationErrorCode.locationUnknown.rawValue)
        case .network:
            e.setOuterCode(FormsGetLocationErrorCode.network.rawValue)
        case .riskOfFakeLocation:
            e.setOuterCode(FormsGetLocationErrorCode.riskOfFakeLocation.rawValue)
        case .psdaRestricted:
            e.setOuterCode(FormsGetLocationErrorCode.psdaRestricted.rawValue)
        }
        
        return e
    }
    
    private func convertAuthorizationAccuracy(_ acc: AuthorizationAccuracy) -> FormsGetLocationResult.AuthorizationAccuracy {
        switch acc {
        case .unknown:
            return .unknown
        case .full:
            return .full
        case .reduced:
            return .reduced
        }
    }
    
    private func convertLocationFrameType(_ type: LocationFrameType) -> FormsLocationType {
        switch type {
        case .wjs84:
            return .wgs84
        case .gcj02:
            return .gcj02
        }
    }
    
}
