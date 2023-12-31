import CoreLocation
import Foundation
import LarkLocationPicker
import LarkLocalizations
import LarkOpenAPIModel
import LKCommonsLogging
import SKFoundation

// MARK: - reverseGeocodeLocation Model
final class FormsReverseGeocodeLocationParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "latitude", validChecker: {
        -90.0 - $0 <= Double.ulpOfOne && $0 - 90.0 <= Double.ulpOfOne
    })
    var latitude: CLLocationDegrees
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "longitude", validChecker: {
        -180.0 - $0 <= Double.ulpOfOne && $0 - 180.0 <= Double.ulpOfOne
    })
    var longitude: CLLocationDegrees
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_latitude, _longitude]
    }
}

final class FormsReverseGeocodeLocationResult: OpenAPIBaseResult {
    
    var name: String
    
    var address: String
    
    var isInternal: Bool
    
    var addressComponent: AddressComponent?
    
    struct AddressComponent {
        
        var country: String         // 国家
        
        var province: String        // 省/直辖市
        
        var city: String            // 市
        
        var district: String        // 区
        
        var township: String        // 乡镇街道
        
        var neighborhood: String    // 社区
        
        var building: String        // 建筑
        
        var address: String         // 完整地址
    }
    
    init(
        name: String,
        address: String,
        isInternal: Bool,
        addressComponent: AddressComponent?
    ) {
        self.name = name
        self.address = address
        self.isInternal = isInternal
        self.addressComponent = addressComponent
    }
    
    override func toJSONDict() -> [AnyHashable : Any] {
        
        let addr: String
        // 优先取格式化地址
        if let addrComponent = addressComponent, !addrComponent.address.isEmpty {
            addr = addrComponent.address
        } else {
            addr = address
        }
        
        var baseAddr = [
            "name": name,
            "address": addr,
            "isInternal": isInternal
        ] as [String : Any]
        
        if let addressComponent = addressComponent {
            baseAddr["addressComponent"] = [
                "country": addressComponent.country,
                "province": addressComponent.province,
                "city": addressComponent.city,
                "district": addressComponent.district,
                "township": addressComponent.township,
                "neighborhood": addressComponent.neighborhood,
                "building": addressComponent.building,
                "address": addressComponent.address,
            ]
        }
        
        return baseAddr
    }
}

// MARK: - reverseGeocodeLocation
extension FormsLocation {
    
    func reverseGeocodeLocation(
        params: FormsReverseGeocodeLocationParams,
        success: @escaping (FormsReverseGeocodeLocationResult) -> Void,
        failure: @escaping (OpenAPIError) -> Void
    ) {
        FormPOITool()
            .searchReGeocode(
                center: CLLocationCoordinate2D(
                    latitude: params.latitude,
                    longitude: params.longitude
                ),
                reverseGeocodeLocationSuccessBlock: success,
                reverseGeocodeLocationFailureBlock: failure
            )
    }
    
}

final private class FormPOITool: SearchAPIDelegate {
    
    static let logger = Logger.formsSDKLog(FormPOITool.self, category: "FormPOITool")
    
    private lazy var poiSearchService: POISearchService = {
        let search = POISearchService(language: LanguageManager.currentLanguage)
        search.delegate = self
        return search
    }()
    
    private var reverseGeocodeLocationSuccessBlock: ((FormsReverseGeocodeLocationResult) -> Void)?
    
    private var reverseGeocodeLocationFailureBlock: ((OpenAPIError) -> Void)?
    
    private var retainSelf: FormPOITool?
    
    deinit {
        Self.logger.info("FormPOITool deinit")
    }
    
    func searchReGeocode(
        center: CLLocationCoordinate2D,
        reverseGeocodeLocationSuccessBlock: @escaping ((FormsReverseGeocodeLocationResult) -> Void),
        reverseGeocodeLocationFailureBlock: @escaping ((OpenAPIError) -> Void)
    ) {
        Self.logger.info("reverseGeocodeLocation start")
        
        retainSelf = self
        
        self.reverseGeocodeLocationSuccessBlock = reverseGeocodeLocationSuccessBlock
        self.reverseGeocodeLocationFailureBlock = reverseGeocodeLocationFailureBlock
        
        poiSearchService.searchReGeocode(center: center)
    }
    
    // 反解析结束
    func reGeocodeDone(data: UILocationData) {
        Self.logger.info("reverseGeocodeLocation success, isInternal: \(data.isInternal)")
        
        var component: FormsReverseGeocodeLocationResult.AddressComponent?
        if let addressComponent = data.addressComponent {
            component = .init(
                country: addressComponent.country,
                province: addressComponent.province,
                city: addressComponent.city,
                district: addressComponent.district,
                township: addressComponent.township,
                neighborhood: addressComponent.neighborhood,
                building: addressComponent.building,
                address: addressComponent.address
            )
        }
        
        let result = FormsReverseGeocodeLocationResult(
            name: data.name,
            address: data.address,
            isInternal: data.isInternal,
            addressComponent: component
        )
        
        if let reverseGeocodeLocationSuccessBlock = reverseGeocodeLocationSuccessBlock {
            reverseGeocodeLocationSuccessBlock(result)
        } else {
            Self.logger.info("reverseGeocodeLocation callback failure, reverseGeocodeLocationSuccessBlock is nil")
        }
        
        reverseGeocodeLocationSuccessBlock = nil
        reverseGeocodeLocationFailureBlock = nil
        
        retainSelf = nil
    }
    // 反解析错误
    func reGeocodeFailed(data: UILocationData, err: Error) {
        Self.logger.info("reverseGeocodeLocation failure", error: err)
        
        let e = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setError(err)
        if let nse = err as? NSError {
            e.setOuterCode(nse.code)
            e.setOuterMessage(e.description)
        }
        
        if let reverseGeocodeLocationFailureBlock = reverseGeocodeLocationFailureBlock {
            reverseGeocodeLocationFailureBlock(e)
        } else {
            Self.logger.info("reverseGeocodeLocation callback failure, reverseGeocodeLocationFailureBlock is nil")
        }
        
        reverseGeocodeLocationSuccessBlock = nil
        reverseGeocodeLocationFailureBlock = nil
        
        retainSelf = nil
    }
    
    // 下边的回调不在逆地址范围内，但是接口又不得不实现
    func searchFailed(err: Error) {}
    
    func searchInputTipDone(keyword: String, data: [(UILocationData, Bool)]) {}
    
    func searchDone(keyword: String?, data: [UILocationData], isFirstPage: Bool) {}
    
    func regionOutOfService(current: UILocationData) {}
    
}
