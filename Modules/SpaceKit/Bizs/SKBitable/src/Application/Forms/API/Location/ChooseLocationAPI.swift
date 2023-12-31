import CoreLocation
import Foundation
import LarkCoreLocation
import LarkLocationPicker
import LarkOpenAPIModel
import LKCommonsLogging
import LarkUIKit
import SKFoundation

final class FormsChooseLocationResult: OpenAPIBaseResult {
    
    let name: String
    
    let address: String
    
    let latitude: CLLocationDegrees
    
    let longitude: CLLocationDegrees
    
    init(
        name: String,
        address: String,
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees
    ) {
        
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        super.init()
    }
    
    override func toJSONDict() -> [AnyHashable : Any] {
        return [
            "name": name,
            "address": address,
            "latitude": latitude,
            "longitude": longitude
        ]
    }
}

// MARK: - ChooseLocation
extension FormsLocation {
    
    func chooseLocation(
        vc: UIViewController,
        success: @escaping (FormsChooseLocationResult) -> Void,
        failure: @escaping (OpenAPIError) -> Void
    ) {
        
        let viewController = ChooseLocationViewController(
            forToken: PSDAToken("LARK-PSDA-bitable_form_map_location_field", type: .location)
        )
        
        viewController.cancelCallBack = {
            let msg = "chooseLocation fail, user cancel"
            let code = -1
            Self.logger.error(msg)
            let e = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            failure(e)
        }
        
        viewController.sendLocationCallBack = { (location) in
            Self.logger.info("chooseLocation callback")
            let result = FormsChooseLocationResult(
                name: location.name,
                address: location.address,
                latitude:location.location.latitude,
                longitude: location.location.longitude
            )
            success(result)
        }
        
        let navi = LkNavigationController(rootViewController: viewController)
        navi.modalPresentationStyle = .overFullScreen
        navi.navigationBar.isTranslucent = false
        vc.present(navi, animated: true)
    }
    
}
