//
//  DriveCircleProgressBar.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/1/21.
//

import UIKit

/// Circle Progress Bar

class DriveCircleProgressBar: UIView {

    var progress: CGFloat = 0.0 {
        didSet {
            if progress != oldValue {
                updateProgress()
            }
        }
    }

    var lineWidth: CGFloat = 2.0 {
        didSet {
            backgroundLayer.lineWidth = lineWidth
            frontLayer.lineWidth = lineWidth
        }
    }

    var frontColor: UIColor = UIColor.ud.colorfulBlue {
        didSet {
            frontLayer.strokeColor = frontColor.cgColor
        }
    }

    var backColor: UIColor = UIColor.ud.N200 {
        didSet {
            backgroundLayer.strokeColor = backColor.cgColor
        }
    }

    private lazy var backgroundLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = backColor.cgColor
        self.layer.addSublayer(layer)
        return layer
    }()

    private lazy var frontLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = frontColor.cgColor
        self.layer.addSublayer(layer)
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        _ = backgroundLayer
        _ = frontLayer
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundLayer.frame = bounds
        frontLayer.frame = bounds
        let radius = min(bounds.width, bounds.height) * 0.5
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let backPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        backgroundLayer.path = backPath.cgPath

        updateProgress()
    }

    private func updateProgress() {
        let radius = min(bounds.width, bounds.height) * 0.5
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let progressValue = max(min(1.0, progress), 0.0)
        let endAngle = CGFloat.pi * 2 * progressValue - CGFloat.pi / 2
        let frontFillPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: -CGFloat.pi / 2, endAngle: endAngle, clockwise: true)
        frontLayer.path = frontFillPath.cgPath
    }
}
