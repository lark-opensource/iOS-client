//
//  CoordinateConverter.swift
//  LarkLocationPicker
//
//  Created by Fangzhou Liu on 2019/7/19.
//

import UIKit
import Foundation
import MapKit

// disable-lint: magic number

public final class CoordinateConverter {

    public static let a: Double = 6378245.0
    public static let ee: Double = 0.00669342162296594323

    public static func convertGCJ02ToWGS84(coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let deltaD = delta(wgLat: coordinate.latitude, wgLon: coordinate.longitude)
        let mgLat = coordinate.latitude - Double(deltaD.x)
        let mgLon = coordinate.longitude - Double(deltaD.y)
        return CLLocationCoordinate2D(latitude: mgLat, longitude: mgLon)
    }

    private static func delta(wgLat: Double, wgLon: Double) -> CGPoint {
        var dLat = transformLat(x: wgLon - 105.0, y: wgLat - 35.0)
        var dLon = transformLon(x: wgLon - 105.0, y: wgLat - 35.0)
        let radLat = wgLat / 180.0 * Double.pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * Double.pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * Double.pi)
        return CGPoint(x: dLat, y: dLon)
    }

    private static func transformLat(x: Double, y: Double) -> Double {
        var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * Double.pi) + 20.0 * sin(2.0 * x * Double.pi)) * 2.0 / 3.0
        ret += (20.0 * sin(y * Double.pi) + 40.0 * sin(y / 3.0 * Double.pi)) * 2.0 / 3.0
        ret += (160.0 * sin(y / 12.0 * Double.pi) + 320 * sin(y * Double.pi / 30.0)) * 2.0 / 3.0
        return ret
    }

    private static func transformLon(x: Double, y: Double) -> Double {
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * Double.pi) + 20.0 * sin(2.0 * x * Double.pi)) * 2.0 / 3.0
        ret += (20.0 * sin(x * Double.pi) + 40.0 * sin(x / 3.0 * Double.pi)) * 2.0 / 3.0
        ret += (150.0 * sin(x / 12.0 * Double.pi) + 300.0 * sin(x / 30.0 * Double.pi)) * 2.0 / 3.0
        return ret
    }
}
