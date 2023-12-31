//
//  OCRModel.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/8/23.
//

import UIKit
import Foundation

public struct ImageOCRResult {
    public var imageSize: CGSize
    public var lines: [Line]
    public var regions: [Region]
    public var entities: [Entity]

    public init(
        imageSize: CGSize,
        lines: [Line],
        regions: [Region],
        entities: [Entity]
    ) {
        self.imageSize = imageSize
        self.lines = lines
        self.regions = regions
        self.entities = entities
    }
}

extension ImageOCRResult {
    public struct Rect {
        public var topLeft: CGPoint
        public var topRight: CGPoint
        public var bottomLeft: CGPoint
        public var bottomRight: CGPoint
        public init(topLeft: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint, topRight: CGPoint) {
            self.topLeft = topLeft
            self.bottomLeft = bottomLeft
            self.bottomRight = bottomRight
            self.topRight = topRight
        }

    }
}

extension ImageOCRResult {
    public struct Line {
        public var index: Int
        public var rect: ImageOCRResult.Rect
        public var string: String
        public var regionIndex: Int
        public var entities: [ImageOCRResult.Entity]

        public init(index: Int, rect: ImageOCRResult.Rect, string: String, regionIndex: Int, entities: [ImageOCRResult.Entity]) {
            self.index = index
            self.rect = rect
            self.string = string
            self.regionIndex = regionIndex
            self.entities = entities
        }
    }
}

extension ImageOCRResult {
    public struct Region {
        public var string: String
        public var lines: [ImageOCRResult.Line]
        public var entities: [ImageOCRResult.Entity]

        public init(string: String, lines: [ImageOCRResult.Line], entities: [ImageOCRResult.Entity]) {
            self.string = string
            self.lines = lines
            self.entities = entities
        }
    }
}

extension ImageOCRResult {
    public struct Entity {
        public enum EntityType: Int {
            case unknown = 0
            case phone = 1
            case url = 2
        }

        public struct Range {
            public var start: Int
            public var end: Int
            public init(start: Int, end: Int) {
                self.start = start
                self.end = end
            }
        }
        public var type: Entity.EntityType
        public var string: String
        public var lines: [(Int, Range)]
        public var regionIndex: Int
        public var regionRange: Range
        public var extra: [String: String]

        public init(
            type: Entity.EntityType,
            string: String,
            lines: [(Int, Range)],
            regionIndex: Int,
            regionRange: Range,
            extra: [String: String] = [:]
        ) {
            self.type = type
            self.string = string
            self.lines = lines
            self.regionIndex = regionIndex
            self.regionRange = regionRange
            self.extra = extra
        }
    }
}
