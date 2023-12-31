//
//  BDPAnnotationView.swift
//  EEMicroAppSDK
//
//  Created by 武嘉晟 on 2019/12/27.
//

import UIKit
import MapKit

final class BDPAnnotationView: MKAnnotationView {
    let uniqueID: Int?
    init(
        uniqueID: Int?,
        annotation: MKAnnotation?,
        reuseIdentifier: String?
    ) {
        self.uniqueID = uniqueID
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
