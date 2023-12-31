//
//  LarkMKMapView.swift
//  LarkLocationPicker
//
//  Created by aslan on 2022/2/23.
//

import UIKit
import Foundation
import MapKit
import RxCocoa
import SnapKit
import CoreLocation
import LKCommonsLogging

protocol LarkMKMapViewDelegate: AnyObject {
    func mkMapViewWillStartLocatingUser(_ mapView: MKMapView)
    func mkMapView(_ mapView: MKMapView, failedLocate error: Error)
    func mkMapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation, updatingLocation: Bool)
    func mkMapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    func mkMapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    func mkMapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView])
    func mkMapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool)
}

public final class LarkMKMapView: UIView, MapViewAdapter {
    #if canImport(MAMapKit)
    weak var delegate: LarkMapViewAdapterDelegate?
    #else
    weak var delegate: LarkMKMapViewDelegate?
    #endif
    private var didUpdateLocation: Bool = false
    public var userTrackingMode: LarkUserTrackingMode {
        set {
            let mkMode = convertLarkTrackingModeToMKTrackingMode(newValue)
            mapView.userTrackingMode = mkMode
        }
        get {
            return convertMKTrackingModeToLarkTrackingMode(mapView.userTrackingMode)
        }
    }

    func setUserTrackingMode(_ mode: LarkUserTrackingMode, animated: Bool) {
        let mkMode = convertLarkTrackingModeToMKTrackingMode(mode)
        mapView.setUserTrackingMode(mkMode, animated: animated)
    }

    private func convertLarkTrackingModeToMKTrackingMode(_ mode: LarkUserTrackingMode) -> MKUserTrackingMode {
        switch mode {
        case .none:
            return .none
        case .follow:
            return .follow
        case .followWithHeading:
            return .followWithHeading
        }
    }

    private func convertMKTrackingModeToLarkTrackingMode(_ mode: MKUserTrackingMode) -> LarkUserTrackingMode {
        switch mode {
        case .none:
            return .none
        case .follow:
            return .follow
        case .followWithHeading:
            return .followWithHeading
        }
    }

    private var _centerPinImage: UIImage?
    private var _distanceFilter: CLLocationDistance?
    public var centerPinImage: UIImage? {
        get { _centerPinImage }
        set { _centerPinImage = newValue }
    }

    private var _centerPinImageView: UIImageView?
    public var centerPinImageView: UIImageView? {
        get { _centerPinImageView }
        set { _centerPinImageView = newValue }
    }

    public var distanceFilter: CLLocationDistance {
        set { _distanceFilter = newValue }
        get { _distanceFilter ?? 0 }
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

    public var region: LarkCoordinateRegion {
        get {
            let mapViewSpan = mapView.region.span
            let span = LarkCoordinateSpan(latitudeDelta: mapViewSpan.latitudeDelta, longitudeDelta: mapViewSpan.longitudeDelta)
            return LarkCoordinateRegion(center: mapView.region.center, span: span)
        }
    }

    func setRegion(region: LarkCoordinateRegion, animated: Bool) {
        let span = MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta, longitudeDelta: region.span.longitudeDelta)
        let region = MKCoordinateRegion(center: region.center, span: span)
        if checkRegionTheLegality(mkRegion: region) {
            mapView.setRegion(region, animated: animated)
        } else {
            Self.logger.error("setRegion Invilid region center")
        }
    }

    func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool) {
        mapView.setCenter(coordinate, animated: animated)
    }

    func setZoomLevel(zoom: Double, center: CLLocationCoordinate2D, animated: Bool = true) {
        if self.frame.size.width > 0 {
            let span = MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 360 / pow(2, zoom) * Double(self.frame.size.width) / 256)
            let mkRegion = MKCoordinateRegion(center: center, span: span)
            if checkRegionTheLegality(mkRegion: mkRegion) {
                mapView.setRegion(mkRegion, animated: animated)
            } else {
                Self.logger.error("setZoomLevel Invilid region center width greater than zero")
            }
        } else {
            let span = MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: MapConsts.deltaLongitude)
            let mkRegion = MKCoordinateRegion(center: center, span: span)
            if checkRegionTheLegality(mkRegion: mkRegion) {
                mapView.setRegion(mkRegion, animated: animated)
            } else {
                Self.logger.error("setZoomLevel Invilid region center width less than or equal zero")
            }
        }
    }

    func checkRegionTheLegality(mkRegion: MKCoordinateRegion) -> Bool {
        if (mkRegion.center.latitude >= -90 && mkRegion.center.latitude <= 90) && (mkRegion.center.longitude >= -180 && mkRegion.center.longitude <= 180) {
            return true
        }
        return false
    }

    public var userLocation: MKMapItemModel {
        get {
            let userLocation = mapView.userLocation
            return MKMapItemModel(name: userLocation.title ?? "",
                                  addr: userLocation.subtitle ?? "",
                                  location: userLocation.coordinate,
                                  isInternal: false,
                                  isSelected: false,
                                  system: .wgs84)
        }
    }

    public func addAnnotation(annotation: LarkAnnotion) {
        let annotationPin = MKPointAnnotation()
        annotationPin.title = annotation.title
        annotationPin.subtitle = annotation.subTitle
        annotationPin.coordinate = annotation.coordinate
        mapView.addAnnotation(annotationPin)
    }

    public func removeAllannotion() {
        mapView.removeAnnotations(mapView.annotations)
    }

    func getMapDataSource() -> MapType {
        for view in mapView.subviews {
            guard let img = view as? UIImageView else {
                continue
            }
            // 高德地图Logo所在的imageView
            if img.frame.size.width == 45.5, img.frame.size.height == 10.5, img.autoresizingMask == [.flexibleLeftMargin, .flexibleTopMargin] {
                Self.logger.info("getMapDataSource Amap")
                return .amap
            }
        }
        Self.logger.info("getMapDataSource Apple")
        return .apple
    }

    func getMapType() -> MapType {
        return .apple
    }

    private static let logger = Logger.log(LarkMKMapView.self, category: "LocationPicker.LarkMKMapView")

    public var vendor: BehaviorRelay<MapType> = BehaviorRelay<MapType>(value: .apple)

    let mapView: MKMapView

    public init(centerPinImage: UIImage?) {
        self.mapView = MKMapView(frame: .zero)
        super.init(frame: .zero)
        self.centerPinImage = centerPinImage
        self.mapView.delegate = self
        self.addSubview(self.mapView)
        self.mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if let centerImage = centerPinImage {
            let pin = UIImageView(image: centerImage)
            self.mapView.addSubview(pin)
            pin.isUserInteractionEnabled = false
            pin.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(-centerImage.size.height / 2)
            }
            self.centerPinImageView = pin
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LarkMKMapView: MKMapViewDelegate {

    public func mapViewWillStartLocatingUser(_ mapView: MKMapView) {
        delegate?.mkMapViewWillStartLocatingUser(mapView)
    }

    public func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
        Self.logger.info("didFailToLocateUserWithError By Apple error: \(error)")
        delegate?.mkMapView(mapView, failedLocate: error)
    }

    public func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let isNegativeLatitude = (userLocation.location?.coordinate.latitude ?? 0) <= 0
        let isNegativeLongitude = (userLocation.location?.coordinate.longitude ?? 0) <= 0
        Self.logger.info("didUpdate By Apple\(isNegativeLatitude),\(isNegativeLongitude)")
        didUpdateLocation = true
        delegate?.mkMapView(mapView, didUpdate: userLocation, updatingLocation: userLocation.isUpdating)
    }

    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let isNegativeLatitude = self.mapView.centerCoordinate.latitude <= 0
        let isNegativeLongitude = self.mapView.centerCoordinate.longitude <= 0
        Self.logger.info("regionDidChangeAnimated By Apple\(isNegativeLatitude),\(isNegativeLongitude)")
        if didUpdateLocation {
            /// 解决苹果地图前两次会回调错误位置
            Self.logger.info("regionDidChangeAnimated Location By Apple")
            delegate?.mkMapView(mapView, regionDidChangeAnimated: animated)
        }
    }

    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return delegate?.mkMapView(mapView, viewFor: annotation)
    }

    public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        delegate?.mkMapView(mapView, didAdd: views)
    }

    public func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        delegate?.mkMapView(mapView, didChange: mode, animated: animated)
    }
}
