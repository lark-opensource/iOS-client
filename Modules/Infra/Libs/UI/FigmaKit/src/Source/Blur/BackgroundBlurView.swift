//
//  BackgroundBlurView.swift
//  FigmaKit
//
//  Created by Hayden Wang on 2021/8/3.
//

import Foundation
import UIKit

public typealias BackgroundBlurView = SystemBlurView

/* 去除私有 API

// swiftlint:disable all

// https://iphonedev.wiki/index.php/CAFilter
public final class BackgroundBlurView: UIView, UIViewBlurable {

    /// Blur radius. Defaults to `20`
    public var blurRadius: CGFloat = 20 {
        didSet {
            let blurFilter = (NSClassFromString(EncodedKeys.filterClass) as! NSObject.Type)
                .perform(NSSelectorFromString(EncodedKeys.createFilter), with: EncodedKeys.gaussianBlurType)
                .takeUnretainedValue() as! NSObject
            self.blurFilter = blurFilter
            blurFilter.setValue(blurRadius / 2, forKey: EncodedKeys.blurRadius)
            blurFilter.setValue(true, forKey: EncodedKeys.blurHardEdges)
            layer.filters = [blurFilter]
        }
    }

    /// Tint color. Defaults to `nil`
    public var fillColor: UIColor? {
        get { backgroundColor }
        set { backgroundColor = newValue }
    }

    /// Tint color alpha. Defaults to `0`
    public var fillOpacity: CGFloat = 0.0 {
        didSet {
            backgroundColor = backgroundColor?.withAlphaComponent(fillOpacity)
        }
    }

    private lazy var blurFilter = (NSClassFromString(EncodedKeys.filterClass) as! NSObject.Type)
        .perform(NSSelectorFromString(EncodedKeys.createFilter), with: EncodedKeys.gaussianBlurType)
        .takeUnretainedValue() as! NSObject

    public override class var layerClass: AnyClass {
        if let layerClass = NSClassFromString(EncodedKeys.blurLayer) {
            return layerClass
        } else {
            return super.layerClass
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.filters = [blurFilter]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BackgroundBlurView {

    enum EncodedKeys {
        // CAFilter
        static var filterClass: String {
            "CAFilter"
            // "Q0FGaWx0ZXI=".base64Decoded()!
        }
        // filterWithName:
        static var createFilter: String {
            "filterWithName:"
            // "ZmlsdGVyV2l0aE5hbWU6".base64Decoded()!
        }
        // CABackdropLayer
        static var blurLayer: String {
            "CABackdropLayer"
            // "Q0FCYWNrZHJvcExheWVy".base64Decoded()!
        }
        // inputRadius
        static var blurRadius: String {
            "inputRadius"
            // "aW5wdXRSYWRpdXM=".base64Decoded()!
        }
        // gaussianBlur
        static var gaussianBlurType: String {
            "gaussianBlur"
            // "Z2F1c3NpYW5CbHVy".base64Decoded()!
        }
        // inputHardEdges
        static var blurHardEdges: String {
            "inputHardEdges"
            // "aW5wdXRIYXJkRWRnZXM=".base64Decoded()!
        }
    }
}

// swiftlint:enable all

 */
