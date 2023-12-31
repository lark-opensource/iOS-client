//
//  ImageEditorSlideView.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/7/4.
//

import Foundation
import UIKit
import SnapKit

protocol ImageEditorSlideViewDelegate: AnyObject {
    func sliderDidChangeValue(to newValue: Int)
    func sliderTimerTicked()
}

final class ImageEditorSlideView: UIView {
    private let slider = ImageEditorSlider()
    private let sliderGradientLayer = CAGradientLayer()

    weak var delegate: ImageEditorSlideViewDelegate?

    var currentValue: Float { slider.value }
    var defaultValue: Float { (slider.minimumValue + slider.maximumValue) / 2 }

    init(maxValue: Float, minValue: Float) {
        super.init(frame: CGRect.zero)

        sliderGradientLayer.ud.setColors([UIColor.ud.N1000.withAlphaComponent(0).alwaysLight,
                                          UIColor.ud.N1000.withAlphaComponent(0.3).alwaysLight],
                                         bindTo: self)
        layer.addSublayer(sliderGradientLayer)

        addSubview(slider)
        slider.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        slider.minimumValue = minValue
        slider.maximumValue = maxValue
        slider.value = (minValue + maxValue) / 2
        slider.setThumbImage(Resources.edit_slider_v2, for: .normal)
        slider.setMinimumTrackImage(Resources.edit_slider_min_v2, for: .normal)
        slider.setMaximumTrackImage(Resources.edit_slider_max_v2, for: .normal)
        slider.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(23)
            make.width.equalTo(302)
            make.height.equalTo(32)
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        sliderGradientLayer.bounds = .init(x: 0, y: 0, width: bounds.width, height: 120)
        sliderGradientLayer.position = .init(x: bounds.width / 2, y: bounds.height - 60)
    }

    @objc
    private func valueChanged() {
        let newValue: Int = Int(ceil(slider.value))
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(hideCurrentValueBgView), with: nil, afterDelay: 1.0)
        delegate?.sliderDidChangeValue(to: newValue)
    }

    @objc
    private func hideCurrentValueBgView() {
        delegate?.sliderTimerTicked()
    }
}

// internal apis
extension ImageEditorSlideView {
    func setSliderValue(_ value: CGFloat) { slider.setValue(Float(value), animated: true) }
}

extension ImageEditorSlideView {
    private final class ImageEditorSlider: UISlider {
        override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
            return super.thumbRect(forBounds: bounds,
                                   trackRect: .init(x: rect.minX - 5,
                                                    y: rect.minY - 5,
                                                    width: rect.width + 10,
                                                    height: rect.height + 10),
                                   value: value)
        }
    }
}
