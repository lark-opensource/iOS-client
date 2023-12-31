//
//  BTLightingIconView.swift
//  SKBitable
//
//  Created by zhysan on 2022/11/23.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import SnapKit
import ByteWebImage
import SKFoundation
import SKUIKit

final class BTLightingIconView: UIView {
    
    // MARK: - public funcs
    
    /// main icon image
    var image: UIImage? {
        set {
            if let color = imageTintColor {
                imageView.image = newValue?.ud.withTintColor(color)
            } else {
                imageView.image = newValue
            }
        }
        get {
            imageView.image
        }
    }
    
    /// Whether to display the lightning badge
    var showLighting: Bool = false {
        didSet {
            lightingView.isHidden = !showLighting
            if showLighting {
                imageView.layer.mask = bgMaskLayer
                setNeedsLayout()
            } else {
                imageView.layer.mask = nil
            }
        }
    }
    
    /// main image tint color
    var imageTintColor: UIColor? = nil {
        didSet {
            if let image = imageView.image, let color = imageTintColor {
                imageView.image = image.ud.withTintColor(color)
            }
        }
    }
    
    /// lightning badge tint color
    var lightingTintColor: UIColor = UDColor.iconN2 {
        didSet {
            lightingView.lightingColor = lightingTintColor
        }
    }
    
    
    /// update lighting icon at once
    /// - Parameters:
    ///   - image: image content
    ///   - showLighting: display the lightning badge or not
    ///   - tintColor: set imageTintColor and lightingTintColor at same time if it's not nil
    func update(_ image: UIImage, showLighting: Bool, tintColor: UIColor? = nil) {
        if let color = tintColor {
            imageTintColor = color
            lightingTintColor = color
        }
        self.image = image
        self.showLighting = showLighting
    }
    
    /// update image with url, and set gray style if needed after image loaded.
    /// using imageUrl will not support lighting badge
    func update(_ imageUrl: String, grayScale: Bool){
        self.showLighting = false
        self.imageTintColor = nil
        imageView.bt.setLarkImage(.default(key: imageUrl), completion:  { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                DocsLogger.info("set url image success: \(imageUrl.encryptToShort)")
                if grayScale {
                    self.image = self.image?.docs_grayscale()
                }
            case .failure(let error):
                self.image = UDIcon.bitableunknowOutlined
                DocsLogger.error("set url image failed: \(imageUrl.encryptToShort)", error: error)
            }
        })
    }
    
    
    /// set imageTintColor and lightingTintColor at same time
    func updateTintColor(_ color: UIColor) {
        imageTintColor = color
        lightingTintColor = color
    }
    
    // MARK: - private vars
    
    private let imageView: UIImageView = {
        UIImageView()
    }()
    
    private let lightingView: LightingView = {
        LightingView()
    }()
    
    private let bgMaskLayer: CAShapeLayer = {
        CAShapeLayer()
    }()
    
    // MARK: - life cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        addSubview(lightingView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        lightingView.snp.makeConstraints { make in
            make.width.height.equalToSuperview().multipliedBy(0.5)
            make.right.equalToSuperview().offset(Const.lightingExtraX)
            make.bottom.equalToSuperview().offset(Const.lightingExtraY)
        }
    
        lightingView.lightingColor = lightingTintColor
        lightingView.isHidden = !showLighting
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - override
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !lightingView.isHidden else {
            return
        }
        
        let scaleW = bounds.width / 20.0
        let scaleH = bounds.height / 20.0
        
        let path = lightingStoke12x14BezierPath()
        
        // convert to 14x14 in 20x20 container
        path.apply(CGAffineTransformMakeTranslation(1.0, 0))
        
        // scale to mxm in nxn container
        path.apply(CGAffineTransformMakeScale(scaleW, scaleH))
        
        // align stoke mask to lighting icon
        let offsetX = 8 * scaleW + Const.lightingExtraX
        let offsetY = 8 * scaleH + Const.lightingExtraY
        path.apply(CGAffineTransformMakeTranslation(offsetX, offsetY))
        
        // reverse
        path.append(UIBezierPath(rect: bounds))
        
        bgMaskLayer.path = path.cgPath
    }
}

/// generate lighting icon 8x8 bezier path
private func lighting8x8BezierPath() -> UIBezierPath {
    // origin ux svg convert: 8x8
    let path = UIBezierPath()
    path.move(to: CGPoint(x: 4.1, y: 0.3))
    path.addCurve(to: CGPoint(x: 5, y: 0.6), controlPoint1: CGPoint(x: 4.4, y: 0), controlPoint2: CGPoint(x: 5, y: 0.2))
    path.addLine(to: CGPoint(x: 5, y: 3.1))
    path.addLine(to: CGPoint(x: 6.7, y: 3.2))
    path.addCurve(to: CGPoint(x: 7, y: 4.1), controlPoint1: CGPoint(x: 7.1, y: 3.3), controlPoint2: CGPoint(x: 7.3, y: 3.8))
    path.addLine(to: CGPoint(x: 4.1, y: 7.7))
    path.addCurve(to: CGPoint(x: 3.2, y: 7.3), controlPoint1: CGPoint(x: 3.8, y: 8), controlPoint2: CGPoint(x: 3.2, y: 7.8))
    path.addLine(to: CGPoint(x: 3.2, y: 4.9))
    path.addLine(to: CGPoint(x: 1.6, y: 4.7))
    path.addCurve(to: CGPoint(x: 1.2, y: 3.9), controlPoint1: CGPoint(x: 1.2, y: 4.7), controlPoint2: CGPoint(x: 1, y: 4.2))
    path.addLine(to: CGPoint(x: 4.1, y: 0.3))
    path.close()
    return path
}

/// generate lighting stoke icon 12x14 bezier path
private func lightingStoke12x14BezierPath() -> UIBezierPath {
    // origin ux svg convert: 12x14
    let path = UIBezierPath()
    path.move(to: CGPoint(x: 5, y: 1.4))
    path.addLine(to: CGPoint(x: 5, y: 1.4))
    path.addLine(to: CGPoint(x: 1.4, y: 5.9))
    path.addCurve(to: CGPoint(x: 2.8, y: 9.4), controlPoint1: CGPoint(x: 0.3, y: 7.2), controlPoint2: CGPoint(x: 1.1, y: 9.3))
    path.addLine(to: CGPoint(x: 3.5, y: 9.5))
    path.addLine(to: CGPoint(x: 3.5, y: 11.2))
    path.addCurve(to: CGPoint(x: 7.2, y: 12.6), controlPoint1: CGPoint(x: 3.5, y: 13.1), controlPoint2: CGPoint(x: 6, y: 14))
    path.addLine(to: CGPoint(x: 7.3, y: 12.5))
    path.addLine(to: CGPoint(x: 10.9, y: 8))
    path.addCurve(to: CGPoint(x: 9.4, y: 4.5), controlPoint1: CGPoint(x: 12, y: 6.7), controlPoint2: CGPoint(x: 11.2, y: 4.7))
    path.addLine(to: CGPoint(x: 8.7, y: 4.5))
    path.addLine(to: CGPoint(x: 8.7, y: 2.8))
    path.addCurve(to: CGPoint(x: 5, y: 1.4), controlPoint1: CGPoint(x: 8.7, y: 0.9), controlPoint2: CGPoint(x: 6.3, y: -0.1))
    path.close()
    return path
}

private final class LightingView: UIView {
    var lightingColor: UIColor = UDColor.iconN1 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let path = lighting8x8BezierPath()
        // scale to nxn
        let scaleW = rect.width / 8.0
        let scaleH = rect.height / 8.0
        path.apply(CGAffineTransformMakeScale(scaleW, scaleH))
        path.lineWidth = 1.0
        lightingColor.setFill()
        path.fill()
    }
}

private struct Const {
    static let lightingExtraX: CGFloat = 2.0
    static let lightingExtraY: CGFloat = 1.0
}
