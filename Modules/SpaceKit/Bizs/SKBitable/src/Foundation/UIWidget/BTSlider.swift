//
//  BTSlider.swift
//  SKBitable
//
//  Created by yinyuan on 2022/11/21.
//

import UIKit
import SKResource
import UniverseDesignColor

protocol BTSliderDelegate: AnyObject {
    
    func sliderValueChanged(slider: BTSlider, value: Double)
    
}

final class BTSlider: UISlider {
    weak var delegate: BTSliderDelegate?
    
    var progressColor: BTColor? {
        didSet {
            updateColor()
        }
    }
    
    /// 步进值，大于 0，设置有效值时需要确保 isContinuous 为 true，否则将无法正常表现步进效果
    private var step: Double = 1
    private var _currentValue: Double? {
        didSet {
            // 更新颜色
            updateColor()
        }
    }
    
    /// 当前值，支持步进值
    var currentValue: Double {
        get {
            return _currentValue ?? minValue
        }
        set {
            if _currentValue != newValue {
                _currentValue = newValue
            }
            transformValues()
        }
    }
    
    var _minValue: Double? {
        didSet {
            updateColor()
        }
    }
    var minValue: Double {
        get {
           return _minValue ?? 0
        }
        set {
            _minValue = newValue
            step = max(1, (maxValue - minValue) / Double(maximumValue)).rounded()
            transformValues()
        }
    }
    
    var _maxValue: Double? {
        didSet {
            updateColor()
        }
    }
    var maxValue: Double {
        get {
           return _maxValue ?? 100
        }
        set {
            _maxValue = newValue
            step = max(1, (maxValue - minValue) / Double(maximumValue)).rounded()
            transformValues()
        }
    }
    
    /// UISlider 只能支持 float 值设置，这里通过如下转换支持 double 值设置
    private func transformValues() {
        // double 无损区间转换为 float 单位
        let range: Double = maxValue - minValue
        guard range > 0 else {
            return
        }
        
        let valueRange: Double
        if currentValue < minValue {
            valueRange = 0
        } else if currentValue > maxValue {
            valueRange = range
        } else {
            valueRange = currentValue - minValue
        }
        
        let progress: Float = Float(valueRange / range)
        setValue(progress * maximumValue, animated: false)
    }
    
    private func transformSliderValue() -> Double {
        
        let range: Double = maxValue - minValue
        guard range > 0 else {
            return 0
        }
        
        let progress: Double = Double(value) / Double(maximumValue)
        return (progress * range) + minValue
    }
    
    /// 范围是否过大，过大的范围就不需要步进效果了
    private var rangeTooLarge: Bool {
        return maxValue - minValue > Double(maximumValue)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.setThumbImage(BundleResources.SKResource.Bitable.slider_thumb, for: [.normal])
        self.addTarget(self, action: #selector(sliderUpdate(slider:)), for: .valueChanged)
        
        minimumValue = 0
        maximumValue = 80
        
        self.maximumTrackTintColor = UDColor.N90010
        updateColor()
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let tBounds = super.trackRect(forBounds: bounds)
        let tHeight = 10.0
        return CGRect(x: tBounds.origin.x, y: tBounds.origin.y + (tBounds.size.height - tHeight) / 2, width: tBounds.size.width, height: tHeight)
    }
    
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let tSize = CGSize(width: 20, height: 36)
        let tBounds = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        return CGRect(x: tBounds.origin.x + (tBounds.size.width - tSize.width) / 2, y: tBounds.origin.y + (tBounds.size.height - tSize.height) / 2, width: tSize.width, height: tSize.height)
    }
    
    /// 找到距离最近的步进值
    private func getNearStepValue(_ value: Double) -> Double {
        guard step > 0 else {
            return value
        }
        
        if value < minValue + (step - abs(minValue).truncatingRemainder(dividingBy: step)) / 2 {
            return minValue
        } else if value >= maxValue - abs(maxValue).truncatingRemainder(dividingBy: step) / 2 {
            return maxValue
        } else {
            return Double(lround(value / step)) * step
        }
    }
    
    @objc
    func sliderUpdate(slider: UISlider) {
        
        let tValue: Double = transformSliderValue()
        let nearValue = getNearStepValue(tValue)
        if !rangeTooLarge {
            if currentValue < nearValue, tValue >= nearValue {
                self.currentValue = nearValue
                delegate?.sliderValueChanged(slider: self, value: currentValue)
            } else if currentValue > nearValue, tValue <= nearValue {
                self.currentValue = nearValue
                delegate?.sliderValueChanged(slider: self, value: currentValue)
            } else {
                self.currentValue = currentValue
            }
        } else {
            // 表示范围过大，不需要去做进度规整的操作了
            if _currentValue != nearValue {
                _currentValue = nearValue
                delegate?.sliderValueChanged(slider: self, value: currentValue)
            }
        }
    }
    
    private func updateColor() {
        guard maxValue > minValue else {
            return
        }
        if let progressColor = progressColor {
            let progress = max(min((currentValue - minValue) / (maxValue - minValue), 1), 0)
            self.minimumTrackTintColor = progressColor.color(for: Float(progress))
        } else {
            self.minimumTrackTintColor = UDColor.primaryContentDefault
        }
    }
}
