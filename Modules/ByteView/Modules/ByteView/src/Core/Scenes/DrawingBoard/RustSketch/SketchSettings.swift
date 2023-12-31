//
//  SketchSettings.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/12/31.
//

import Foundation
import CoreGraphics

struct SketchSettings: Decodable {
    static let sketchSettingField = "vc_sketch_config"

    struct PencilConfig: Decodable {
        let minDistance: CGFloat
        let k: CGFloat
        let errorGap: CGFloat
        let fittingInterval: UInt64
        let snippetInterval: UInt64
    }
    struct CometConfig: Decodable {
        let weakSpeed: CGFloat
        let minDistance: CGFloat
        let fittingInterval: UInt64
        let snippetInterval: UInt64
        let reduceTimes: Float
        let enableWebgl: Bool
    }

    let pencilConfig: PencilConfig
    let cometConfig: CometConfig
    let guestLocalShapeAutoDisappearTime: TimeInterval
    let guestReceiveSeiAutoDisappearTime: TimeInterval
    // disable-lint: magic number
    static let `default` = SketchSettings(pencilConfig: PencilConfig(minDistance: 3.0,
                                                                     k: 0.25,
                                                                     errorGap: 100.0,
                                                                     fittingInterval: 1000,
                                                                     snippetInterval: 25),
                                          cometConfig: CometConfig(weakSpeed: 0.01,
                                                                   minDistance: 3.0,
                                                                   fittingInterval: 1000,
                                                                   snippetInterval: 25,
                                                                   reduceTimes: 5,
                                                                   enableWebgl: false),
                                          guestLocalShapeAutoDisappearTime: 30000,
                                          guestReceiveSeiAutoDisappearTime: 3000)
}
