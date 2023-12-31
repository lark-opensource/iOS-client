//
//  LarkLynxUIText.swift
//  LarkLynxKit
//
//  Created by ByteDance on 2023/1/31.
//

import Foundation
import Lynx

public final class LarkLynxUIText: LynxUIText {
    public static let name: String = "text"
    
    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["text-selection", NSStringFromSelector(#selector(setTextSelection))]]
    }
    
    @objc func setTextSelection(context: Any?, requestReset _: Bool) {
    }
}
