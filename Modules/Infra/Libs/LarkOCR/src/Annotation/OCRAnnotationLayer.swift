//
//  OCRAnnotationLayer.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/8/23.
//

import Foundation
import LKCommonsLogging
import UniverseDesignColor
import UIKit

public struct AnnotationBox: CustomDebugStringConvertible, CustomStringConvertible {
    public var lineIndex: Int
    public var str: String
    public var isSelected: Bool
    public var points: [CGPoint]
    public var imageSize: CGSize
    public var showImageSize: CGSize
    public var pathRadius: CGFloat
    public var path: UIBezierPath

    public init(lineIndex: Int, str: String, isSelected: Bool, points: [CGPoint], imageSize: CGSize) {
        self.lineIndex = lineIndex
        self.str = str
        self.isSelected = isSelected
        self.points = points
        self.imageSize = imageSize
        self.showImageSize = imageSize
        self.pathRadius = 2
        self.path = Self.path(imageSize: imageSize, showImageSize: imageSize, points: points, radius: 2)
    }

    public mutating func updatePathIfNeeded(showImageSize: CGSize, radius: CGFloat) {
        if self.showImageSize == showImageSize,
           self.pathRadius == radius {
            return
        }
        self.showImageSize = showImageSize
        self.pathRadius = radius
        self.path = Self.path(
            imageSize: self.imageSize,
            showImageSize: self.showImageSize,
            points: self.points,
            radius: self.pathRadius
        )
    }

    private static func path(imageSize: CGSize, showImageSize: CGSize, points: [CGPoint], radius: CGFloat) -> UIBezierPath {
        if imageSize == showImageSize {
            return UIBezierPath(roundedPolygon: points, radius: radius)
        }
        let newPoints = points.map { point in
            return CGPoint(
                x: point.x * showImageSize.width / imageSize.width,
                y: point.y * showImageSize.height / imageSize.height
            )
        }
        return UIBezierPath(roundedPolygon: newPoints, radius: radius)
    }

    public var debugDescription: String {
        return description
    }

    public var description: String {
        return "str: \(str), isSelected \(isSelected), points \(points)"
    }
}

public struct AnnotationUIConfig {
    public var maskColor: UIColor = UIColor.ud.staticBlack.withAlphaComponent(0.4)
    public var unselectedFillColor: UIColor = UIColor.clear
    public var unselectedStrokeColor: UIColor = UIColor.ud.B200.alwaysLight
    public var selectedFillColor: UIColor = UIColor.ud.colorfulBlue.alwaysLight.withAlphaComponent(0.4)
    public var selectedStrokeColor: UIColor = UIColor.ud.colorfulBlue.alwaysLight
    public var selectedStrokeLineWidth: CGFloat = 1
    public var unselectedStrokeLineWidth: CGFloat = 0.5

    public init() {
    }
}

public final class OCRAnnotationShapeLayer: CALayer {

    var maskLayer: CAShapeLayer = CAShapeLayer()
    var selectLayer: CAShapeLayer = CAShapeLayer()
    var unselectLayer: CAShapeLayer = CAShapeLayer()

    public var results: [AnnotationBox] = [] {
        didSet {
            self.updateShapeLayer()
        }
    }

    public var config: AnnotationUIConfig {
        didSet {
            self.updateShapeLayer()
        }
    }

    public init(config: AnnotationUIConfig) {
        self.config = config
        super.init()
        self.addSublayer(self.maskLayer)
        self.addSublayer(self.selectLayer)
        self.addSublayer(self.unselectLayer)
    }

    public override init(layer: Any) {
        if let shapeLayer = layer as? OCRAnnotationShapeLayer {
            self.config = shapeLayer.config
        } else {
            self.config = AnnotationUIConfig()
        }
        super.init(layer: layer)
        self.addSublayer(self.maskLayer)
        self.addSublayer(self.selectLayer)
        self.addSublayer(self.unselectLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSublayers() {
        super.layoutSublayers()
        self.maskLayer.frame = self.bounds
        self.selectLayer.frame = self.bounds
        self.unselectLayer.frame = self.bounds
        self.updateShapeLayer()
    }

    func updateShapeLayer() {
        guard !results.isEmpty else {
            self.maskLayer.isHidden = true
            self.selectLayer.isHidden = true
            self.unselectLayer.isHidden = true
            return
        }
        self.maskLayer.isHidden = false
        self.selectLayer.isHidden = false
        self.unselectLayer.isHidden = false

        let clipBounds = self.bounds
        var showPaths: [UIBezierPath] = []
        var showSelectPaths: [UIBezierPath] = []
        var showUnselectPaths: [UIBezierPath] = []

        self.results.forEach { box in
            if box.path.bounds.intersects(clipBounds) {
                showPaths.append(box.path)
                if box.isSelected {
                    showSelectPaths.append(box.path)
                } else {
                    showUnselectPaths.append(box.path)
                }
            }
        }

        self.maskLayer.fillColor = self.config.maskColor.cgColor
        var maskPath = UIBezierPath()
        maskPath.append(.init(rect: clipBounds))
        showPaths.forEach { path in
            maskPath.append(path)
        }
        self.maskLayer.path = maskPath.cgPath
        self.maskLayer.fillRule = .evenOdd

        var unselectPath = UIBezierPath()
        showUnselectPaths.forEach { path in
            unselectPath.append(path)
        }
        self.unselectLayer.path = unselectPath.cgPath
        self.unselectLayer.lineWidth = config.unselectedStrokeLineWidth
        self.unselectLayer.strokeColor = config.unselectedStrokeColor.cgColor
        self.unselectLayer.fillColor = config.unselectedFillColor.cgColor
        self.unselectLayer.fillRule = .evenOdd

        var selectPath = UIBezierPath()
        showSelectPaths.forEach { path in
            selectPath.append(path)
        }
        self.selectLayer.path = selectPath.cgPath
        self.selectLayer.lineWidth = config.selectedStrokeLineWidth
        self.selectLayer.strokeColor = config.selectedStrokeColor.cgColor
        self.selectLayer.fillColor = config.selectedFillColor.cgColor
        self.selectLayer.fillRule = .evenOdd
    }
}


public final class OCRAnnotationLayer: CALayer {

    public var results: [AnnotationBox] = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    public var config: AnnotationUIConfig {
        didSet {
            setNeedsDisplay()
        }
    }

    public init(config: AnnotationUIConfig) {
        self.config = config
        super.init()
    }

    public override init(layer: Any) {
        if let annotationLayer = layer as? OCRAnnotationLayer {
            self.config = annotationLayer.config
        } else {
            self.config = AnnotationUIConfig()
        }
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func draw(in ctx: CGContext) {
        guard !results.isEmpty else {
            return
        }
        ctx.setFillColor(self.config.maskColor.cgColor)
        let clipBounds = ctx.boundingBoxOfClipPath
        var showPaths: [UIBezierPath] = []
        var showSelectPaths: [UIBezierPath] = []
        var showUnselectPaths: [UIBezierPath] = []
        self.results.forEach { box in
            if box.path.bounds.intersects(clipBounds) {
                showPaths.append(box.path)
                if box.isSelected {
                    showSelectPaths.append(box.path)
                } else {
                    showUnselectPaths.append(box.path)
                }
            }
        }

        ctx.addRect(clipBounds)
        showPaths.forEach { path in
            ctx.addPath(path.cgPath)
        }
        ctx.fillPath(using: .evenOdd)
        ctx.saveGState()

        showUnselectPaths.forEach { path in
            ctx.addPath(path.cgPath)
        }
        ctx.setLineWidth(config.unselectedStrokeLineWidth)
        ctx.setStrokeColor(config.unselectedStrokeColor.cgColor)
        ctx.strokePath()

        ctx.setFillColor(config.unselectedFillColor.cgColor)
        showUnselectPaths.forEach { path in
            ctx.addPath(path.cgPath)
        }
        ctx.fillPath(using: .evenOdd)

        showSelectPaths.forEach { path in
            ctx.addPath(path.cgPath)
        }
        ctx.setLineWidth(config.selectedStrokeLineWidth)
        ctx.setStrokeColor(config.selectedStrokeColor.cgColor)
        ctx.strokePath()

        ctx.setFillColor(config.selectedFillColor.cgColor)
        showSelectPaths.forEach { path in
            ctx.addPath(path.cgPath)
        }
        ctx.fillPath(using: .evenOdd)
        ctx.restoreGState()
    }
}
