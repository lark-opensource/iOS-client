//
//  ZoomSlider.swift
//  LarkZoomable
//
//  Created by bytedance on 2020/11/5.
//

import Foundation
import UIKit
import UniverseDesignFont

public final class ZoomSlider: UISlider {

    private let zoomLevels = Zoom.allCases
    private var previousValue: Float?
    private var tapGesture: UITapGestureRecognizer!

    /// Called when slider value changed.
    public var onZoomChanged: ((Zoom) -> Void)?

    /// The slider’s current zoom value.
    public var zoom: Zoom {
        get {
            return zoomLevels[Int(value)]
        }
        set {
            let newValue = Float(zoomLevels.firstIndex(where: { $0 == newValue })!)
            value = newValue
        }
    }

    /// The slider’s current value in float.
    public override var value: Float {
        didSet {
            guard previousValue != value else { return }
            if previousValue != nil {
                onZoomChanged?(zoomLevels[Int(value)])
            }
            previousValue = value
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        setupSubviews()
        setupAppearance()
        setupZoomStep()
    }

    private func setupSubviews() {}

    private func setupAppearance() {
        isMultipleTouchEnabled = false
        minimumTrackTintColor = .clear
        maximumTrackTintColor = .clear
        guard !zoomLevels.isEmpty else { return }
        minimumValue = 0
        maximumValue = Float(zoomLevels.count - 1)
    }

    private func setupZoomStep() {
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(zoomSliderDidTapped(_:)))
        addGestureRecognizer(tapGesture)
        addTarget(self, action: #selector(zoomSliderDidChangeValue(_:)), for: .valueChanged)
        addTarget(self, action: #selector(zoomSliderDidTouchDown(_:)), for: .touchDown)
        addTarget(self, action: #selector(zoomSliderDidTouchUp(_:)), for: .touchUpInside)
    }

    @objc
    private func zoomSliderDidTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: gesture.view)
        let thumbWidth = thumbRect(forBounds: .zero, trackRect: .zero, value: minimumValue).width
        let percentage = (point.x - thumbWidth / 2) / (frame.size.width - thumbWidth)
        let indexValue = Int((percentage * CGFloat(zoomLevels.count - 1)).rounded(.toNearestOrAwayFromZero))
        zoom = zoomLevels[min(zoomLevels.count - 1, max(0, indexValue))]
    }

    @objc
    private func zoomSliderDidChangeValue(_ sender: UISlider) {
        let roundedValue = sender.value.rounded(.toNearestOrAwayFromZero)
        sender.value = roundedValue
    }

    @objc
    private func zoomSliderDidTouchDown(_ sender: UISlider) {
        tapGesture.isEnabled = false
    }

    @objc
    private func zoomSliderDidTouchUp(_ sender: UISlider) {
        tapGesture.isEnabled = true
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        // Create bezier path
        let path = UIBezierPath()
        path.lineWidth = 1
        UIColor(red: 196 / 255.0, green: 196 / 255.0, blue: 196 / 255.0, alpha: 1).set()
        // Calculate parameters
        let rulerHeight: CGFloat = 9
        let thumbDiameter = thumbRect(forBounds: .zero, trackRect: .zero, value: minimumValue).width
        let rulerWidth = rect.width - thumbDiameter
        // Draw x-axis
        path.move(to: CGPoint(x: thumbDiameter / 2, y: rect.height / 2))
        path.addLine(to: CGPoint(x: thumbDiameter / 2 + rulerWidth, y: rect.height / 2))
        path.stroke()
        // Draw y-axis
        guard zoomLevels.count > 1 else { return }
        for i in 0...zoomLevels.count {
            let xCoordinate = thumbDiameter / 2 + rulerWidth * CGFloat(i) / CGFloat(zoomLevels.count - 1)
            let yCoordinate = (rect.height - rulerHeight) / 2
            path.move(to: CGPoint(x: xCoordinate, y: yCoordinate))
            path.addLine(to: CGPoint(x: xCoordinate, y: yCoordinate + rulerHeight))
            path.stroke()
        }
    }

}
