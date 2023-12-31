//
//  OpenPlatformMockSearchPOIProvider.swift
//  Ecosystem
//
//  Created by ByteDance on 2023/12/15.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkAssembler
import Swinject
import OPPlugin
import LarkLocationPicker

final class OpenPlatformMockSearchPOIProvider: OpenPluginSearchPoiProxy {
    
    func searchPOI(coordinate: CLLocationCoordinate2D, radius: Int, maxCount: Int, keyword: String?, failedCallback: @escaping ((Error) -> Void), successCallback: @escaping (([LarkLocationPicker.LocationData]) -> Void)) {
        successCallback([])
    }
   
}
