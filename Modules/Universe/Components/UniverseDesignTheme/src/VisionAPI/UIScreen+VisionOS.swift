//
//  UIScreen+VisionOS.swift
//  UniverseDesignTheme
//
//  Created by Hayden on 19/12/2023.
//

import UIKit

public final class UDScreen {

    public static let main = UDScreen()

    private static let screenBounds: CGRect = {
        #if os(visionOS)
        if let windowScene = UIApplication.shared.ud.topMostWindowScene {
            return windowScene.coordinateSpace.bounds
        }
        return CGRect(x: 0, y: 0, width: 1280, height: 720)
        #else
        return UIScreen.main.bounds
        #endif
    }()

    private static let screenScale: CGFloat = {
        #if os(visionOS)
        let scale = UITraitCollection.ud.topMost.displayScale
        return scale > 0 ? scale : 2.0
        #else
        return UIScreen.main.scale
        #endif
    }()

    public var bounds: CGRect {
        UDScreen.screenBounds
    }

    public var scale: CGFloat {
        UDScreen.screenScale
    }
}
