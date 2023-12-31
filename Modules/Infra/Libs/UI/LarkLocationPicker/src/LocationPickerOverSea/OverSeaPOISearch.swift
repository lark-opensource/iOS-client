//
//  OverSeaPOISearch.swift
//  LarkLocationPicker
//
//  Created by 姚启灏 on 2020/5/18.
//

import Foundation
import MapKit
import LarkLocalizations
import RxSwift
import RxCocoa
import LKCommonsTracker
import Homeric
import LKCommonsLogging
import LarkSensitivityControl

public class POISearchService {
    private static let logger = Logger.log(POISearchService.self, category: "LocationPicker.POISearchService")
    private var appleSearchAPI: MKLocalSearch?

    public weak var delegate: SearchAPIDelegate?
    public weak var poiDelegate: SearchPOIDelegate?
    public var allowCustomLocation: Bool = false
    private var coordSystem: CoordinateSystem = .origin
    private var isInputTips: Bool = false
    private let teaTracker: POISearchTracker = POISearchTracker()
    fileprivate var serachPOIComplete: Bool = false
    fileprivate var searchReGeocodeComplete: Bool = false

    public init(language: Lang) { }

    public func setCoordinateSystem(system: CoordinateSystem) {
        coordSystem = system
    }

    // *****************************
    // 关键字搜索
    // ******************************
    public func searchKeyword(center: CLLocationCoordinate2D, mapType: MapType, keyword: String, page: Int = 1) {
        searchByAppleMap(keyWord: keyword)
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
                POISearchService.logger.info("Search Keyword Completion By Apple, count: \(dataItems.count)")

                if self.allowCustomLocation {
                    dataItems.insert(MKMapItemModel(name: keyWord), at: 0)
                }
                self.delegate?.searchDone(keyword: keyWord, data: dataItems, isFirstPage: true)
            }
            if let err = error {
                POISearchService.logger.info("Search Keyword Error By Apple, error: \(err)")
                self?.teaTracker.searchAroundResult(mapType: .apple, count: 0, result: .fail, error: err)
                Tracker.post(TeaEvent(Homeric.LARK_MESSAGE_LOCATION_IOS_POI_ERROR, params: [:]))
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

    // *****************************
    // 搜索关键字提示
    // ******************************
    public func searchInputTip(center: CLLocationCoordinate2D, mapType: MapType, keyword: String) {
        isInputTips = true
        return
    }

    deinit {
        self.delegate = nil
        appleSearchAPI?.cancel()
    }

    // *****************************
    // 搜索周边POI
    // ******************************
    public func searchPOI(center: CLLocationCoordinate2D, page: Int = 1) {
        searchPOIByAppleMap(center: center, page: page)
    }

    public func searchPOI(center: CLLocationCoordinate2D,
                          radiusInMeters: Int,
                          pageSize: Int = 24,
                          keywords: String? = nil) {
        searchPOIByAppleMap(center: center, radiusInMeters: radiusInMeters, keywords: keywords)
    }

    private func searchPOIByAppleMap(center: CLLocationCoordinate2D, page: Int = 1, radiusInMeters: Int = 1_000, keywords: String? = nil) {
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
                self.serachPOIComplete = true
                let dataItems = response.mapItems.map({ (mapItem) -> UILocationData in
                    return MKMapItemModel(mapItem: mapItem, system: self.coordSystem)
                })
                self.teaTracker.searchAroundResult(mapType: .apple, count: dataItems.count, result: .success)
                self.delegate?.searchDone(keyword: nil, data: dataItems, isFirstPage: true)
                self.poiDelegate?.searchPOIDone(data: dataItems)
            }
            if let err = error {
                POISearchService.logger.info("Search POI Error By Apple, error: \(err)")
                self?.teaTracker.searchAroundResult(mapType: .apple, count: 0, result: .fail, error: err)
                Tracker.post(TeaEvent(Homeric.LARK_MESSAGE_LOCATION_IOS_POI_ERROR, params: [:]))
                if self?.serachPOIComplete == true {
                    POISearchService.logger.info("Search POI Error By Apple, error: \(err),AppleSerachPOIComplete")
                    return
                }
                self?.delegate?.searchFailed(err: err)
                self?.poiDelegate?.searchFailed(err: err)
                print(String(describing: err))
            }
        }
    }

    // *****************************
    // 当前位置反解析
    // ******************************
    public func searchReGeocode(center: CLLocationCoordinate2D) {
        searchReGeocodeByAppleMap(center: center)
    }

    private func searchReGeocodeByAppleMap(center: CLLocationCoordinate2D, page: Int = 1) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
        /// 逆地址解析 PSDA管控Token
        let reverseGeocodeToken: Token = Token("LARK-PSDA-OverSeaPOISearch-reverseGeocodeLocation", type: .deviceInfo)
        do {
            try DeviceInfoEntry.reverseGeocodeLocation(forToken: reverseGeocodeToken, geocoder: geocoder, userLocation: location, completionHandler: { [weak self] (placemarks, error) in
                POISearchService.logger.info("Search ReGeocode By AppleMap For OverSea")
                if let err = error {
                    POISearchService.logger.info("Search ReGeocode By AppleMap Error: \(err)")
                    Tracker.post(TeaEvent(Homeric.LARK_MESSAGE_LOCATION_IOS_POI_ERROR, params: [:]))
                    if self?.searchReGeocodeComplete == true {
                        POISearchService.logger.info("Search ReGeocode By AppleMap Error: \(err),AppleReGeocodeComplete")
                        return
                    }
                    self?.delegate?.reGeocodeFailed(data:
                        MKMapItemModel(location: center,
                                       isInternal: false,
                                       system: self?.coordSystem ?? .origin),
                                       err: err
                    )
                } else if let placemark = placemarks?.first {
                    POISearchService.logger.info("Search ReGeocode By AppleMap Success")
                    self?.searchReGeocodeComplete = true
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
