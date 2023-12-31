//
//  InternalPOISearch.swift
//  LarkLocationPicker
//
//  Created by 姚启灏 on 2020/5/18.
//

import UIKit
import Foundation
import LarkLocalizations
import RxSwift
import RxCocoa
import MapKit
import LKCommonsTracker
import Homeric
import AMapSearchKit
import LKCommonsLogging
import ThreadSafeDataStructure
import LarkSensitivityControl

public final class POISearchService: NSObject {
    private static let logger = Logger.log(POISearchService.self, category: "LocationPicker.POISearchService")

    private var appleSearchAPI: MKLocalSearch?
    private var gaodeSearchAPI: AMapSearchAPI?

    public weak var delegate: SearchAPIDelegate?
    public weak var poiDelegate: SearchPOIDelegate?
    public var allowCustomLocation: Bool = false
    private var coordSystem: CoordinateSystem = .origin
    private var isInputTips: Bool = false
    private let teaTracker: POISearchTracker = POISearchTracker()
    fileprivate var amapSerachPOI: Bool = false
    fileprivate var amapSearchReGeocode: Bool = false

    public init(language: Lang) {
        super.init()
        self.setupAmap(language: language)
    }

    private func setupAmap(language: Lang) {
        guard FeatureUtils.isAdminAllowAmap() else {
            Self.logger.info("not allow use aMap，not set up aMap")
            return
        }
        FeatureUtils.setAMapAPIKey()
        AMapSearchAPI.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        AMapSearchAPI.updatePrivacyAgree(.didAgree)
        self.gaodeSearchAPI = AMapSearchAPI()
        switch language {
        case .zh_CN:
            gaodeSearchAPI?.language = AMapSearchLanguageZhCN
        default:
            gaodeSearchAPI?.language = AMapSearchLanguageEn
        }
        gaodeSearchAPI?.delegate = self
    }

    @available(*, deprecated, message: "set coordinate system nonsupport，to be removed")
    public func setCoordinateSystem(system: CoordinateSystem) {
        coordSystem = system
        switch coordSystem {
        case .wgs84:
            POISearchService.logger.info("Set Coordinate System By wgs84")
        case .origin:
            POISearchService.logger.info("Set Coordinate System By origin")
        }
    }

    /// 校验地图类型，如果不允许使用高德SDK，默认使用系统服务
    private func checkMapType(_ mapType: MapType) -> MapType {
        guard FeatureUtils.isAdminAllowAmap() else {
            return .apple
        }
        return mapType
    }

    /// 校验是否可以使用高德SDK服务能力
    private func checkWhetherUseAmapService(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return FeatureUtils.AMapDataAvailableForCoordinate(coordinate)
    }

    private func checkString(by text: String?) -> String {
        guard let result = text else {
            return ""
        }
        return result
    }

    // *****************************
    // 关键字搜索
    // ******************************
    public func searchKeyword(center: CLLocationCoordinate2D, mapType: MapType, keyword: String, page: Int = 1) {
        switch checkMapType(mapType) {
        case .apple:
            POISearchService.logger.info("Search Keyword By Apple")
            searchByAppleMap(keyWord: keyword)
        case .amap:
            POISearchService.logger.info("Search Keyword By Amap")
            searchByGaodeMap(center: center, keyword: keyword, page: page)
        }
    }

    private func searchByAppleMap(keyWord: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = keyWord
        let localSearch = MKLocalSearch(request: request)
        appleSearchAPI?.cancel()
        appleSearchAPI = localSearch
        teaTracker.searchKeyword(mapType: .apple)
        localSearch.start { [weak self] (response, error) in
            if let response = response, let `self` = self {
                var dataItems = response.mapItems.map({ (mapItem) -> UILocationData in
                    return MKMapItemModel(mapItem: mapItem, system: self.coordSystem)
                })
                self.teaTracker.searchKeywordResult(mapType: .apple, count: dataItems.count, result: .success)
                if self.allowCustomLocation {
                    dataItems.insert(MKMapItemModel(name: keyWord), at: 0)
                }
                POISearchService.logger.info("Search Keyword Completion By Apple, count: \(dataItems.count)")
                self.delegate?.searchDone(keyword: keyWord, data: dataItems, isFirstPage: true)
            }
            if let err = error {
                POISearchService.logger.info("Search Keyword Error By Apple, error: \(err)")
                Tracker.post(TeaEvent(Homeric.LARK_MESSAGE_LOCATION_IOS_POI_ERROR, params: [:]))
                self?.teaTracker.searchAroundResult(mapType: .apple, count: 0, result: .fail, error: err)
                if self?.allowCustomLocation ?? false {
                    self?.delegate?.searchDone(keyword: keyWord,
                                               data: [MKMapItemModel(name: keyWord)],
                                               isFirstPage: true)
                } else {
                    self?.delegate?.searchFailed(err: err)
                }
            }
        }
    }

    private func searchByGaodeMap(center: CLLocationCoordinate2D, keyword: String, page: Int) {
        let request = AMapInputTipsSearchRequest()
        let newCoord = AMapCoordinateConvert(center, AMapCoordinateType.aMap)
        request.keywords = keyword
        request.location = "\(CGFloat(newCoord.longitude)),\(CGFloat(newCoord.latitude))"
        teaTracker.searchKeyword(mapType: .amap)
        gaodeSearchAPI?.aMapInputTipsSearch(request)
        POISearchService.logger.info("Search Keyword By Amap GaodeMap")
    }

    // *****************************
    // 搜索关键字提示
    // ******************************
    public func searchInputTip(center: CLLocationCoordinate2D, mapType: MapType, keyword: String) {
        isInputTips = true
        switch checkMapType(mapType) {
        case .apple:
            return
        case .amap:
            searchInputTipByGaodeMap(center: center, keyword: keyword)
        }
    }

    private func searchInputTipByGaodeMap(center: CLLocationCoordinate2D, keyword: String) {
        POISearchService.logger.info("Search Input Tip By Amap")
        isInputTips = true
        let request = AMapInputTipsSearchRequest()
        let newCoord = AMapCoordinateConvert(center, AMapCoordinateType.google)
        request.keywords = keyword
        request.location = "\(CGFloat(newCoord.longitude)),\(CGFloat(newCoord.latitude))"
        teaTracker.searchKeyword(mapType: .amap)
        gaodeSearchAPI?.aMapInputTipsSearch(request)
    }

    deinit {
        self.delegate = nil
        appleSearchAPI?.cancel()
        gaodeSearchAPI?.cancelAllRequests()
    }

    // *****************************
    // 搜索周边POI
    // ******************************
    public func searchPOI(center: CLLocationCoordinate2D, page: Int = 1) {
        amapSerachPOI = false
        if checkWhetherUseAmapService(center) {
            POISearchService.logger.info("Search POI By Amap")
            searchPOIByGaodeMap(center: center, page: page)
        } else {
            POISearchService.logger.info("Search POI By Apple")
            searchPOIByAppleMap(center: center, page: page)
        }
    }

    public func searchPOI(center: CLLocationCoordinate2D, 
                          radiusInMeters: Int,
                          pageSize: Int = LarkLocationPickerUtils.defaultPageOffset,
                          keywords: String? = nil) {
        amapSerachPOI = false
        if checkWhetherUseAmapService(center) {
            POISearchService.logger.info("Search POI By Amap")
            searchPOIByGaodeMap(center: center, pageSize: pageSize, radiusInMeters: radiusInMeters, keywords: keywords)
        } else {
            POISearchService.logger.info("Search POI By Apple")
            searchPOIByAppleMap(center: center, radiusInMeters: radiusInMeters, keywords: keywords)
        }
    }
    // nolint: duplicated_code - 非重复代码，国内国外隔离
    private func searchPOIByAppleMap(center: CLLocationCoordinate2D,
                                     page: Int = 1,
                                     radiusInMeters: Int = 1_000,
                                     keywords: String? = nil) {
        // AOP 范围信息
        let region = MKCoordinateRegion(center: center,
                                        latitudinalMeters: CLLocationDistance(radiusInMeters),
                                        longitudinalMeters: CLLocationDistance(radiusInMeters))
        let request = MKLocalSearch.Request()
        request.region = region
        if let keywords {
            request.naturalLanguageQuery = keywords
        } else {
            request.naturalLanguageQuery = "place"
        }
        let localSearch = MKLocalSearch(request: request)
        appleSearchAPI?.cancel()
        appleSearchAPI = localSearch
        teaTracker.searchAround(mapType: .apple)
        localSearch.start { [weak self] (response, error) in
            if let response = response, let `self` = self {
                POISearchService.logger.info("Search POI Success By Apple")
                let dataItems = response.mapItems.map({ (mapItem) -> UILocationData in
                    return MKMapItemModel(mapItem: mapItem, system: self.coordSystem)
                })
                self.teaTracker.searchAroundResult(mapType: .apple, count: dataItems.count, result: .success)
                if self.amapSerachPOI == true {
                    POISearchService.logger.info("Search POI Success By Apple,AmapSerachPOIComplete")
                    return
                }
                self.delegate?.searchDone(keyword: nil, data: dataItems, isFirstPage: true)
                self.poiDelegate?.searchPOIDone(data: dataItems)
            }
            if let err = error {
                POISearchService.logger.info("Search POI Error By Apple, error: \(err)")
                self?.teaTracker.searchAroundResult(mapType: .apple, count: 0, result: .fail, error: err)
                Tracker.post(TeaEvent(Homeric.LARK_MESSAGE_LOCATION_IOS_POI_ERROR, params: [:]))
                if self?.amapSerachPOI == true {
                    POISearchService.logger.info("Search POI Error By Apple, error: \(err),AmapSerachPOIComplete")
                    return
                }
                self?.delegate?.searchFailed(err: err)
                self?.poiDelegate?.searchFailed(err: err)
                print(String(describing: err))
            }
        }
    }

    private func searchPOIByGaodeMap(center: CLLocationCoordinate2D, 
                                     page: Int = 1,
                                     pageSize: Int = LarkLocationPickerUtils.defaultPageOffset,
                                     radiusInMeters: Int = 1_000,
                                     keywords: String? = nil) {
        if !checkWhetherUseAmapService(center) {
            self.delegate?.regionOutOfService(current: AMapItemModel(location: center, system: coordSystem))
            return
        }
        let request = AMapPOIAroundSearchRequest()
        request.location = AMapGeoPoint.location(
            withLatitude: CGFloat(center.latitude), longitude: CGFloat(center.longitude)
        )
        request.radius = radiusInMeters
        if let keywords {
            request.keywords = keywords
        }
        request.sortrule = 1
        request.page = page
        request.offset = pageSize
        request.requireExtension = true
        gaodeSearchAPI?.aMapPOIAroundSearch(request)
        teaTracker.searchAround(mapType: .amap)
    }

    // *****************************
    // 当前位置反解析
    // ******************************
    public func searchReGeocode(center: CLLocationCoordinate2D) {
        amapSearchReGeocode = false
        if checkWhetherUseAmapService(center) {
            searchReGeocodeByGaodeMap(center: center)
            POISearchService.logger.info("Search ReGeocode By Amap")
        } else {
           searchReGeocodeByAppleMap(center: center)
            POISearchService.logger.info("Search ReGeocode By Apple")
        }
    }

    private func searchReGeocodeByGaodeMap(center: CLLocationCoordinate2D) {
        let request = AMapReGeocodeSearchRequest()
        request.location = AMapGeoPoint.location(
            withLatitude: CGFloat(center.latitude), longitude: CGFloat(center.longitude)
        )
        request.requireExtension = true
        print("[LocationPicker] reGaode lat:\(center.latitude), lng: \(center.longitude)")
        gaodeSearchAPI?.aMapReGoecodeSearch(request)
    }

    // nolint: duplicated_code - 国内外文件隔离处理
    private func searchReGeocodeByAppleMap(center: CLLocationCoordinate2D, page: Int = 1) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
        /// 逆地址解析 PSDA管控Token
        let reverseGeocodeToken: Token = Token("LARK-PSDA-POISearch-reverseGeocodeLocation", type: .deviceInfo)
        do {
            try DeviceInfoEntry.reverseGeocodeLocation(forToken: reverseGeocodeToken, geocoder: geocoder, userLocation: location, completionHandler: { [weak self] (placemarks, error) in
                if let err = error {
                    POISearchService.logger.info("Search ReGeocode By AppleMap Error: \(err)")
                    Tracker.post(TeaEvent(Homeric.LARK_MESSAGE_LOCATION_IOS_POI_ERROR, params: [:]))
                    if self?.amapSearchReGeocode == true {
                        POISearchService.logger.info("Search ReGeocode By AppleMap Error: \(err),AmapReGeocodeComplete")
                        return
                    }
                    self?.delegate?.reGeocodeFailed(data:
                        MKMapItemModel(location: center, isInternal: false, system: self?.coordSystem ?? .origin), err: err
                    )
                } else if let placemark = placemarks?.first {
                    POISearchService.logger.info("Search ReGeocode By AppleMap Success")
                    if self?.amapSearchReGeocode == true {
                        POISearchService.logger.info("Search ReGeocode By AppleMap Success,AmapReGeocodeComplete")
                        return
                    }
                    let addressComponent = AddressComponent(country: placemark.country ?? "",
                                                            province: placemark.administrativeArea ?? "",
                                                            city: placemark.locality ?? "",
                                                            district: placemark.subLocality ?? "",
                                                            township: "",
                                                            neighborhood: "",
                                                            building: "",
                                                            address: placemark.formattedAddress ?? "", 
                                                            pois: nil,
                                                            aois: nil,
                                                            streetNumberInfo: nil)
                    if let name = placemark.name, let addr = placemark.thoroughfare {
                        let city = placemark.locality ?? placemark.subAdministrativeArea
                        let currentAddrName = ( name != addr && name != city ) ? name + " (" + addr + ")" : name
                        self?.delegate?.reGeocodeDone(data: MKMapItemModel(
                            name: currentAddrName,
                            addr: placemark.formattedAddress ?? "",
                            location: center,
                            isInternal: placemark.isoCountryCode == "CN",
                            system: self?.coordSystem ?? .origin,
                            addressComponent: addressComponent))
                    } else {
                        self?.delegate?.reGeocodeDone(data: MKMapItemModel(
                            location: center,
                            isInternal: placemark.isoCountryCode == "CN",
                            system: self?.coordSystem ?? .origin,
                            addressComponent: addressComponent))
                    }
                }
            })
        } catch let error {
            if let checkError = error as? CheckError {
                Self.logger.info("Search ReGeocode By AppleMap reverseGeocodeLocationForPSDA error \(checkError.description)")
            }
        }
    }

}

// MARK: - <#AMapSearchDelegate#>
extension POISearchService: AMapSearchDelegate {
    /* POI 搜索回调. */
    public func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        guard response != nil else {
            return
        }
        var dataItems = response.pois.map({ (mapItem) -> UILocationData in
            return AMapItemModel(poi: mapItem, system: self.coordSystem)
        })
        POISearchService.logger.info("Search POI Completion By AMap, count: \(dataItems.count)")
        amapSerachPOI = true
        if let keywordRequest = request as? AMapPOIKeywordsSearchRequest {
            POISearchService.logger.info("Search POI Completion By AMap, AMapPOIKeywordsSearchRequest")
            teaTracker.searchKeywordResult(mapType: .amap, count: dataItems.count, result: .success)
            if self.allowCustomLocation {
                dataItems.insert(MKMapItemModel(name: keywordRequest.keywords), at: 0)
            }
            if isInputTips {
                isInputTips = false
                self.delegate?.searchInputTipDone(keyword: keywordRequest.keywords, data: dataItems.map({ (data) -> (UILocationData, Bool) in
                    return (data, true)
                }))
            } else {
                self.delegate?.searchDone(keyword: keywordRequest.keywords, data: dataItems, isFirstPage: request.page == 1)
                self.poiDelegate?.searchPOIDone(data: dataItems)
            }
        } else {
            POISearchService.logger.info("Search POI Completion By AMap, AMapOtherRequest")
            teaTracker.searchAroundResult(mapType: .amap, count: dataItems.count, result: .success)
            self.delegate?.searchDone(keyword: nil, data: dataItems, isFirstPage: request.page == 1)
            self.poiDelegate?.searchPOIDone(data: dataItems)
        }
    }

    public func onReGeocodeSearchDone(_ request: AMapReGeocodeSearchRequest!, response: AMapReGeocodeSearchResponse!) {
        guard response != nil else {
            Self.logger.info("onReGeocodeSearchDone response is nil")
            return
        }
        guard response.regeocode != nil else {
            Self.logger.info("onReGeocodeSearchDone regeocode is nil")
            return
        }
        var name = ""
        var description = response.regeocode.addressComponent.township + response.regeocode.addressComponent.neighborhood
        var pois = [PoiItemInfo]()
        if response.regeocode.pois != nil, !response.regeocode.pois.isEmpty {
            pois = response.regeocode.pois.map {
                PoiItemInfo(poiId: checkString(by: $0.uid),
                            title: checkString(by: $0.name),
                            typeCode: checkString(by: $0.typecode),
                            typeDes: checkString(by: $0.type),
                            latitude: $0.location.latitude,
                            longitude: $0.location.longitude,
                            snippet: checkString(by: $0.address),
                            tel: checkString(by: $0.tel),
                            distance: $0.distance,
                            parkingType: checkString(by: $0.parkingType),
                            businessArea: checkString(by: $0.businessArea))
            }
        } else {
            Self.logger.info("onReGeocodeSearchDone pois is nil")
        }
        var aois = [AoiItemInfo]()
        if response.regeocode.aois != nil, !response.regeocode.aois.isEmpty {
            aois = response.regeocode.aois.map {
                AoiItemInfo(adCode: checkString(by: $0.adcode),
                            aoiArea: $0.area,
                            latitude: $0.location.latitude,
                            longitude: $0.location.longitude,
                            aioId: checkString(by: $0.uid),
                            aoiName: checkString(by: $0.name))
            }
        } else {
            Self.logger.info("onReGeocodeSearchDone aois is nil")
        }
        var streetNumberLatitude: Double = 0
        var streetNumberLongitude: Double = 0
        var streetNumberInfo = StreetNumberInfo(direction: "", distance: 0, latitude: streetNumberLatitude, longitude: streetNumberLongitude, number: "", street: "")
        if response.regeocode.addressComponent.streetNumber.location != nil {
            streetNumberLatitude = response.regeocode.addressComponent.streetNumber.location.latitude
            streetNumberLongitude = response.regeocode.addressComponent.streetNumber.location.longitude
        } else {
            Self.logger.info("onReGeocodeSearchDone streetNumber location is nil")
        }
        if response.regeocode.addressComponent.streetNumber != nil {
            streetNumberInfo = StreetNumberInfo(direction: checkString(by: response.regeocode.addressComponent.streetNumber.direction),
                                                    distance: response.regeocode.addressComponent.streetNumber.distance,
                                                    latitude: streetNumberLatitude,
                                                    longitude: streetNumberLongitude,
                                                    number: checkString(by: response.regeocode.addressComponent.streetNumber.number),
                                                    street: checkString(by: response.regeocode.addressComponent.streetNumber.street))
        } else {
            Self.logger.info("onReGeocodeSearchDone streetNumberInfo is nil")
        }
        let addressComponent = AddressComponent(country: response.regeocode.addressComponent.country,
                                                province: response.regeocode.addressComponent.province,
                                                city: response.regeocode.addressComponent.city,
                                                district: response.regeocode.addressComponent.district,
                                                township: response.regeocode.addressComponent.township,
                                                neighborhood: response.regeocode.addressComponent.neighborhood,
                                                building: response.regeocode.addressComponent.building,
                                                address: response.regeocode.formattedAddress,
                                                pois: pois,
                                                aois: aois,
                                                streetNumberInfo: streetNumberInfo)
        /*
         如果有建筑物信息则用建筑物信息，
         如果有poi信息，则用poi列表中的第一个，
         否则用API封装好的详细地址
        */
        if !response.regeocode.addressComponent.building.isEmpty {
            name = response.regeocode.addressComponent.building
        } else if !response.regeocode.pois.isEmpty && response.regeocode.formattedAddress.contains(response.regeocode.pois[0].name) {
            name = response.regeocode.pois[0].name
            description = response.regeocode.pois[0].address
        } else {
            name = response.regeocode.formattedAddress
        }
        POISearchService.logger.info("Search ReGeocode Completion By AMap")
        amapSearchReGeocode = true
        let aMapItemModel = AMapItemModel(
            name: name,
            addr: description,
            location: CLLocationCoordinate2D(
                latitude: CLLocationDegrees(request.location.latitude),
                longitude: CLLocationDegrees(request.location.longitude)
            ),
            system: self.coordSystem,
            addressComponent: addressComponent)
        self.delegate?.reGeocodeDone(data: aMapItemModel)
    }

    public func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        POISearchService.logger.info("Search Error By AMap, error: \(error)")
        if request is AMapPOIKeywordsSearchRequest || request is AMapPOIAroundSearchRequest {
            let scene = (request is AMapPOIKeywordsSearchRequest) ? POIScene.searchKeyword : POIScene.searchAround
            self.teaTracker.searchPOIResult(scene: scene, mapType: .amap, count: 0, result: .fail, error: error)
            self.delegate?.searchFailed(err: error)
            self.poiDelegate?.searchFailed(err: error)
        } else if let req = request as? AMapReGeocodeSearchRequest {
            let amapItemModel = AMapItemModel(
                location: CLLocationCoordinate2D(
                    latitude: CLLocationDegrees(req.location.latitude),
                    longitude: CLLocationDegrees(req.location.longitude)
            ), system: self.coordSystem)
            self.delegate?.reGeocodeFailed(data: amapItemModel, err: error)
        }
    }

    public func onInputTipsSearchDone(_ request: AMapInputTipsSearchRequest!, response: AMapInputTipsSearchResponse!) {
        guard response != nil else {
            return
        }
        // 1）uid为空，location为空，该提示语为品牌词，双端对齐过滤非POI信息的品牌词数据。
        // 2）uid不为空，location也不为空，是一个真实存在的POI，可直接显示在地图上。
        var dataItems = response.tips.filter({ (tip) -> Bool in
            return !tip.uid.isEmpty && tip.location != nil
        }).map({ (tip) -> (UILocationData, Bool) in
            return (AMapItemModel(tip: tip, system: self.coordSystem), (!tip.uid.isEmpty && tip.location != nil))
        })

        POISearchService.logger.info("Search Input Tips Completion By AMap, count: \(dataItems.count)")

        if self.allowCustomLocation {
            dataItems.insert((AMapItemModel(name: request.keywords), true), at: 0)
        }
        self.teaTracker.searchKeywordResult(mapType: .amap, count: dataItems.count, result: .success)
        self.delegate?.searchInputTipDone(keyword: request.keywords, data: dataItems)
    }
}
