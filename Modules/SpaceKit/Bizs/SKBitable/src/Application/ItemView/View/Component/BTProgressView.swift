//
//  BTProgressView.swift
//  SKBitable
//
//  Created by yinyuan on 2022/11/10.
//

import UIKit
import UniverseDesignColor

final class BTProgressView: UIView {
    
    var progressColor: BTColor? {
        didSet {
            updateProgress()
        }
    }
    
    /// 最大值
    var maxValue: Double = 100 {
        didSet {
            updateProgress()
        }
    }
    
    /// 最小值
    var minValue: Double = 0 {
        didSet {
            updateProgress()
        }
    }
    
    /// 进度值
    var value: Double = 0 {
        didSet {
            updateProgress()
        }
    }
    
    lazy var progressLayer: CALayer = {
        let layer = CALayer()
        layer.ud.setBackgroundColor(UDColor.colorfulBlue)
        layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        layer.masksToBounds = true
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.backgroundColor = UDColor.N90010
        self.layer.masksToBounds = true
        self.layer.addSublayer(progressLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.height / 2
        progressLayer.cornerRadius = self.bounds.height / 2
        updateProgress()
    }
    
    private func updateProgress() {
        guard maxValue > minValue else {
            return
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true) // 禁用切换动画
        let progress = Float(max(min((value - minValue) / (maxValue - minValue), 1), 0))
        
        progressLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.width * CGFloat(progress), height: self.bounds.height)
        
        if let progressColor = progressColor {
            self.progressLayer.backgroundColor = progressColor.color(for: progress).cgColor
        }
        CATransaction.commit()
    }
}
