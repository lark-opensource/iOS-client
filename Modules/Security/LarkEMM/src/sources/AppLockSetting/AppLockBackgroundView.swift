//
//  AppLockBackgroundView.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/8/15.
//

import UIKit
import UniverseDesignColor

final private class AppLockGradientView: UIView {
    
    final private class ALayer: CAGradientLayer {
        
        override init(layer: Any) {
            super.init(layer: layer)
            commonInit()
        }
        
        override init() {
            super.init()
            commonInit()
        }
        
        required init?(coder: NSCoder) {
            return nil
        }
        
        func commonInit() {
            opacity = 0.8
            colors = [
                UDColor.rgb(0x374A44).cgColor,
                UDColor.rgb(0x3A4A5B).cgColor,
                UDColor.rgb(0x283442).cgColor
            ]
            locations = [0, 0.44, 1]
            startPoint = CGPoint(x: 0.5, y: 0.25)
            endPoint = CGPoint(x: 0.5, y: 0.75)
        }
    }
    
    override class var layerClass: AnyClass { ALayer.self }
}

// swiftlint:disable:next line_length
// https://www.figma.com/file/iTfvILLfZCdjEpZPCfAAT1/%F0%9F%96%A5-%E7%BB%88%E7%AB%AF%E5%AE%89%E5%85%A8---%E7%B2%98%E8%B4%B4%E4%BF%9D%E6%8A%A4%E3%80%81%E6%96%87%E4%BB%B6%E5%AE%89%E5%85%A8%E6%A3%80%E6%B5%8B%E7%AD%89?type=design&node-id=4000-251&mode=design&t=NHLptoDFHltPRby5-0
final class AppLockBackgroundView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.masksToBounds = true
        backgroundColor = UDColor.rgb(0x5A5A5A)
        
        let gradientView = AppLockGradientView(frame: bounds)
        addSubview(gradientView)
        gradientView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let bgView = UIView(frame: bounds)
        bgView.frame = bounds
        bgView.backgroundColor = UDColor.staticBlack.withAlphaComponent(0.28)
        addSubview(bgView)
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let imageView = UIImageView(frame: bounds)
        imageView.clipsToBounds = true
        let image = BundleResources.LarkEMM.app_lock_bg_icon.resizableImage(withCapInsets: .zero, resizingMode: .tile)
        imageView.image = image
        addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
}
