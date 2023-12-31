//
//  WhiteboardShape.swift
//  ByteView
//
//  Created by 阮明哲 on 2022/3/25.
//

import Foundation
import CoreGraphics
import UIKit

public typealias ShapeID = String

// MARK: - Drawable

protocol WhiteboardShape: CustomStringConvertible {
    var id: ShapeID { get }
}

extension WhiteboardShape {
    public var description: String {
        "Shape(\(id))"
    }
}

enum DrawableType {
    case text
    case vector
    case image
    case nameTag
    case unknown
}

enum CmdUpdateType {
    case graphic
    case path
    case stroke
    case fill
    case transform
}

struct TextStyle {
    var textColor: UIColor
    var font: UIFont
    var backgroundColor: UIColor
    var cornerRadius: CGFloat

    init(textColor: UIColor,
         font: UIFont,
         backgroundColor: UIColor,
         cornerRadius: CGFloat = 4) {
        self.textColor = textColor
        self.font = font
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }
}

struct VectorShape: WhiteboardShape {
    let path: CGMutablePath
    let strokeColor: UIColor?
    let lineWidth: CGFloat?
    let fillColor: UIColor?
    let transform: CGAffineTransform?
    let id: ShapeID
    init(id: ShapeID,
         path: CGMutablePath,
         strokeColor: UIColor? = nil,
         lineWidth: CGFloat? = nil,
         fillColor: UIColor? = nil,
         transform: CGAffineTransform? = nil) {
        self.id = id
        self.path = path
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
        self.fillColor = fillColor
        self.transform = transform
    }
}

struct TextDrawable: WhiteboardShape {
    let id: ShapeID
    let text: String
    let fontSize: Int
    let fontWeight: Int
    let strokeColor: UIColor?
    let fillColor: UIColor?
    let lineWidth: CGFloat?
    let transform: CGAffineTransform?
    init(id: ShapeID,
         text: String,
         fontSize: Int,
         fontWeight: Int,
         strokeColor: UIColor? = nil,
         fillColor: UIColor? = nil,
         lineWidth: CGFloat? = nil,
         transform: CGAffineTransform? = nil) {
        self.id = id
        self.text = text
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.lineWidth = lineWidth
        self.transform = transform
    }

    var description: String {
        "RecognizeText(id: \(id))"
    }
}

struct ImageDrawable: WhiteboardShape {
    var id: ShapeID
    let resourceID: UInt64
    let size: CGSize
    init(id: ShapeID,
         resourceID: UInt64,
         size: CGSize) {
        self.id = id
        self.resourceID = resourceID
        self.size = size
    }

    var description: String {
        "ImageDrawable(id: \(id))"
    }
}

struct NicknameDrawable: WhiteboardShape {
    var id: ShapeID
    let text: String
    let style: TextStyle
    let position: CGPoint

    var description: String {
        "NickName(id: \(id))"
    }
}
