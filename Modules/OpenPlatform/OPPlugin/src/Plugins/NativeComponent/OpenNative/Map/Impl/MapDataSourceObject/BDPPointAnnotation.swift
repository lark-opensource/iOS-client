//
//  BDPPointAnnotation.swift
//  EEMicroAppSDK
//
//  Created by 武嘉晟 on 2019/12/26.
//

import MapKit
import OPPluginBiz

final class BDPPointAnnotation: MKPointAnnotation {
    let uniqueID: Int?
    let markerModel: BDPMapMarkerModel
    init(
        uniqueID: Int?,
        markerModel: BDPMapMarkerModel
    ) {
        self.uniqueID = uniqueID
        self.markerModel = markerModel
        super.init()
    }
}
