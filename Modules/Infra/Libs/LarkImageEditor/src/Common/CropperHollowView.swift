//
//  CropperHollowView.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2017/12/7.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

final class CropperHollowView: UIView {
    let rectView = UIView()

    private(set) var rect: CGRect = CGRect(x: 0, y: 0, width: 100, height: 100)

    var fillColor = UIColor.ud.staticBlack.withAlphaComponent(0.5) {
        didSet {
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                self?.topMask.backgroundColor = self?.fillColor
                self?.bottomMask.backgroundColor = self?.fillColor
                self?.leftMask.backgroundColor = self?.fillColor
                self?.rightMask.backgroundColor = self?.fillColor
            })
        }
    }

    private var config: GridConfigure

    private var edgeThickNess: (horizontal: CGFloat, vertical: CGFloat) {
        return config.edgeThickNess
    }

    private var cornerTouchSize: CGSize {
        return config.cornerTouchSize
    }

    private var cornerSize: (width: CGFloat, length: CGFloat) {
        return config.cornerSize
    }

    // 四边蒙版view
    private var topMask: UIView = .init()
    private var bottomMask: UIView = .init()
    private var leftMask: UIView = .init()
    private var rightMask: UIView = .init()

    var topLeftCornerFrame: CGRect {
        return CGRect(
            x: rect.minX - cornerTouchSize.width / 2,
            y: rect.minY - cornerTouchSize.height / 2,
            width: cornerTouchSize.width,
            height: cornerTouchSize.height
        )
    }

    var topRightCornerFrame: CGRect {
        return CGRect(
            x: rect.maxX - cornerTouchSize.width / 2,
            y: rect.minY - cornerTouchSize.height / 2,
            width: cornerTouchSize.width,
            height: cornerTouchSize.height
        )
    }

    var bottomLeftCornerFrame: CGRect {
        return CGRect(
            x: rect.minX - cornerTouchSize.width / 2,
            y: rect.maxY - cornerTouchSize.height / 2,
            width: cornerTouchSize.width,
            height: cornerTouchSize.height
        )
    }

    var bottomRightCornerFrame: CGRect {
        return CGRect(
            x: rect.maxX - cornerTouchSize.width / 2,
            y: rect.maxY - cornerTouchSize.height / 2,
            width: cornerTouchSize.width,
            height: cornerTouchSize.height
        )
    }

    var topEdgeFrame: CGRect {
        return CGRect(
            x: topLeftCornerFrame.maxX,
            y: rect.minY - edgeThickNess.horizontal / 2,
            width: topRightCornerFrame.minX - topLeftCornerFrame.maxX,
            height: edgeThickNess.horizontal
        )
    }

    var bottomEdgeFrame: CGRect {
        return CGRect(
            x: bottomLeftCornerFrame.maxX,
            y: rect.maxY - edgeThickNess.horizontal / 2,
            width: bottomRightCornerFrame.minX - bottomLeftCornerFrame.maxX,
            height: edgeThickNess.horizontal
        )
    }

    var leftEdgeFrame: CGRect {
        return CGRect(
            x: rect.minX - edgeThickNess.vertical / 2,
            y: topLeftCornerFrame.maxY,
            width: edgeThickNess.vertical,
            height: bottomLeftCornerFrame.minY - topLeftCornerFrame.maxY
        )
    }

    var rightEdgeFrame: CGRect {
        return CGRect(
            x: rect.maxX - edgeThickNess.vertical / 2,
            y: topRightCornerFrame.maxY,
            width: edgeThickNess.vertical,
            height: bottomRightCornerFrame.minY - topRightCornerFrame.maxY
        )
    }

    init(frame: CGRect, config: GridConfigure = .default) {
        self.config = config

        super.init(frame: frame)
        self.isUserInteractionEnabled = false

        self.rectView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        setupRect()
        setupMaskViews()
        setupGridLines()
        setupCorners()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupRect() {
        rectView.layer.borderColor = UIColor.white.cgColor
        rectView.layer.borderWidth = 1

        self.addSubview(rectView)
        rectView.snp.makeConstraints { (make) in
            make.size.equalTo(self.rect.size)
            make.left.equalTo(self.rect.minX)
            make.top.equalTo(self.rect.minY)
        }

        let shadowView = UIView()
        shadowView.layer.borderColor = UIColor.white.cgColor
        shadowView.layer.borderWidth = 1
        shadowView.layer.shadowOpacity = 1
        shadowView.layer.shadowRadius = 2
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize.zero
        rectView.addSubview(shadowView)
        shadowView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func setupMaskViews() {
        // 顶部
        topMask = UIView()
        topMask.backgroundColor = fillColor
        self.insertSubview(topMask, at: 0)
        topMask.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(rectView.snp.top)
        }

        // 底部
        bottomMask = UIView()
        bottomMask.backgroundColor = fillColor
        self.insertSubview(bottomMask, at: 0)
        bottomMask.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(rectView.snp.bottom)
        }

        // 左边
        leftMask = UIView()
        leftMask.backgroundColor = fillColor
        self.insertSubview(leftMask, at: 0)
        leftMask.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalTo(rectView.snp.left)
            make.top.bottom.equalTo(rectView)
        }

        // 右边
        rightMask = UIView()
        rightMask.backgroundColor = fillColor
        self.insertSubview(rightMask, at: 0)
        rightMask.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.left.equalTo(rectView.snp.right)
            make.top.bottom.equalTo(rectView)
        }
    }

    private func setupGridLines() {
        // 水平线
        let horizontalLineCount = 3
        var previous: UIView?
        for _ in 1..<horizontalLineCount {
            let lineContainer = UIView()

            rectView.addSubview(lineContainer)
            lineContainer.snp.makeConstraints { (make) in
                make.height.equalToSuperview().multipliedBy(1.0 / CGFloat(horizontalLineCount))
                make.left.right.equalToSuperview()

                if let previousView = previous {
                    make.top.equalTo(previousView.snp.bottom)
                } else {
                    make.top.equalToSuperview()
                }
            }

            let line = UIView()
            line.backgroundColor = UIColor.white
            lineContainer.addSubview(line)
            line.snp.makeConstraints { (make) in
                make.height.equalTo(1 / UIScreen.main.scale)
                make.left.right.bottom.equalToSuperview()
            }

            previous = lineContainer
        }

        // 垂直线
        previous = nil
        let verticalLineCount = 3
        for _ in 1..<verticalLineCount {
            let lineContainer = UIView()

            rectView.addSubview(lineContainer)
            lineContainer.snp.makeConstraints { (make) in
                make.width.equalToSuperview().multipliedBy(1.0 / CGFloat(verticalLineCount))
                make.top.bottom.equalToSuperview()
                if let previousView = previous {
                    make.left.equalTo(previousView.snp.right)
                } else {
                    make.left.equalToSuperview()
                }
            }

            let line = UIView()
            line.backgroundColor = UIColor.white
            lineContainer.addSubview(line)
            line.snp.makeConstraints { (make) in
                make.width.equalTo(1 / UIScreen.main.scale)
                make.top.bottom.right.equalToSuperview()
            }

            previous = lineContainer
        }
    }

    private func setupCorners() {
        let lineWidth: CGFloat = cornerSize.width
        let lineLength: CGFloat = cornerSize.length
        let halfWidth = lineWidth / 2

        // top left
        generateCorner(
            start: CGPoint(x: lineLength + halfWidth, y: halfWidth),
            middle: CGPoint(x: halfWidth, y: halfWidth),
            end: CGPoint(x: halfWidth, y: lineLength + halfWidth)
        ) { (make) in
            make.left.top.equalTo(-lineWidth)
        }

        // top right
        generateCorner(
            start: CGPoint(x: halfWidth, y: halfWidth),
            middle: CGPoint(x: lineLength + halfWidth, y: halfWidth),
            end: CGPoint(x: lineLength + halfWidth, y: lineLength + halfWidth)
        ) { (make) in
            make.top.equalTo(-lineWidth)
            make.right.equalTo(lineWidth)
        }

        // bottom right
        generateCorner(
            start: CGPoint(x: lineLength + halfWidth, y: halfWidth),
            middle: CGPoint(x: lineLength + halfWidth, y: lineLength + halfWidth),
            end: CGPoint(x: halfWidth, y: lineLength + halfWidth)
        ) { (make) in
            make.bottom.equalTo(lineWidth)
            make.right.equalTo(lineWidth)
        }

        // bottom left
        generateCorner(
            start: CGPoint(x: halfWidth, y: halfWidth),
            middle: CGPoint(x: halfWidth, y: lineLength + halfWidth),
            end: CGPoint(x: lineLength + halfWidth, y: lineLength + halfWidth)
        ) { (make) in
            make.bottom.equalTo(lineWidth)
            make.left.equalTo(-lineWidth)
        }
    }

    private func generateCorner(start: CGPoint,
                                middle: CGPoint,
                                end: CGPoint,
                                setPosition: (_ make: ConstraintMaker) -> Void) {
        let cornerLayer = CAShapeLayer()
        let cornerPath = UIBezierPath()

        let lineWidth: CGFloat = cornerSize.width
        let lineLength: CGFloat = cornerSize.length

        drawCorner(in: cornerPath, start: start, middle: middle, end: end)
        cornerLayer.path = cornerPath.cgPath
        cornerLayer.lineWidth = lineWidth
        cornerLayer.strokeColor = UIColor.white.cgColor
        cornerLayer.fillColor = UIColor.clear.cgColor

        let size = CGSize(
            width: lineWidth + lineLength,
            height: lineWidth + lineLength
        )
        let cornerView = UIView()
        cornerView.layer.addSublayer(cornerLayer)
        rectView.addSubview(cornerView)
        cornerView.snp.makeConstraints { (make) in
            setPosition(make)
            make.size.equalTo(size)
        }
    }

    func update(rect: CGRect) {
        self.rect = rect

        rectView.snp.updateConstraints { (update) in
            update.size.equalTo(rect.size)
            update.left.equalTo(rect.minX)
            update.top.equalTo(rect.minY)
        }
    }

    private func drawCorner(in path: UIBezierPath, start: CGPoint, middle: CGPoint, end: CGPoint) {
        path.move(to: start)
        path.addLine(to: middle)
        path.addLine(to: end)
    }
}
