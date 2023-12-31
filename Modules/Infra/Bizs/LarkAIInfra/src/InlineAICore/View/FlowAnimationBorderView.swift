//
//  FlowAnimationBorderView.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/6/7.
//  


import UIKit
import UniverseDesignColor
import FigmaKit

class FlowAnimationBorderView: UIView {
    
    static let defaultBorderWidth = CGFloat(2)
    
    class ColorView: UIImageView {

        var inAnimation = false

        private let imgSize = CGSize(width: 100, height: 100)

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.contentMode = .scaleToFill
            if let color = UDColor.AIDynamicLine(ofSize: imgSize) {
                self.image = UIColor.ud.image(with: color, size: imgSize, scale: UIScreen.main.scale)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func startAnimate() {
            inAnimation = true
            let rotationAnimatioin = CABasicAnimation(keyPath: "transform.rotation.z")
            rotationAnimatioin.toValue = Double.pi * 2.0
            rotationAnimatioin.duration = 3
            rotationAnimatioin.repeatCount = Float.greatestFiniteMagnitude
            rotationAnimatioin.isRemovedOnCompletion = false
            self.layer.add(rotationAnimatioin, forKey: "rotationAnimatioin")
        }

        func stopAnimate() {
            inAnimation = false
            self.layer.removeAllAnimations()
        }
    }
    
    var colorView = ColorView(frame: .zero)
    var topMaskView = UIView()
    var borderWidth: CGFloat = 0

    convenience init(borderWidth: CGFloat, backgroundColor: UIColor, cornerRadius: CGFloat) {
        self.init(frame: .zero)
        self.borderWidth = borderWidth
        addSubview(colorView)
        addSubview(topMaskView)
        colorView.isHidden = true
        topMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(borderWidth)
        }
        clipsToBounds = true
        self.backgroundColor = backgroundColor
        topMaskView.clipsToBounds = true
        topMaskView.backgroundColor = backgroundColor

        layer.ux.setSmoothCorner(radius: cornerRadius, corners: .allCorners, smoothness: .natural)
        let cornerRadiusDelta: CGFloat = 1
        topMaskView.layer.ux.setSmoothCorner(radius: cornerRadius + cornerRadiusDelta, corners: .allCorners, smoothness: .max)
    }
                   
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAuroraAnimate() {
        guard colorView.inAnimation == false else { return }
        LarkInlineAILogger.info("start boardr animation")
        topMaskView.snp.updateConstraints { make in
            make.edges.equalToSuperview().inset(borderWidth)
        }
        colorView.isHidden = false
        updateLayout()
        colorView.startAnimate()
    }
    
    func stopAnimate() {
        guard colorView.inAnimation else { return }
        LarkInlineAILogger.info("[aurora] stop boardr animation")
        colorView.isHidden = true
        self.layoutIfNeeded()
        colorView.stopAnimate()
        topMaskView.snp.updateConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }
    
    func updateLayout() {
        let size = self.bounds.size
        guard size.width > 0 else {
            LarkInlineAILogger.warn("[aurora] animation colorView layout fail")
            return
        }
        let length = sqrt(pow(size.width, 2) + pow(size.height, 2)) + 2
        colorView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: length, height: length))
        }
    }
}
