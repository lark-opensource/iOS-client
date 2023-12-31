//
//  TranslationDirectionDetector.swift
//  SKUIKit
//
//  Created by zengsenyuan on 2022/7/18.
//  


import UIKit

public struct TranslationDirectionDetector {
    
    public enum ScrollDirection: String {
        case left
        case right
        case down
        case up
        case none
    }
    
    public static func detect(_ translation: CGPoint, threshold: CGFloat = 5) -> ScrollDirection {
        var direction: ScrollDirection = .none
        let absX = abs(translation.x)
        let absY = abs(translation.y)
        if absX > threshold || absY > threshold {
            if absX > absY {
                if translation.x > 0 {
                    direction = .right
                } else {
                    direction = .left
                }
            } else {
                if translation.y > 0 {
                    direction = .down
                } else {
                    direction = .up
                }
            }
        }
        debugPrint("TranslationDirectionDetector translation: \(translation) absX: \(absX), absY: \(absY)  detectDirection: \(direction) ")
        return direction
    }
}
