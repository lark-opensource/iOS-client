import CoreLocation
import EENavigator
import Foundation
import LarkCoreLocation
import LarkLocationPicker
import LarkOpenAPIModel
import SKFoundation

struct FormsLocationConstants {
    
    static let longitudeRange = -180.0...180.0
    
    static let latitudeRange = -90.0...90.0
    
    static let scaleMin = 5
    
    static let scaleMax = 18
    
    static let scaleRange = scaleMin...scaleMax
}

final class FormsOpenLocationParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "latitude", validChecker: {
        FormsLocationConstants.latitudeRange.contains($0)
    })
    var latitude: CLLocationDegrees
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "longitude", validChecker: {
        FormsLocationConstants.longitudeRange.contains($0)
    })
    var longitude: CLLocationDegrees
    
    @OpenAPIOptionalParam(jsonKey: "name")
    var name: String?
    
    @OpenAPIOptionalParam(jsonKey: "address")
    var address: String?
    
    var scale: Int = FormsLocationConstants.scaleMax
    
    required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        
        // 类型兼容String，以免引起双端打开地图scale效果不一致
        if let locationScale = params["scale"] as? NSNumber {
            self.scale = locationScale.intValue
        } else if let locationScale = Int(params["scale"] as? String ?? "") {
            self.scale = locationScale
        }
        
        let scale = self.scale
        if !FormsLocationConstants.scaleRange.contains(scale) {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setOuterMessage("parameter value invalid: scale ")
        }
        
    }
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_latitude, _longitude, _name, _address]
    }
}

extension FormsLocation {
    
    func openLocation(
        vc: UIViewController,
        params: FormsOpenLocationParams,
        success: @escaping () -> Void,
        failure: @escaping (OpenAPIError) -> Void
    ) {
        let coordinate2D = CLLocationCoordinate2D(latitude: params.latitude, longitude: params.longitude)
        let setting = LocationSetting(
            name: params.name ?? "",
            description: params.address ?? "",
            center: coordinate2D,
            zoomLevel: Double(params.scale),
            isCrypto: false,
            defaultAnnotation: true,
            needRightBtn: false
        )
        let locationController = OpenLocationController(setting: setting)
        Navigator
            .shared
            .push(
                locationController,
                from: vc
            )
        success()
    }
    
}
