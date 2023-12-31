//
//  LarkMapViewInterface.swift
//  LarkLocationPicker
//
//  Created by aslan on 2022/2/23.
//

import Foundation
import CoreLocation
import UIKit

public struct LarkCoordinateSpan {

    public var latitudeDelta: CLLocationDegrees

    public var longitudeDelta: CLLocationDegrees

    public init(latitudeDelta: CLLocationDegrees, longitudeDelta: CLLocationDegrees) {
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
}

public struct LarkCoordinateRegion {

    public var center: CLLocationCoordinate2D

    public var span: LarkCoordinateSpan

    public init(center: CLLocationCoordinate2D, span: LarkCoordinateSpan) {
        self.center = center
        self.span = span
    }
}

public enum LarkUserTrackingMode: Int {
    case none
    case follow
    case followWithHeading
}

protocol MapViewAdapter: UIView {
    #if canImport(MAMapKit)
    var delegate: LarkMapViewAdapterDelegate? { get set }
    #else
    var delegate: LarkMKMapViewDelegate? { get set }
    #endif
    var distanceFilter: CLLocationDistance { get set }
    var userTrackingMode: LarkUserTrackingMode { get set }
    var showsCompass: Bool { get set }
    var showsScale: Bool { get set }
    var showsUserLocation: Bool { get set }
    var centerCoordinate: CLLocationCoordinate2D { get set }
    var region: LarkCoordinateRegion { get }
    var userLocation: MKMapItemModel { get }
    var centerPinImage: UIImage? { get set }
    var centerPinImageView: UIImageView? { get set }

    func setZoomLevel(zoom: Double, center: CLLocationCoordinate2D, animated: Bool)
    func setRegion(region: LarkCoordinateRegion, animated: Bool)
    func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool)
    func setUserTrackingMode(_ mode: LarkUserTrackingMode, animated: Bool)
    func addAnnotation(annotation: LarkAnnotion)
    func removeAllannotion()
    func getMapDataSource() -> MapType
    func getMapType() -> MapType
}
