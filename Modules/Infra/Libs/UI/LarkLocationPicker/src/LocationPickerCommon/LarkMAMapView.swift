//
//  LarkMAMapView.swift
//  LarkLocationPicker
//
//  Created by aslan on 2022/2/23.
//

import UIKit
#if canImport(MAMapKit)
import Foundation
import MAMapKit
import SnapKit
import RxCocoa
import CoreLocation
import LKCommonsLogging
import LarkLocalizations

protocol LarkMAMapViewDelegate: AnyObject {
    func maMapViewWillStartLocatingUser(_ mapView: MAMapView)
    func maMapView(_ mapView: MAMapView, failedLocate error: Error)
    func maMapView(_ mapView: MAMapView, didUpdate userLocation: MAUserLocation, updatingLocation: Bool)
    func maMapView(_ mapView: MAMapView, regionDidChangeAnimated animated: Bool)
    func maMapView(_ mapView: MAMapView, viewFor annotation: MAAnnotation) -> MAAnnotationView?
    func maMapView(_ mapView: MAMapView, didAdd views: [MAAnnotationView])
    func maMapView(_ mapView: MAMapView, didChange mode: MAUserTrackingMode, animated: Bool)
}

public class LarkMAMapView: UIView, MapViewAdapter {
    weak var delegate: (LarkMAMapViewDelegate & LarkMKMapViewDelegate)?

    public var userTrackingMode: LarkUserTrackingMode {
        set {
            let maMode = convertLarkTrackingModeToMATrackingMode(newValue)
            mapView.userTrackingMode = maMode
        }
        get {
            return convertMATrackingModeToLarkTrackingMode(mapView.userTrackingMode)
        }
    }

    func setUserTrackingMode(_ mode: LarkUserTrackingMode, animated: Bool) {
        let maMode = convertLarkTrackingModeToMATrackingMode(mode)
        mapView.setUserTrackingMode(maMode, animated: animated)
    }

    private func convertLarkTrackingModeToMATrackingMode(_ mode: LarkUserTrackingMode) -> MAUserTrackingMode {
        switch mode {
        case .none:
            return .none
        case .follow:
            return .follow
        case .followWithHeading:
            return .followWithHeading
        }
    }

    private func convertMATrackingModeToLarkTrackingMode(_ mode: MAUserTrackingMode) -> LarkUserTrackingMode {
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
    public var centerPinImage: UIImage? {
        get { _centerPinImage }
        set { _centerPinImage = newValue }
    }

    private var _centerPinImageView: UIImageView?
    public var centerPinImageView: UIImageView? {
        get { _centerPinImageView }
        set { _centerPinImageView = newValue }
    }

    /// 定位的最小更新距离
    public var distanceFilter: CLLocationDistance {
        set { mapView.distanceFilter = newValue }
        get { mapView.distanceFilter }
    }

    /// 是否显示指南针
    public var showsCompass: Bool {
        set { mapView.showsCompass = newValue }
        get { mapView.showsCompass }
    }

    /// 是否显示比例尺
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

    public var userLocation: MKMapItemModel {
        get {
            let userLocation = mapView.userLocation ?? MAUserLocation()
            return MKMapItemModel(name: "",
                                  addr: "",
                                  location: userLocation.coordinate,
                                  isInternal: false,
                                  isSelected: false,
                                  system: .wgs84)
        }
    }

    public var region: LarkCoordinateRegion {
        get {
            let mapViewSpan = mapView.region.span
            let span = LarkCoordinateSpan(latitudeDelta: mapViewSpan.latitudeDelta, longitudeDelta: mapViewSpan.longitudeDelta)
            return LarkCoordinateRegion(center: mapView.region.center, span: span)
        }
    }

    func setRegion(region: LarkCoordinateRegion, animated: Bool) {
        let span = MACoordinateSpan(latitudeDelta: region.span.latitudeDelta, longitudeDelta: region.span.longitudeDelta)
        let region = MACoordinateRegion(center: region.center, span: span)
        mapView.setRegion(region, animated: animated)
    }

    func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool) {
        mapView.setCenter(coordinate, animated: animated)
    }

    func setZoomLevel(zoom: Double, center: CLLocationCoordinate2D, animated: Bool = true) {
        mapView.zoomLevel = MapConsts.defaultZoomLevel + 2
        mapView.setCenter(center, animated: animated)
    }

    func addAnnotation(annotation: LarkAnnotion) {
        let annotationPin = MAPointAnnotation()
        annotationPin.title = annotation.title
        annotationPin.subtitle = annotation.subTitle
        annotationPin.coordinate = annotation.coordinate
        mapView.addAnnotation(annotationPin)
    }

    public func removeAllannotion() {
        mapView.removeAnnotations(mapView.annotations)
    }

    func getMapDataSource() -> MapType {
        return .amap
    }

    func getMapType() -> MapType {
        return .amap
    }

    private static let logger = Logger.log(LarkMAMapView.self, category: "LocationPicker.LarkMAMapView")

    public let mapView: MAMapView

    public init(centerPinImage: UIImage?, language: Lang = .zh_CN) {
        FeatureUtils.setAMapAPIKey()
        MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        MAMapView.updatePrivacyAgree(.didAgree)
        mapView = MAMapView(frame: .zero)
        super.init(frame: .zero)
        self.centerPinImage = centerPinImage
        mapView.delegate = self
        addSubview(self.mapView)
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if let centerImage = centerPinImage {
            let pin = UIImageView(image: centerImage)
            mapView.addSubview(pin)
            pin.isUserInteractionEnabled = false
            pin.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(-centerImage.size.height / 2)
            }
            self.centerPinImageView = pin
        }
        switch language {
        case .zh_CN:
            mapView.mapLanguage = 0
        default:
            mapView.mapLanguage = 1
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LarkMAMapView: MAMapViewDelegate {
    public func mapViewWillStartLocatingUser(_ mapView: MAMapView) {
        delegate?.maMapViewWillStartLocatingUser(mapView)
    }

    public func mapView(_ mapView: MAMapView!, didFailToLocateUserWithError error: Error!) {
        delegate?.maMapView(mapView, failedLocate: error)
    }

    public func mapView(_ mapView: MAMapView, didUpdate userLocation: MAUserLocation, updatingLocation: Bool) {
        delegate?.maMapView(mapView, didUpdate: userLocation, updatingLocation: updatingLocation)
    }

    public func mapView(_ mapView: MAMapView, regionDidChangeAnimated animated: Bool) {
        delegate?.maMapView(mapView, regionDidChangeAnimated: animated)
    }

    public func mapView(_ mapView: MAMapView, viewFor annotation: MAAnnotation) -> MAAnnotationView? {
        return delegate?.maMapView(mapView, viewFor: annotation)
    }

    public func mapView(_ mapView: MAMapView, didAdd views: [MAAnnotationView]) {
        delegate?.maMapView(mapView, didAdd: views)
    }

    public func mapView(_ mapView: MAMapView, didChange mode: MAUserTrackingMode, animated: Bool) {
        delegate?.maMapView(mapView, didChange: mode, animated: animated)
    }
}
#endif
