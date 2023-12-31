//
//  OpenPluginSearchPoiProxy.swift
//  OPPlugin
//
//  Created by ByteDance on 2023/12/8.
//

import Foundation
import CoreLocation
import LarkLocalizations
import LarkLocationPicker

public protocol OpenPluginSearchPoiProxy {
    func searchPOI(coordinate: CLLocationCoordinate2D,
                   radius: Int,
                   maxCount: Int,
                   keyword: String?,
                   failedCallback: @escaping ((Error) -> Void),
                   successCallback: @escaping (([LarkLocationPicker.LocationData]) -> Void))
}
