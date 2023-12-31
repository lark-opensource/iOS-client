//
//  SketchShape+Codable.swift
//
//
//  Created by 刘建龙 on 2020/3/13.
//

import Foundation
import UIKit

// disable-lint: magic number
private extension UIColor {
    var hexRGBA: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "0x%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
    }

    convenience init(hexRGBA: String) {
        let str: String.SubSequence
        if hexRGBA.starts(with: "0x") {
            str = hexRGBA.dropFirst(2)
        } else if hexRGBA.starts(with: "#") {
            str = hexRGBA.dropFirst(1)
        } else {
            str = hexRGBA.dropFirst(0)
        }
        let hexVal = Int(str, radix: 16) ?? 0
        let r = hexVal & 0xFF000000 >> 24
        let g = hexVal & 0x00FF0000 >> 16
        let b = hexVal & 0x0000FF00 >> 8
        let a = hexVal & 0x000000FF >> 0
        self.init(red: CGFloat(r) / 255,
                  green: CGFloat(g) / 255,
                  blue: CGFloat(b) / 255,
                  alpha: CGFloat(a) / 255)
    }
}
// enable-lint: magic number

extension OvalPaintStyle: Codable {
    enum CodingKeys: String, CodingKey {
        case color
        case size
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.color = UIColor(hexRGBA: try container.decode(String.self, forKey: .color))
        self.size = try container.decode(type(of: size), forKey: .size)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(color.hexRGBA, forKey: .color)
        try container.encode(size, forKey: .size)
    }
}

extension OvalDrawable: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case frame
        case style
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(type(of: id), forKey: .id)
        self.frame = try container.decode(type(of: frame), forKey: .frame)
        self.style = try container.decode(type(of: style), forKey: .style)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(frame, forKey: .frame)
        try container.encode(style, forKey: .style)
    }
}

extension PencilPaintStyle: Codable {
    enum CodingKeys: String, CodingKey {
        case color
        case size
        case pencilType
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.color = UIColor(hexRGBA: try container.decode(String.self, forKey: .color))
        self.pencilType = try container.decode(type(of: pencilType), forKey: .pencilType)
        self.size = try container.decode(type(of: size), forKey: .size)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(color.hexRGBA, forKey: .color)
        try container.encode(size, forKey: .size)
        try container.encode(pencilType, forKey: .pencilType)

    }
}

extension PencilPathDrawable: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case points
        case dimension
        case style
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(type(of: id), forKey: .id)
        self.points = try container.decode(type(of: points), forKey: .points)
        self.dimension = try container.decode(type(of: dimension), forKey: .dimension)
        self.style = try container.decode(type(of: style), forKey: .style)
        pause = false
        finish = true
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(points, forKey: .points)
        try container.encode(dimension, forKey: .dimension)
        try container.encode(style, forKey: .style)
    }
}

extension RectanglePaintStyle: Codable {
    enum CodingKeys: String, CodingKey {
        case color
        case size
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.color = UIColor(hexRGBA: try container.decode(String.self, forKey: .color))
        self.size = try container.decode(type(of: size), forKey: .size)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(color.hexRGBA, forKey: .color)
        try container.encode(size, forKey: .size)
    }
}

extension RectangleDrawable: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case frame
        case style
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(type(of: id), forKey: .id)
        self.frame = try container.decode(type(of: frame), forKey: .frame)
        self.style = try container.decode(type(of: style), forKey: .style)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(frame, forKey: .frame)
        try container.encode(style, forKey: .style)
    }
}

extension ArrowPaintStyle: Codable {
    enum CodingKeys: String, CodingKey {
        case color
        case size
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.color = UIColor(hexRGBA: try container.decode(String.self, forKey: .color))
        self.size = try container.decode(type(of: size), forKey: .size)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(color.hexRGBA, forKey: .color)
        try container.encode(size, forKey: .size)
    }
}

extension ArrowDrawable: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case start
        case end
        case style
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(type(of: id), forKey: .id)
        self.start = try container.decode(type(of: start), forKey: .start)
        self.end = try container.decode(type(of: end), forKey: .end)
        self.style = try container.decode(type(of: style), forKey: .style)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(start, forKey: .start)
        try container.encode(end, forKey: .end)
        try container.encode(style, forKey: .style)
    }
}
