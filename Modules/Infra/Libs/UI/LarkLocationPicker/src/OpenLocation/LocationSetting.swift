//
//  LocationSetting.swift
//  LarkLocationPicker
//
//  Created by aslan on 2022/3/25.
//

import Foundation
import CoreLocation

public struct LocationSetting {
    var name: String
    var description: String
    var center: CLLocationCoordinate2D
    var zoomLevel: Double
    var isCrypto: Bool
    var isInternal: Bool
    var defaultAnnotation: Bool
    var needRightBtn: Bool

    public init(
        name: String,
        description: String,
        center: CLLocationCoordinate2D,
        zoomLevel: Double,
        isCrypto: Bool,
        isInternal: Bool = true,
        defaultAnnotation: Bool = false,
        needRightBtn: Bool = false
    ) {
        self.name = name
        self.description = description
        self.center = center
        self.zoomLevel = zoomLevel
        self.isCrypto = isCrypto
        self.isInternal = isInternal
        self.defaultAnnotation = defaultAnnotation
        self.needRightBtn = needRightBtn
    }
}
