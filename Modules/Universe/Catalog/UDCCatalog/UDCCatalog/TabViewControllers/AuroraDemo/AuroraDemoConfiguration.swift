//
//  AuroraDemoConfiguration.swift
//  UDCCatalog
//
//  Created by Hayden Wang on 2023/8/10.
//  Copyright © 2023 姚启灏. All rights reserved.
//

import UIKit
import UniverseDesignColor

// swiftlint:disable all

public struct AuroraDemoViewConfig {

    public init(mainBlob: BlobConfig,
                subBlob: BlobConfig,
                reflectionBlob: BlobConfig,
                backgroundColor: UIColor,
                blurRadius: CGFloat,
                blobOpacity: CGFloat) {
        self.mainBlob = mainBlob
        self.subBlob = subBlob
        self.reflectionBlob = reflectionBlob
        self.backgroundColor = backgroundColor
        self.blurRadius = blurRadius
        self.blobOpacity = blobOpacity
    }

    public var mainBlob: BlobConfig
    public var subBlob: BlobConfig
    public var reflectionBlob: BlobConfig
    public var backgroundColor: UIColor
    public var blurRadius: CGFloat
    public var blobOpacity: CGFloat

    public static var `default`: AuroraDemoViewConfig {
        return AuroraDemoViewConfig(mainBlob: .init(color: .clear, frame: .zero, opacity: 0),
                                subBlob: .init(color: .clear, frame: .zero, opacity: 0),
                                reflectionBlob: .init(color: .clear, frame: .zero, opacity: 0),
                                backgroundColor: .clear,
                                blurRadius: 0,
                                blobOpacity: 0)
    }

    public struct BlobConfig {
        public var color: UIColor
        public var frame: CGRect
        public var opacity: CGFloat

        public init(color: UIColor, frame: CGRect, opacity: CGFloat) {
            self.color = color
            self.frame = frame
            self.opacity = opacity
        }
    }
}

extension AuroraDemoViewConfig: Decodable {

    enum CodingKeys: String, CodingKey {
        case mainBlob
        case subBlob
        case reflectionBlob
        case backgroundColor
        case blurRadius
        case blobOpacity
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mainBlob = try container.decode(BlobConfig.self, forKey: .mainBlob)
        subBlob = try container.decode(BlobConfig.self, forKey: .subBlob)
        reflectionBlob = try container.decode(BlobConfig.self, forKey: .reflectionBlob)
        let colorName = try container.decode(String.self, forKey: .backgroundColor)
        backgroundColor = UDColor.getBaseColorByName(colorName) ?? .clear
        blurRadius = try container.decode(CGFloat.self, forKey: .blurRadius)
        blobOpacity = try container.decode(CGFloat.self, forKey: .blobOpacity)
    }

    /*
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mainBlob, forKey: .mainBlob)
        try container.encode(subBlob, forKey: .subBlob)
        try container.encode(reflectionBlob, forKey: .reflectionBlob)
        try container.encode(backgroundColor.toHexString(), forKey: .backgroundColor)
        try container.encode(blurRadius, forKey: .blurRadius)
        try container.encode(blobOpacity, forKey: .blobOpacity)
    }
    */
}

extension AuroraDemoViewConfig.BlobConfig: Decodable {
    enum CodingKeys: String, CodingKey {
        case color
        case frame
        case opacity
    }

    /*
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(color.toHexString(), forKey: .color)
        try container.encode([frame.origin.x, frame.origin.y, frame.size.width, frame.size.height], forKey: .frame)
        try container.encode(opacity, forKey: .opacity)
    }
    */

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let colorName = try container.decode(String.self, forKey: .color)
        color = UDColor.getBaseColorByName(colorName) ?? .clear
        let frameArray = try container.decode([CGFloat].self, forKey: .frame)
        frame = CGRect(x: frameArray[0], y: frameArray[1], width: frameArray[2], height: frameArray[3])
        opacity = try container.decode(CGFloat.self, forKey: .opacity)
    }
}

extension UIColor {

    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        var hexFormatted: String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }
        assert(hexFormatted.count == 6, "无效的颜色代码")
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    func toHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format:"#%06x", rgb)
    }
}

// swiftlint:enable all
