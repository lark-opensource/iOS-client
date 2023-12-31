//
//  ChooseLocation.swift
//  LarkLocationPicker
//
//  Created by aslan on 2022/3/25.
//

import UIKit
import Foundation
import CoreLocation

public final class ChooseLocation {
    public let name: String
    public let address: String
    public let location: CLLocationCoordinate2D
    public let zoomLevel: Double
    public let isInternal: Bool
    public let image: UIImage
    // enum: .amap or .apple
    public let mapType: String
    // enum: defatult, list or search
    public let selectType: String

    public init(
        name: String,
        address: String,
        location: CLLocationCoordinate2D,
        zoomLevel: Double,
        isInternal: Bool = true,
        image: UIImage,
        mapType: String,
        selectType: String
    ) {
        self.name = name
        self.address = address
        self.location = location
        self.zoomLevel = zoomLevel
        self.isInternal = isInternal
        self.image = image
        self.mapType = mapType
        self.selectType = selectType
    }
}
