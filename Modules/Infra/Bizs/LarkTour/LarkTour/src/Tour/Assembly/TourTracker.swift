//
//  TourTracker.swift
//  LarkTour
//
//  Created by Meng on 2019/8/16.
//

import Foundation
import Homeric
import LKCommonsTracker
import LarkContainer
import LarkTourInterface

final class TourTracker {
    static var instance: TourTracker?

    static var advertisingServiceProvider: (() -> AdvertisingService?)?

    static var source: String {
        return advertisingServiceProvider?()?.source ?? ""
    }
}
