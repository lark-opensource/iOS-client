//
//  BTFetchGeoLocationHelper.swift
//  SKBitable
//
//  Created by 曾浩泓 on 2022/5/29.
//  


import SKFoundation
import Contacts
import CoreLocation
#if canImport(AMapSearchKit)
import AMapSearchKit
#endif
import LarkContainer
import LarkCoreLocation
import SKResource
import LarkLocationPicker
import LarkLocalizations

protocol BTFetchGeoLoactionHelperDelegate: AnyObject {
    func updateFetchingLocations(fieldLocations: Set<BTFieldLocation>)
    func notifyFrontendDidFetchGeoLocation(forLocation location: BTFieldLocation, geoLocation: BTGeoLocationModel, isAutoLocate: Bool, callback: String)
}

protocol BTGeoLocationFetcher: AnyObject {
    func didClickAutoLocate(forField fieldLocation: BTFieldLocation, forToken token: String, inRecord: BTRecord?, authFailHandler: (LocationAuthorizationError?) -> Void)
    func didSelectLocation(forField fieldLocation: BTFieldLocation, inRecord: BTRecord?, geoLocation: ChooseLocation)
}
struct BTReGeocodeResult {
    var location: CLLocationCoordinate2D
    var country: String // 中国
    var pname: String // 广东省
    var cityname: String // 深圳市
    var adname: String // 南山区
    var name: String // 深圳湾创新科技中心
    var address: String// 科苑南路与高新南九道交叉口东南约160米
    var fullAddress: String// 广东省深圳市南山区科苑南路与高新南九道交叉口东南约160米
}

typealias ReGeocodeCompletion = (BTReGeocodeResult?) -> Void

final class BTFetchGeoLocationHelper {
    @InjectedSafeLazy static private var locationAuth: LocationAuthorization
    @InjectedSafeLazy static private var service: LocationService
    private var autoLocateTasks: [BTFieldLocation: SingleLocationTask] = [:]
    private var reGeocodeTasks: Set<BTFieldLocation> = []
    private let reGeocoder: BTReGeocoder
    var actionParams: BTActionParamsModel
    private(set) weak var delegate: BTFetchGeoLoactionHelperDelegate?
    init(actionParams: BTActionParamsModel, delegate: BTFetchGeoLoactionHelperDelegate?, reGeocoder: BTReGeocoder = BTLKReGeocoder()) {
        self.actionParams = actionParams
        self.delegate = delegate
        self.reGeocoder = reGeocoder
    }
    
     static func requestAuthIfNeed(forToken: String, completion: @escaping (LocationAuthorizationError?) -> Void) {
        let error = locationAuth.checkWhenInUseAuthorization()
        guard let error = error else {
            completion(nil)
            return
        }
        switch error {
        case .notDetermined:
            locationAuth.requestWhenInUseAuthorization(forToken: PSDAToken(forToken, type: .location)) { err in
                completion(err)
            }
        default:
            completion(error)
        }
    }

    private func getReGeocoder(type: LocationServiceType) -> BTReGeocoder {
        return reGeocoder
    }
}
extension BTFetchGeoLocationHelper: BTGeoLocationFetcher {
    func didClickAutoLocate(forField fieldLocation: BTFieldLocation, 
                            forToken token: String, 
                            inRecord: BTRecord?,
                             authFailHandler: (LocationAuthorizationError?) -> Void) {
        let timeout: TimeInterval
            timeout = 15 // SingleLocationRequest 系统首次回调可能都有 7-10s 设置太短的超时时间会导致本来能成功的定位失败
        let request = SingleLocationRequest(
            desiredAccuracy: kCLLocationAccuracyHundredMeters,
            desiredServiceType: nil, //sdk会根据情况选择高德或者苹果
            timeout: timeout,
            cacheTimeout: 5// 如果使用cache的话，允许的最长cache 时长
        )
        guard let task = implicitResolver?.resolve(SingleLocationTask.self, argument: request) else {
            return
        }
        task.locationCompleteCallback = {[weak self] _, result in
            guard let self = self else { return }
            switch result {
            case .success(let location):
                let coordinate = location.location.coordinate
                let reGeocoder = self.getReGeocoder(type: location.serviceType)

                reGeocoder.fetchLocationModel(coordinate: coordinate) { [weak self] result in
                    guard let self = self else { return }
                    if let result = result {
                        let model = self.createGeoLocationModel(chooseAddress: result.address, chooseName: result.name, reGeocodeResult: result)
                        self.delegate?.notifyFrontendDidFetchGeoLocation(forLocation: fieldLocation, geoLocation: model, isAutoLocate: true, callback: self.actionParams.callback)
                    } else if !UserScopeNoChangeFG.YY.bitableGeoLocationFixDisable {
                        let model = Self.createUnnamedGeoLocationModel(location: location.location)
                        self.delegate?.notifyFrontendDidFetchGeoLocation(forLocation: fieldLocation, geoLocation: model, isAutoLocate: true, callback: self.actionParams.callback)
                    }
                    self.autoLocateTasks[fieldLocation] = nil
                    self.notifyUpdateFetchingLocations()
                }
            case .failure(let error):
                DocsLogger.info("定位失败:\(error.localizedDescription)")
                self.autoLocateTasks[fieldLocation] = nil
                self.notifyUpdateFetchingLocations()
            }
        }
        do {
            let psdaToken = PSDAToken(token, type: .location)
            try task.resume(forToken: psdaToken)
            self.autoLocateTasks[fieldLocation] = task
            notifyUpdateFetchingLocations()
        } catch {
            authFailHandler(error as? LocationAuthorizationError)
            DocsLogger.info("autoLocate resume fail:\(error.localizedDescription)")
        }
    }
    
    func didSelectLocation(forField fieldLocation: BTFieldLocation, inRecord: BTRecord?, geoLocation: ChooseLocation) {
        self.reGeocodeTasks.insert(fieldLocation)
        notifyUpdateFetchingLocations()
        let reGeocoder = self.getReGeocoder(type: geoLocation.mapType == "gaode" ? .aMap : .apple)
        reGeocoder.fetchLocationModel(coordinate: geoLocation.location) { [weak self] result in
            guard let self = self else { return }
            if let result = result {
                let model = self.createGeoLocationModel(chooseAddress: geoLocation.address, chooseName: geoLocation.name, reGeocodeResult: result)
                self.delegate?.notifyFrontendDidFetchGeoLocation(forLocation: fieldLocation, geoLocation: model, isAutoLocate: false, callback: self.actionParams.callback)
            }
            self.reGeocodeTasks.remove(fieldLocation)
            self.notifyUpdateFetchingLocations()
        }
    }
    
    private func notifyUpdateFetchingLocations() {
        var fieldLocations = Set(self.autoLocateTasks.keys)
        fieldLocations.formUnion(self.reGeocodeTasks)
        self.delegate?.updateFetchingLocations(fieldLocations: fieldLocations)
    }

    private func createGeoLocationModel(chooseAddress: String, chooseName: String, reGeocodeResult: BTReGeocodeResult) -> BTGeoLocationModel {
        let provinceCityDistrict = [
            reGeocodeResult.pname,
            reGeocodeResult.cityname,
            reGeocodeResult.adname
        ]
            .removeDuplicate()
            .joined(separator: "")
        var chooseAddress = chooseAddress.filter { !$0.isWhitespace }
        if !reGeocodeResult.country.isEmpty,
            chooseAddress.hasPrefix(reGeocodeResult.country) {
            chooseAddress = String(chooseAddress.dropFirst(reGeocodeResult.country.count))
        }
        
        let address = provinceCityDistrict.contains(chooseAddress) || chooseAddress.contains(provinceCityDistrict) ? "" : chooseAddress
        let components = [
            reGeocodeResult.pname,
            reGeocodeResult.cityname,
            reGeocodeResult.adname,
            address
        ]
        let subfix = components
            .removeDuplicate()
            .joined(separator: "")
        
        let fullAddress: String
        if chooseName.isEmpty || provinceCityDistrict.contains(chooseName) {
            fullAddress = subfix
        } else if chooseName.hasPrefix(provinceCityDistrict) {
            fullAddress = chooseName
        } else {
            fullAddress = "\(chooseName)，\(subfix)"
        }
        var model = BTGeoLocationModel()
        model.location = (Double(reGeocodeResult.location.longitude), Double(reGeocodeResult.location.latitude))
        model.pname = reGeocodeResult.pname
        model.cityname = reGeocodeResult.cityname
        model.adname = reGeocodeResult.adname
        model.name = reGeocodeResult.name
        model.address = reGeocodeResult.address
        model.fullAddress = fullAddress
        return model
    }
    
    /// 部分位置无法成功逆地址，因此提供兜底的地址名字
    static func createUnnamedGeoLocationModel(location: CLLocation) -> BTGeoLocationModel {
        var model = BTGeoLocationModel()
        model.location = (Double(location.coordinate.longitude), Double(location.coordinate.latitude))
        model.pname = ""
        model.cityname = ""
        model.adname = ""
        model.name = BundleI18n.SKResource.Bitable_Location_UnknownLocation_Desc
        model.address = BundleI18n.SKResource.Bitable_Location_UnknownLocation_Desc
        model.fullAddress = BundleI18n.SKResource.Bitable_Location_UnknownLocation_Desc
        return model
    }
    
    private func appendIfNeed(component: String?, to fullAddress: inout String, notExistIn components: [String]) {
        guard let component = component, !component.isEmpty else {
            return
        }
        let isExist = components.contains(where: { $0.contains(component) })
        guard !isExist else {
            return
        }
        fullAddress.append(component)
    }
}

extension Array where Element: Equatable {
    func removeDuplicate() -> Array {
        return self.enumerated().filter { (index, value) in
            return self.firstIndex(of: value) == index
        }
        .map({ (_, component) in component })
    }
}

protocol BTReGeocoder {
    func fetchLocationModel(coordinate: CLLocationCoordinate2D, completion: @escaping ReGeocodeCompletion)
}

final class BTLKReGeocoder: BTReGeocoder {
    private let service = POISearchService(language: LanguageManager.currentLanguage)
    private var tasks: [String: [ReGeocodeCompletion]] = [:]
    
    init() {
        service.delegate = self
    }
    
    func fetchLocationModel(coordinate: CLLocationCoordinate2D, completion: @escaping ReGeocodeCompletion) {
        let key = key(with: coordinate)
        var completions = tasks[key] ?? []
        completions.append(completion)
        tasks[key] = completions
        service.searchReGeocode(center: coordinate)
    }
    private func key(with coordinate: CLLocationCoordinate2D) -> String {
        return "\(coordinate.latitude),\(coordinate.longitude)"
    }
}
extension BTLKReGeocoder: SearchAPIDelegate {
    func searchFailed(err: Error) {}
    func searchInputTipDone(keyword: String, data: [(UILocationData, Bool)]) {}
    func searchDone(keyword: String?, data: [UILocationData], isFirstPage: Bool) {}
    func regionOutOfService(current: UILocationData) {}
    
    func reGeocodeDone(data: UILocationData) {
        let key = key(with: data.location)
        guard let completions = tasks[key] else { return }
        let model = BTReGeocodeResult(
            location: data.location,
            country: data.addressComponent?.country ?? "",
            pname: data.addressComponent?.province ?? "",
            cityname: data.addressComponent?.city ?? "",
            adname: data.addressComponent?.district ?? "",
            name: data.name,
            address: data.address,
            fullAddress: data.addressComponent?.address ?? ""
        )
        completions.forEach { completion in
            completion(model)
        }
        tasks[key] = nil
    }
    
    func reGeocodeFailed(data: UILocationData, err: Error) {
        DocsLogger.error("reGeocode failed", error: err)
        let key = key(with: data.location)
        guard let completions = tasks[key] else { return }
        completions.forEach { completion in
            completion(nil)
        }
        tasks[key] = nil
    }
}
