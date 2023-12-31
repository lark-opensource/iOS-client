//
//  UniverseDesignSectionIndexViewItemPreview.swift
//  UniverseDesignTabs
//
//  Created by Yaoguoguo on 2023/2/7.
//

import Foundation
import UIKit

public enum UDSectionIndexViewItemPreviewType: Int {
    case `default`
    case rect
    case circle
    case drip
    case empty
}

final public class UDSectionIndexViewItemPreview: UIView {

    public var titleColor: UIColor? {
        didSet {
            titleLabel.textColor = titleColor
        }
    }
    public var titleFont: UIFont? {
        didSet {
            titleLabel.font = titleFont
        }
    }
    public var color: UIColor? {
        didSet {
            switch type {
            case .default, .rect :
                titleLabel.backgroundColor = color
            case .circle :
                if let borderColor = color {
                    titleLabel.layer.ud.setBorderColor(borderColor)
                }
            case .drip :
                if let fillColor = color {
                    shapeLayer.ud.setFillColor(fillColor)
                }
            default:
                break
            }
        }
    }

    private var type: UDSectionIndexViewItemPreviewType = .default

    private lazy var titleLabel: UILabel = {
        let lab = UILabel()
        lab.frame = bounds
        lab.textColor = .white
        lab.font = UIFont.boldSystemFont(ofSize: 35)
        lab.adjustsFontSizeToFitWidth = true
        lab.textAlignment = .center
        return lab
    }()

    private lazy var shapeLayer: CAShapeLayer = {
        let x = bounds.width * 0.5
        let y = bounds.height * 0.5
        let radius = bounds.width * 0.5
        let startAngle = CGFloat(Double.pi * 0.25)
        let endAngle = CGFloat(Double.pi * 1.75 )

        let path = UIBezierPath(arcCenter: CGPoint(x: x, y: y), radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)

        let lineX = x * 2 + 10
        let lineY = y
        path.addLine(to: CGPoint(x: lineX, y: lineY))
        path.close()
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = bounds
        shapeLayer.path = path.cgPath
        return shapeLayer
    }()

    private lazy var dripView: UIView = {
        let view = UIView(frame: bounds)
        view.layer.addSublayer(shapeLayer)
        view.addSubview(titleLabel)
        return view
    }()

    private lazy var imageView: UIImageView = {
        let v = UIImageView(frame: bounds)
        v.contentMode = .center
        return v
    }()

    public init(title: String? = nil, type: UDSectionIndexViewItemPreviewType = .default, image: UIImage? = nil) {
        super.init(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
        if let image = image {
            addSubview(imageView)
            imageView.image = image
        }
        self.type = type
        setPreview(title: title)
        shapeLayer.ud.setFillColor(UIColor.ud.color(158, 158, 158, 0.5))
    }

    private func setPreview(title: String?) {
        titleLabel.text = title
        switch type {
        case .default:
            titleLabel.backgroundColor = UIColor.ud.color(158, 158, 158, 0.5)
            titleLabel.layer.cornerRadius = titleLabel.frame.size.width * 0.5
            titleLabel.layer.masksToBounds = true
            titleLabel.shadowColor = .darkGray
            titleLabel.shadowOffset = CGSize(width: 1, height: 1)
            addSubview(titleLabel)
        case .rect:
            titleLabel.backgroundColor = UIColor.cyan
            titleLabel.layer.masksToBounds = true
            titleLabel.layer.cornerRadius = 5
            addSubview(titleLabel)
        case .circle:
            titleLabel.backgroundColor = .clear
            titleLabel.textColor = UIColor.cyan
            titleLabel.layer.cornerRadius = titleLabel.frame.size.width * 0.5
            titleLabel.layer.borderWidth = 5
            titleLabel.layer.borderColor = UIColor.cyan.cgColor
            addSubview(titleLabel)
        case .drip:
            addSubview(dripView)
        case .empty:
            break
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

