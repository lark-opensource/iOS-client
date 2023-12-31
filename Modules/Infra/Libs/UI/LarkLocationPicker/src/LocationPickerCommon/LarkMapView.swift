//
//  LarkMapView.swift
//  LarkLocationPicker
//
//  Created by aslan on 2022/2/23.
//

import Foundation
import UIKit
import MapKit
import RxCocoa
import SwiftUI
import UniverseDesignTheme
import LarkLocalizations
import LKCommonsLogging
import LarkSensitivityControl

#if canImport(MAMapKit)
import MAMapKit
typealias LarkMapViewAdapterDelegate = (LarkMAMapViewDelegate & LarkMKMapViewDelegate)
#endif

public struct LarkAnnotion {
    var title: String?
    var subTitle: String?
    var coordinate: CLLocationCoordinate2D

    public init(coordinate: CLLocationCoordinate2D, title: String?, subTitle: String?) {
        self.coordinate = coordinate
        self.title
        self.subTitle
    }
}

public protocol LarkMapViewDelegate: AnyObject {
    func mapViewWillStartLocatingUser(_ mapView: LarkMapView)
    func mapView(_ mapView: LarkMapView, failedLocate error: Error)
    func mapView(_ mapView: LarkMapView, didUpdate userLocation: MKMapItemModel, updatingLocation: Bool)
    func mapView(_ mapView: LarkMapView, regionDidChangeAnimated animated: Bool)
    func mkMapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    func mkMapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView])
    func mkMapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool)
#if canImport(MAMapKit)
    func maMapView(_ mapView: MAMapView, viewFor annotation: MAAnnotation) -> MAAnnotationView?
    func maMapView(_ mapView: MAMapView, didAdd views: [MAAnnotationView])
    func maMapView(_ mapView: MAMapView, didChange mode: MAUserTrackingMode, animated: Bool)
#endif
}

extension LarkMapViewDelegate {
    func mapView(_ mapView: LarkMapView, failedLocate error: Error) {}
}

public final class LarkMapView: UIView {
    public weak var delegate: LarkMapViewDelegate?

    private var mapView: MapViewAdapter
    private var centerPinImage: UIImage?

    public var vendor: BehaviorRelay<MapType> = BehaviorRelay<MapType>(value: .amap)
    private static let logger = Logger.log(LarkMapView.self, category: "LocationPicker.LarkMapView")
    /// 逆地址解析 PSDA管控Token
    private let reverseGeocodeToken: Token = Token("LARK-PSDA-LarkMapView-reverseGeocodeLocation", type: .deviceInfo)
    public init(frame: CGRect, centerPinImage: UIImage? = nil) {
        self.centerPinImage = centerPinImage
        let language = LanguageManager.currentLanguage
#if canImport(MAMapKit)
        mapView = LarkMAMapView(centerPinImage: centerPinImage, language: language)
#else
        mapView = LarkMKMapView(centerPinImage: centerPinImage)
#endif
        super.init(frame: frame)
        addSubview(mapView)
        mapView.delegate = self
        mapView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var userTrackingMode: LarkUserTrackingMode {
        set { mapView.userTrackingMode = newValue }
        get { mapView.userTrackingMode }
    }

    public func setUserTrackingMode(_ mode: LarkUserTrackingMode, animated: Bool) {
        mapView.setUserTrackingMode(mode, animated: animated)
    }

    public var userLocation: MKMapItemModel {
        get { mapView.userLocation }
    }

    public var distanceFilter: CLLocationDistance {
        set { mapView.distanceFilter = newValue }
        get { mapView.distanceFilter }
    }

    public var showsCompass: Bool {
        set { mapView.showsCompass = newValue }
        get { mapView.showsCompass }
    }

    public var showsScale: Bool {
        get { mapView.showsScale }
        set { mapView.showsScale = newValue }
    }

    public var showsUserLocation: Bool {
        get { mapView.showsUserLocation }
        set { mapView.showsUserLocation = newValue }
    }

    public var centerCoordinate: CLLocationCoordinate2D {
        get { mapView.centerCoordinate }
        set { mapView.centerCoordinate = newValue }
    }

    public func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool) {
        mapView.setCenter(coordinate, animated: animated)
    }

    public func removeAllannotion() {
        mapView.removeAllannotion()
    }

    public func addAnnotation(annotation: LarkAnnotion) {
        mapView.addAnnotation(annotation: annotation)
    }

    func getVendorDriver() -> Driver<MapType> {
        return getMapDataSource()
    }

    func getMapType() -> MapType {
        return mapView.getMapType()
    }

    private func getScreenShotOption(coords: CLLocationCoordinate2D, size: CGSize) -> MKMapSnapshotter.Options {
        let option = MKMapSnapshotter.Options()
        if #available(iOS 13.0, *) {
            option.traitCollection = self.traitCollection
        }
        let span = MKCoordinateSpan(
            latitudeDelta: 0,
            longitudeDelta: 360 / pow(2, self.getZoomLevel()) * Double(self.frame.size.width) / 256
        )
        option.region = MKCoordinateRegion(center: coords, span: span)
        option.scale = UIScreen.main.scale
        option.size = size
        option.showsBuildings = true
        option.showsPointsOfInterest = true
        return option
    }

    // swiftlint:disable
    func doScreenShot(
        size: CGSize = UIScreen.main.bounds.size,
        screenShotHandler: @escaping (UIImage?) -> Void
        ) {
        let centerCoor = self.centerCoordinate
        let screenShotOption = getScreenShotOption(coords: centerCoor, size: size)
        let bgQueue = DispatchQueue.main
        let snapShotter = MKMapSnapshotter(options: screenShotOption)

        snapShotter.start(with: bgQueue, completionHandler: { [weak self] (snapshot, error) in
            guard let `self` = self else {
                return screenShotHandler(nil)
            }
            guard error == nil else {
                let screenShotImage = self.screenShot(size: size)
                screenShotHandler(screenShotImage)
                return
            }
            if let snapShotImage = snapshot?.image,
                let coordinatePoint = snapshot?.point(for: centerCoor),
                let pinImage = self.mapView.centerPinImage {
                UIGraphicsBeginImageContextWithOptions(size, true, snapShotImage.scale)
                snapShotImage.draw(at: CGPoint.zero)
                let fixedPinPoint = CGPoint(
                    x: coordinatePoint.x - pinImage.size.width / 2,
                    y: coordinatePoint.y - pinImage.size.height / 2
                )
                pinImage.draw(at: fixedPinPoint)
                let mapImage = UIGraphicsGetImageFromCurrentImageContext()
                guard mapImage != nil else {
                    return
                }
                screenShotHandler(mapImage)
                UIGraphicsEndImageContext()
            }
        })
    }

    // 降级方案，自己做截图
    func screenShot(size: CGSize) -> UIImage? {
        var imageSize: CGSize = .zero
        imageSize.height = size.height > frame.size.height ? frame.size.height : size.height
        imageSize.width = size.width > frame.size.width ? frame.size.width : size.width
        UIGraphicsBeginImageContextWithOptions(imageSize, true, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        let fixedPoint = CGPoint(
            x: (mapView.centerPinImageView?.center.x ?? self.center.x) - imageSize.width / 2,
            y: (mapView.centerPinImageView?.center.y ?? self.center.y) - imageSize.height / 2
        )
        context.saveGState()
        context.translateBy(x: -fixedPoint.x, y: -fixedPoint.y)
        guard let newContext = UIGraphicsGetCurrentContext() else {
            return nil
        }
        self.layer.render(in: newContext)
        context.restoreGState()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    public func setZoomLevel(zoom: Double, center: CLLocationCoordinate2D, animated: Bool = true) {
        mapView.setZoomLevel(zoom: zoom, center: center, animated: animated)
    }

    /// 当地图zoom设置比14.5小的时候默认为14.5
    func getZoomLevel() -> Double {
        let zoom = log2(360 * (Double(self.frame.size.width / 256)
                               / mapView.region.span.longitudeDelta))
        return zoom < MapConsts.defaultZoomLevel ? MapConsts.defaultZoomLevel : zoom
    }

    func centerAnnotationAnimimate(bounceHeight: CGFloat, duration: Double) {
        guard let centerAnnotationView = mapView.centerPinImageView else {
            return
        }
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {() -> Void in
            var center = centerAnnotationView.center
            center.y -= bounceHeight
            centerAnnotationView.center = center
        }, completion: { _ in })
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn, animations: {() -> Void in
            var center = centerAnnotationView.center
            center.y += bounceHeight
            centerAnnotationView.center = center
        }, completion: { _ in })
    }

    public func lookUpCurrentLocation(
        userLocation: CLLocation?,
        completionHandler: @escaping CLGeocodeCompletionHandler) {
        reverseGeocodeLocationForPSDA(userLocation: userLocation, completionHandler: completionHandler)
    }

    func reverseGeocodeLocationForPSDA(
        userLocation: CLLocation?,
        completionHandler: @escaping CLGeocodeCompletionHandler) {
            if let location = userLocation {
                let geocoder = CLGeocoder()
                do {
                    try DeviceInfoEntry.reverseGeocodeLocation(forToken: reverseGeocodeToken, geocoder: geocoder, userLocation: location, completionHandler: { (placemarks, error) in
                        if let reverseGeocodeError = error {
                            Self.logger.info("lookUpCurrentLocation reverseGeocodeLocation error \(reverseGeocodeError)")
                        } else {
                            Self.logger.info("lookUpCurrentLocation reverseGeocodeLocation success")
                        }
                        completionHandler(placemarks, error)
                    })
                } catch let error {
                    if let checkError = error as? CheckError {
                        Self.logger.info("lookUpCurrentLocation reverseGeocodeLocationForPSDA error \(checkError.description)")
                    }
                }
            }
    }

    func getUserLocation() -> CLLocationCoordinate2D {
        return mapView.userLocation.location
    }

    /*
     暂时的解法，为了解决苹果数据源加载错误导致坐标偏移的问题。
     苹果地图在国内默认会用高德的服务，但有时会错误加载TomTom的地图服务导致坐标系不准，定位偏移

     MKMapView的View Hiearchy如下
     <_MKMapContentView>    地图内容
     -----
     <UIImageView>          高德地图Logo
     -----
     <MKAttributionLabel>   服务条款Label
     -----
     <UIImageView>          中心点的PIN
     -----

     当接入TomTom地图服务时，高德地图Logo所在的imageView不会被添加在subview中，因此可以用这个view是否存在来判断服务数据来源
     */
    public func getMapDataSource() -> Driver<MapType> {
        vendor.accept(mapView.getMapDataSource())
        return vendor.asDriver()
    }

    static let MapViewTag = 10002
    public func switchMapToMKMapView() {
        #if canImport(MAMapKit)
        if let view = self.viewWithTag(LarkMapView.MapViewTag) {
            // has add MapView
            return
        }
        var previousMapView = mapView
        mapView = LarkMKMapView(centerPinImage: self.centerPinImage)
        mapView.tag = LarkMapView.MapViewTag
        addSubview(mapView)
        sendSubviewToBack(mapView)
        mapView.delegate = self
        mapView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        self.synPropertyForMKMap(previousMap: previousMapView)
        previousMapView.delegate = nil
        previousMapView.removeFromSuperview()
        #endif
    }
}

extension LarkMapView: LarkMKMapViewDelegate {

    func mkMapView(_ mapView: MKMapView, failedLocate error: Error) {
        delegate?.mapView(self, failedLocate: error)
    }

    func mkMapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation, updatingLocation: Bool) {
        let isInternal = self.mapView.getMapDataSource() == .amap
        var location = MKMapItemModel(location: userLocation.coordinate, isInternal: isInternal, system: .origin)
        location.name = userLocation.title ?? ""
        location.address = userLocation.subtitle ?? ""
        delegate?.mapView(self, didUpdate: location, updatingLocation: updatingLocation)
    }

    public func mkMapViewWillStartLocatingUser(_ mapView: MKMapView) {
        delegate?.mapViewWillStartLocatingUser(self)
    }

    public func mkMapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        delegate?.mapView(self, regionDidChangeAnimated: animated)
    }

    public func mkMapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        delegate?.mkMapView(mapView, viewFor: annotation)
    }

    public func mkMapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        delegate?.mkMapView(mapView, didChange: mode, animated: animated)
    }

    public func mkMapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        delegate?.mkMapView(mapView, didAdd: views)
    }
}

#if canImport(MAMapKit)
extension LarkMapView: LarkMAMapViewDelegate {

    private func synPropertyForMKMap(previousMap: MapViewAdapter) {
        mapView.showsScale = previousMap.showsScale
        mapView.showsCompass = previousMap.showsCompass
        mapView.showsUserLocation = previousMap.showsUserLocation
    }

    func maMapView(_ mapView: MAMapView, failedLocate error: Error) {
        delegate?.mapView(self, failedLocate: error)
    }

    func maMapView(_ mapView: MAMapView, didUpdate userLocation: MAUserLocation, updatingLocation: Bool) {
        if userLocation.coordinate.latitude == 0.0 && userLocation.coordinate.longitude == 0.0 {
            // permission deny, did not locate location
            return
        }

        if !FeatureUtils.AMapDataAvailableForCoordinate(userLocation.coordinate) {
            switchMapToMKMapView()
            return
        }

        var location = MKMapItemModel(location: userLocation.coordinate, isInternal: false, system: .origin)
        location.name = userLocation.title
        location.address = userLocation.subtitle ?? ""
        delegate?.mapView(self, didUpdate: location, updatingLocation: updatingLocation)
    }

    public func maMapViewWillStartLocatingUser(_ mapView: MAMapView) {
        delegate?.mapViewWillStartLocatingUser(self)
    }

    public func maMapView(_ mapView: MAMapView, regionDidChangeAnimated animated: Bool) {
        delegate?.mapView(self, regionDidChangeAnimated: animated)
    }

    public func maMapView(_ mapView: MAMapView, viewFor annotation: MAAnnotation) -> MAAnnotationView? {
        delegate?.maMapView(mapView, viewFor: annotation)
    }

    public func maMapView(_ mapView: MAMapView, didChange mode: MAUserTrackingMode, animated: Bool) {
        delegate?.maMapView(mapView, didChange: mode, animated: animated)
    }

    public func maMapView(_ mapView: MAMapView, didAdd views: [MAAnnotationView]) {
        delegate?.maMapView(mapView, didAdd: views)
    }
}
#endif
