//
//  UDOCColor.swift
//  UniverseDesignColor
//
//  Created by 姚启灏 on 2021/7/20.
//

import UIKit
import Foundation

@objc
public final class UDOCColor: NSObject {

    @objc
    public static func getValueByBizToken(token: String) -> UIColor? {
        return UDColor.current.getValueByBizToken(token: token)
    }
}
