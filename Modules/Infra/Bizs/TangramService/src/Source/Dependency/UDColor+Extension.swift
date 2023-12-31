//
//  UDColor+Extension.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/19.
//

import UIKit
import Foundation
import RustPB
import UniverseDesignColor

// disable-lint: magic number

public extension Basic_V1_ThemeColor {
    /// 优先级：token > key > value
    var color: UIColor? {
        if hasToken, let color = UDColor.current.getValueByBizToken(token: token) {
            return color
        } else if hasKey, let color = colorByKey {
            if key.hasAlpha {
                return color.withAlphaComponent(CGFloat(key.alpha) / 100.0)
            }
            return color
        } else if hasValue {
            return UIColor.ud.color(
                CGFloat((value & 0xFF000000) >> 24),
                CGFloat((value & 0x00FF0000) >> 16),
                CGFloat((value & 0x0000FF00) >> 8),
                CGFloat((value & 0x000000FF)) / 255.0
            )
        }
        return nil
    }

    var colorByKey: UIColor? {
        switch (key.type, key.value) {
        case (.staticWhite, _): return UIColor.ud.primaryOnPrimaryFill
        case (.n, 0): return UIColor.ud.N00
        case (.n, 50): return UIColor.ud.N50
        case (.n, 100): return UIColor.ud.N100
        case (.n, 200): return UIColor.ud.N200
        case (.n, 300): return UIColor.ud.N300
        case (.n, 400): return UIColor.ud.N400
        case (.n, 500): return UIColor.ud.N500
        case (.n, 600): return UIColor.ud.N600
        case (.n, 650): return UIColor.ud.N650
        case (.n, 700): return UIColor.ud.N700
        case (.n, 800): return UIColor.ud.N800
        case (.n, 900): return UIColor.ud.N900
        case (.n, 950): return UIColor.ud.N950
        case (.n, 1000): return UIColor.ud.N1000
        case (.r, 50): return UIColor.ud.R50
        case (.r, 100): return UIColor.ud.R100
        case (.r, 200): return UIColor.ud.R200
        case (.r, 300): return UIColor.ud.R300
        case (.r, 400): return UIColor.ud.R400
        case (.r, 500): return UIColor.ud.colorfulRed
        case (.r, 600): return UIColor.ud.R600
        case (.r, 700): return UIColor.ud.R700
        case (.r, 800): return UIColor.ud.R800
        case (.r, 900): return UIColor.ud.R900
        case (.o, 50): return UIColor.ud.O50
        case (.o, 100): return UIColor.ud.O100
        case (.o, 200): return UIColor.ud.O200
        case (.o, 300): return UIColor.ud.O300
        case (.o, 400): return UIColor.ud.O400
        case (.o, 500): return UIColor.ud.colorfulOrange
        case (.o, 600): return UIColor.ud.O600
        case (.o, 700): return UIColor.ud.O700
        case (.o, 800): return UIColor.ud.O800
        case (.o, 900): return UIColor.ud.O900
        case (.y, 50): return UIColor.ud.Y50
        case (.y, 100): return UIColor.ud.Y100
        case (.y, 200): return UIColor.ud.Y200
        case (.y, 300): return UIColor.ud.Y300
        case (.y, 400): return UIColor.ud.Y400
        case (.y, 500): return UIColor.ud.colorfulYellow
        case (.y, 600): return UIColor.ud.Y600
        case (.y, 700): return UIColor.ud.Y700
        case (.y, 800): return UIColor.ud.Y800
        case (.y, 900): return UIColor.ud.Y900
        case (.s, 50): return UIColor.ud.S50
        case (.s, 100): return UIColor.ud.S100
        case (.s, 200): return UIColor.ud.S200
        case (.s, 300): return UIColor.ud.S300
        case (.s, 400): return UIColor.ud.S400
        case (.s, 500): return UIColor.ud.colorfulSunflower
        case (.s, 600): return UIColor.ud.S600
        case (.s, 700): return UIColor.ud.S700
        case (.s, 800): return UIColor.ud.S800
        case (.s, 900): return UIColor.ud.S900
        case (.l, 50): return UIColor.ud.L50
        case (.l, 100): return UIColor.ud.L100
        case (.l, 200): return UIColor.ud.L200
        case (.l, 300): return UIColor.ud.L300
        case (.l, 400): return UIColor.ud.L400
        case (.l, 500): return UIColor.ud.colorfulLime
        case (.l, 600): return UIColor.ud.L600
        case (.l, 700): return UIColor.ud.L700
        case (.l, 800): return UIColor.ud.L800
        case (.l, 900): return UIColor.ud.L900
        case (.g, 50): return UIColor.ud.G50
        case (.g, 100): return UIColor.ud.G100
        case (.g, 200): return UIColor.ud.G200
        case (.g, 300): return UIColor.ud.G300
        case (.g, 400): return UIColor.ud.G400
        case (.g, 500): return UIColor.ud.colorfulGreen
        case (.g, 600): return UIColor.ud.G600
        case (.g, 700): return UIColor.ud.G700
        case (.g, 800): return UIColor.ud.G800
        case (.g, 900): return UIColor.ud.G900
        case (.t, 50): return UIColor.ud.T50
        case (.t, 100): return UIColor.ud.T100
        case (.t, 200): return UIColor.ud.T200
        case (.t, 300): return UIColor.ud.T300
        case (.t, 400): return UIColor.ud.T400
        case (.t, 500): return UIColor.ud.colorfulTurquoise
        case (.t, 600): return UIColor.ud.T600
        case (.t, 700): return UIColor.ud.T700
        case (.t, 800): return UIColor.ud.T800
        case (.t, 900): return UIColor.ud.T900
        case (.w, 50): return UIColor.ud.W50
        case (.w, 100): return UIColor.ud.W100
        case (.w, 200): return UIColor.ud.W200
        case (.w, 300): return UIColor.ud.W300
        case (.w, 400): return UIColor.ud.W400
        case (.w, 500): return UIColor.ud.colorfulWathet
        case (.w, 600): return UIColor.ud.W600
        case (.w, 700): return UIColor.ud.W700
        case (.w, 800): return UIColor.ud.W800
        case (.w, 900): return UIColor.ud.W900
        case (.b, 50): return UIColor.ud.B50
        case (.b, 100): return UIColor.ud.B100
        case (.b, 200): return UIColor.ud.B200
        case (.b, 300): return UIColor.ud.B300
        case (.b, 400): return UIColor.ud.B400
        case (.b, 500): return UIColor.ud.colorfulBlue
        case (.b, 600): return UIColor.ud.B600
        case (.b, 700): return UIColor.ud.B700
        case (.b, 800): return UIColor.ud.B800
        case (.b, 900): return UIColor.ud.B900
        case (.i, 50): return UIColor.ud.I50
        case (.i, 100): return UIColor.ud.I100
        case (.i, 200): return UIColor.ud.I200
        case (.i, 300): return UIColor.ud.I300
        case (.i, 400): return UIColor.ud.I400
        case (.i, 500): return UIColor.ud.colorfulIndigo
        case (.i, 600): return UIColor.ud.I600
        case (.i, 700): return UIColor.ud.I700
        case (.i, 800): return UIColor.ud.I800
        case (.i, 900): return UIColor.ud.I900
        case (.p, 50): return UIColor.ud.P50
        case (.p, 100): return UIColor.ud.P100
        case (.p, 200): return UIColor.ud.P200
        case (.p, 300): return UIColor.ud.P300
        case (.p, 400): return UIColor.ud.P400
        case (.p, 500): return UIColor.ud.colorfulPurple
        case (.p, 600): return UIColor.ud.P600
        case (.p, 700): return UIColor.ud.P700
        case (.p, 800): return UIColor.ud.P800
        case (.p, 900): return UIColor.ud.P900
        case (.v, 50): return UIColor.ud.V50
        case (.v, 100): return UIColor.ud.V100
        case (.v, 200): return UIColor.ud.V200
        case (.v, 300): return UIColor.ud.V300
        case (.v, 400): return UIColor.ud.V400
        case (.v, 500): return UIColor.ud.colorfulViolet
        case (.v, 600): return UIColor.ud.V600
        case (.v, 700): return UIColor.ud.V700
        case (.v, 800): return UIColor.ud.V800
        case (.v, 900): return UIColor.ud.V900
        case (.c, 50): return UIColor.ud.C50
        case (.c, 100): return UIColor.ud.C100
        case (.c, 200): return UIColor.ud.C200
        case (.c, 300): return UIColor.ud.C300
        case (.c, 400): return UIColor.ud.C400
        case (.c, 500): return UIColor.ud.colorfulCarmine
        case (.c, 600): return UIColor.ud.C600
        case (.c, 700): return UIColor.ud.C700
        case (.c, 800): return UIColor.ud.C800
        case (.c, 900): return UIColor.ud.C900
        @unknown default: return nil
        }
    }
}

// enable-lint: magic number
