//
//  UploadProgressView.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/3/22.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation
import SnapKit

protocol UploadProgressLayerProtocol: AnyObject {
    var progress: Float { get set }
}

public enum UploadProgressType {
    case `default`
    case gradient(image: UIImage)

    public func layer(centerYOffset: CGFloat) -> UIView {
        switch self {
        case let .gradient(image):
            return UploadProgressGradientView(image: image)
        default:
            return UploadProgressView(centerYOffset: centerYOffset)
        }
    }

    public func layerType() -> AnyClass {
        switch self {
        case .gradient:
            return UploadProgressGradientView.self
        default:
            return UploadProgressView.self
        }
    }
}

public struct UploadProgressConfig {
    /// upload progress 开关
    static let uploadProgressEnable = true
    static let uploadProgressLayerTag: Int = 133_331

    public enum ShowProgressType {
        case complete           // 表示进度可以到达 100%
        case incomplete         // 表示进度不可以到达 100%
    }
}

open class UploadProgressView: UIView, UploadProgressLayerProtocol {
    static let labelWidth: CGFloat = 40

    public var progress: Float = 0.0 {
        didSet {
            var progress = self.progress
            if progress > 1 {
                progress = 1
            } else if progress < 0 {
                progress = 0
            }
            propgressLabel.text = String(format: "%d%%", Int(progress * 100))
            circlePathLayer.strokeEnd = CGFloat(progress)
        }
    }

    lazy var propgressLabel: UILabel = {
        var label = UILabel()
        label.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        label.textColor = UIColor.ud.rgb(0x1F2329)
        label.font = UIFont.systemFont(ofSize: 13)
        label.textAlignment = .center
        label.text = "0%"
        label.layer.masksToBounds = true
        label.layer.cornerRadius = UploadProgressView.labelWidth / 2
        self.addSubview(label)
        label.snp.makeConstraints({ (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(centerYOffset)
            make.width.height.equalTo(UploadProgressView.labelWidth)
        })
        return label
    }()

    lazy var circlePathLayer: CAShapeLayer = {
        var garyPathLayer = self.createShapeLayer()
        garyPathLayer.strokeStart = 0
        garyPathLayer.lineWidth = 2.0
        garyPathLayer.fillColor = UIColor.clear.cgColor
        garyPathLayer.strokeColor = UIColor.ud.rgb(0xDEE0E3).cgColor
        self.propgressLabel.layer.addSublayer(garyPathLayer)

        var circlePathLayer = self.createShapeLayer()
        circlePathLayer.strokeStart = 0
        circlePathLayer.lineWidth = 2.0
        circlePathLayer.fillColor = UIColor.clear.cgColor
        circlePathLayer.strokeColor = UIColor.ud.rgb(0x3370FF).cgColor
        self.propgressLabel.layer.addSublayer(circlePathLayer)
        return circlePathLayer
    }()

    fileprivate func createShapeLayer() -> CAShapeLayer {
        let circlePathLayer = CAShapeLayer()
        let frame = CGRect(x: 0, y: 0, width: UploadProgressView.labelWidth, height: UploadProgressView.labelWidth)
        let radius = UploadProgressView.labelWidth / 2
        circlePathLayer.frame = frame
        circlePathLayer.path = UIBezierPath(
            arcCenter: CGPoint(x: radius, y: radius),
            radius: radius - 1,
            startAngle: -CGFloat.pi / 2,
            endAngle: CGFloat.pi * 3 / 2,
            clockwise: true
        ).cgPath
        circlePathLayer.lineWidth = 2.0
        circlePathLayer.fillColor = UIColor.clear.cgColor
        return circlePathLayer
    }

    private let centerYOffset: CGFloat

    init(centerYOffset: CGFloat) {
        self.centerYOffset = centerYOffset
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.3)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class UploadProgressGradientView: UIView, UploadProgressLayerProtocol {
    public var progress: Float = 0.0

    public init(image: UIImage) {
        super.init(frame: CGRect.zero)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
