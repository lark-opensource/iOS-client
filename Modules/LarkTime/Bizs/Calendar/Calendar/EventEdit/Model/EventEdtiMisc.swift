//
//  EventEdtiMisc.swift
//  Calendar
//
//  Created by 张威 on 2020/4/30.
//

import UIKit
import CoreLocation
import RustPB
import EventKit

struct EventEditLocation: EventLocationType, PBModelConvertible {

    typealias PBModel = RustPB.Calendar_V1_CalendarLocation

    var name: String { pb.location }
    var address: String { pb.address }
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: CLLocationDegrees(pb.latitude),
            longitude: CLLocationDegrees(pb.longitude)
        )
    }

    private let pb: PBModel

    init(from pb: PBModel) {
        self.pb = pb
    }

    init(name: String, address: String, coordinate: CLLocationCoordinate2D) {
        var pb = PBModel()
        pb.location = name
        pb.address = address
        pb.latitude = Float(coordinate.latitude)
        pb.longitude = Float(coordinate.longitude)
        self.pb = pb
    }

    func getPBModel() -> PBModel {
        return pb
    }
}

extension EventEditLocation {

    static func makeFromEKLocation(_ ekLocation: EKStructuredLocation) -> Self {
        var pb = PBModel()
        pb.location = ekLocation.title ?? ""
        pb.address = ""
        pb.latitude = Float(ekLocation.geoLocation?.coordinate.latitude ?? 360)
        pb.longitude = Float(ekLocation.geoLocation?.coordinate.longitude ?? 360)
        return .init(from: pb)
    }

    func toEKLocation() -> EKStructuredLocation {
        let ekLocation = EKStructuredLocation(title: name)
        ekLocation.geoLocation = CLLocation(
            latitude: CLLocationDegrees(coordinate.latitude),
            longitude: CLLocationDegrees(coordinate.longitude)
        )
        return ekLocation
    }
}
