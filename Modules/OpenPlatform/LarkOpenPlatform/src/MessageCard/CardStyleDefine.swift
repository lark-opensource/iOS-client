//
//  CardStyleDefine.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2021/10/13.
//

import Foundation
import UIKit
import UniverseDesignColor

func cardBorderColor() -> UIColor {
    if let borderColor = UDColor.current.getValueByBizToken(token: "imtoken-message-card-border") {
        return borderColor
    }
    return UIColor.ud.lineBorderCard
}
