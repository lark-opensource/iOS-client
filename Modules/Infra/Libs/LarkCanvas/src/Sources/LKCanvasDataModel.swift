//
//  LKCanvasDataModel.swift
//  LarkCanvas
//
//  Created by Saafo on 2021/2/2.
//

import UIKit
import Foundation
import PencilKit

/// The Data Model needed by LKCanvasManager
/// - Note: This DataModel won't synchronize with LKCanvasManager in real time
///         used for serialization only
///         默认在 LKCanvasView 里采用 PropertyList 来序列化数据
///         新增可选值类型或计算类型时可以成功解析老数据，但新增必选类型的时候不能解析老数据
///         所以新增新类型时需要注意新老数据的互通，尽量使用可选值类型或计算类型
@available(iOS 13.0, *)
public struct LKCanvasDataModel: Codable {

    /// The drawings in the canvas
    var drawing: PKDrawing = PKDrawing()

    /// The content size of canvas
    var contentSize: CGSize = .zero

    /// The tool last time used, default is black pen
    var currentTool: PKInkingTool = .init(.pen, color: .black, width: 30)
}

// MARK: - Make PKInkingTool conform to Codable
@available(iOS 13.0, *)
extension PKInkingTool: Codable {
    enum CodingKeys: String, CodingKey {
        case inkType, color, width
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(inkType.rawValue, forKey: .inkType)
        try container.encode(Color(uiColor: color), forKey: .color)
        try container.encode(width, forKey: .width)
    }
    public init(from decoder: Decoder) throws {
        self.init(.pen, color: .black, width: 30) // must init the struct first
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inkType = PKInkingTool.InkType(
            rawValue: try container.decode(
                InkType.RawValue.self, forKey: .inkType
            )
        ) ?? .pen
        color = try container.decode(Color.self, forKey: .color).uiColor
        width = try container.decode(CGFloat.self, forKey: .width)
    }
}

/// Helper struct for serializing type `UIColor`
struct Color: Codable {
    var red: CGFloat = 0.0, green: CGFloat = 0.0, blue: CGFloat = 0.0, alpha: CGFloat = 0.0
    var uiColor: UIColor {
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    init(uiColor: UIColor) {
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    }
}
