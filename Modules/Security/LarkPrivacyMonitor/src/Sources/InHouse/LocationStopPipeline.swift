//
//  LocationStopPipeline.swift
//  LarkPrivacyMonitor
//
//  Created by huanzhengjie on 2023/4/3.
//

import TSPrivacyKit
import CoreLocation

/// hook stopUpdatingLocation method
extension CLLocationManager {

    class func tspk_location_stop_preload() {
        Self.ts_swizzleInstanceMethod(#selector(stopUpdatingLocation), with: #selector(tspk_stopUpdatingLocation))
    }

    @objc
    func tspk_stopUpdatingLocation() {
        let result = TSPKLocationOfCLLocationManagerPipeline.handleAPIAccess(NSStringFromSelector(#selector(stopUpdatingLocation)),
                                                                             className: NSStringFromClass(CLLocationManager.self))
        if result?.action == .fuse {
            // will be fused
        } else {
            // call origin method
            self.tspk_stopUpdatingLocation()
        }
    }
}

class LocationStopPipeline: TSPKDetectPipeline {

    class override func preload() {
        CLLocationManager.tspk_location_stop_preload()
    }

    override class func entryType() -> String? {
        return "LocationOfCLLocationManager_Stop"
    }

    class override func pipelineType() -> String? {
        return "LocationOfCLLocationManager"
    }

    class override func dataType() -> String? {
        return "location"
    }

}
