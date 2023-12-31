//
//  WikiSliderView.swift
//  SKWikiV2
//
//  Created by majie.7 on 2022/7/28.
//

import Foundation
import SKUIKit
import UIKit
import UniverseDesignColor
import UniverseDesignIcon

protocol TreeViewHorizonIndicatorDelegate: AnyObject {
    func slideAction(_ value: CGFloat)
}

class TreeViewHorizonIndicator: UIView {
    weak var delegate: TreeViewHorizonIndicatorDelegate?
    private lazy var slider: WikiSlider = {
        let slider = WikiSlider()
        let image = WikiSliderImage(frame: CGRect(x: 0, y: 0, width: 230, height: 3)).transformImage()
        slider.isEnabled = false
        slider.setThumbImage(image, for: .normal)
        slider.minimumTrackTintColor = .clear
        slider.maximumTrackTintColor = .clear
        slider.setValue(0, animated: false)
        return slider
    }()
    
    var value: CGFloat {
        CGFloat(slider.value)
    }
    
    // 判断是否有滑动偏移
    var isSwiped: Bool {
        return slider.value != 0
    }
    // 记录当前视图水平滑动的offset，在手势触发时get, 结束时set，仅用于手势回调
    public var swipeDistance = CGFloat()
    // 当前一屏cell，超出屏幕宽度最大的offset
    var maxHorizonOffset = CGFloat()
    // 当前水平滑动过程中实时的offset
    var currentHorizonOffset = CGFloat()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.addSubview(slider)
        
        slider.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
    }
    
    // 设置百分比，同时按百分比滑动
    func setValue(value: CGFloat) {
        slider.setValue(Float(value), animated: true)
        delegate?.slideAction(value)
    }
    
    func updateSwipDistance(_ distance: CGFloat) {
        swipeDistance = distance
    }
    
    func updateCurrentHorizonOffset(_ offset: CGFloat) {
        currentHorizonOffset = offset
    }
    
    func updateIndicatorWidth(indicatorPercent: CGFloat) {
        if indicatorPercent > 1 { return }
        let indicatorWidth = frame.width * indicatorPercent
        let image = WikiSliderImage(frame: CGRect(x: 0, y: 0, width: indicatorWidth, height: 3)).transformImage()
        slider.setThumbImage(image, for: .normal)
    }
    
    func updateMaxHorizonOffset(_ offset: CGFloat) {
        // 未横向滑动时根据屏幕变化取一屏当前的最大offset
        if !isSwiped {
            maxHorizonOffset = offset
        } else if isSwiped, offset > maxHorizonOffset {
            // 横向滑动后，上下滑动时取比当前大的offset，防止跳变
            maxHorizonOffset = offset
        }
        
        let percent = maxHorizonOffset > 0 ? Float(swipeDistance / maxHorizonOffset) : 0
        slider.setValue(percent, animated: true)
    }
}

class WikiSlider: UISlider {
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var customBounds = super.trackRect(forBounds: bounds)
        customBounds.size.height = 3
        return customBounds
    }
}

class WikiSliderImage: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = UDColor.N500
        self.layer.cornerRadius = 1.5
        self.layer.masksToBounds = true
    }
    
    public func transformImage() -> UIImage {
        let render = UIGraphicsImageRenderer(size: frame.size)
        return render.image { context in
            layer.render(in: context.cgContext)
        }
    }
}
