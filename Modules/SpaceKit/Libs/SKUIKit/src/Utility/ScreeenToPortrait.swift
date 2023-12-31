//
//  ScreeenToPortrait.swift
//  SKUIKit
//
//  Created by qiyongka on 2022/8/8.
//

import Foundation

public struct ScreeenToPortrait {
    
    public static func forceInterfaceOrientationIfNeed(to orientation: UIInterfaceOrientation?) {
        guard !SKDisplay.pad else { return }
        guard let orientation = orientation, UIApplication.shared.statusBarOrientation != orientation else { return }
        LKDeviceOrientation.setOritation(UIDeviceOrientation.portrait)
    }
}
