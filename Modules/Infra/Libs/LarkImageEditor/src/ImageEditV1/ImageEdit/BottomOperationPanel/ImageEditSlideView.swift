//
//  ImageEditSlideView.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/8/3.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

protocol ImageEditSlideViewDelegate: AnyObject {
    func sliderDidChangeValue(_ sliderView: ImageEditSlideView, from oldValue: Int, to newValue: Int)
}

final class ImageEditSlideView: UIView {
    var hasEverChangedValue = false

    private let maxValue: Float
    private let minValue: Float
    private var defaultValue: Float { return (maxValue + minValue) / 2 }

    private let currentValueLabel = UILabel()
    private let currentValueBgView = UIView()
    private var currentValueBgViewCenterX: Constraint?
    private let slider = UISlider()

    weak var delegate: ImageEditSlideViewDelegate?

    init(maxValue: Float, minValue: Float) {
        self.maxValue = maxValue
        self.minValue = minValue
        super.init(frame: CGRect.zero)

        addSubview(currentValueBgView)
        addSubview(slider)

        currentValueBgView.isHidden = true
        currentValueBgView.backgroundColor = UIColor.ud.bgFloat
        currentValueBgView.layer.masksToBounds = true
        currentValueBgView.layer.cornerRadius = 4
        currentValueBgView.snp.makeConstraints { (make) in
            make.width.equalTo(38)
            make.height.equalTo(23)
            currentValueBgViewCenterX = make.centerX.equalToSuperview().offset(0).constraint
            make.bottom.equalTo(slider.snp.top).offset(-4)
        }

        currentValueBgView.addSubview(currentValueLabel)
        currentValueLabel.font = UIFont.systemFont(ofSize: 14)
        currentValueLabel.textColor = UIColor.ud.textTitle
        currentValueLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        slider.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        slider.minimumValue = minValue
        slider.maximumValue = maxValue
        slider.value = defaultValue
        slider.setThumbImage(Resources.edit_slider, for: .normal)
        slider.setMinimumTrackImage(Resources.edit_slider_bg_light, for: .normal)
        slider.setMaximumTrackImage(Resources.edit_slider_bg_dark, for: .normal)
        slider.snp.makeConstraints { (make) in
            make.top.equalTo(22)
            make.left.equalToSuperview().offset(97)
            make.right.equalToSuperview().offset(-97)
        }

        snp.makeConstraints { (make) in
            make.height.equalTo(50)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshSettings() {
        let value = Int(ceil(slider.value))
        delegate?.sliderDidChangeValue(self, from: value, to: value)
    }

    @objc
    private func valueChanged() {
        hasEverChangedValue = true

        let newValue: Int = Int(ceil(slider.value))

        let trackRect = slider.trackRect(forBounds: slider.bounds)
        let thumRect = slider.thumbRect(forBounds: slider.bounds, trackRect: trackRect, value: slider.value)
        let leftDistance = trackRect.left + thumRect.left + thumRect.width / 2
        let offset = leftDistance - slider.frame.width / 2
        currentValueBgViewCenterX?.update(offset: offset)

        if let text = currentValueLabel.text, let oldValue = Int(text) {
            if newValue != oldValue {
                currentValueBgView.isHidden = false
                NSObject.cancelPreviousPerformRequests(withTarget: self)
                perform(#selector(hideCurrentValueBgView), with: nil, afterDelay: 1.0)
                delegate?.sliderDidChangeValue(self, from: oldValue, to: newValue)
            }
        }

        let diff = newValue - Int(ceil(defaultValue))
        currentValueLabel.text = ((diff > 0) ? "+" : "") + "\(diff)"
    }

    @objc
    private func hideCurrentValueBgView() {
        currentValueBgView.isHidden = true
    }
}
