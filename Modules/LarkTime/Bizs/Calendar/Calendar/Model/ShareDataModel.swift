//
//  ShareBoardModel.swift
//  Calendar
//
//  Created by zhuheng on 2020/5/8.
//

import UIKit
import Foundation

struct ShareDataModel {
    var image: UIImage?
    let linkAddress: String
    let shareCopy: String

    init(pb: GetEventShareLinkResponse) {
        if pb.hasImageData {
            self.image = UIImage(data: pb.imageData)
        }
        self.linkAddress = pb.linkAddress
        self.shareCopy = pb.shareCopy
    }
}
