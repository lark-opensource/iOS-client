//
//  UDRateView.swift
//  UniverseDesignRate
//
//  Created by 姚启灏 on 2021/2/24.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignFont

public protocol UDRateViewDelegate: AnyObject {
    func rateView(_ rateView: UDRateView, didSelectedStep step: Double)
}

public struct UDRateViewConfig {

    /// Drag Gesture Step
    public enum DragStep {
        /// none
        case none
        /// Follow the gesture step
        case normal
        /// 1 step
        case full
        /// 0.5 step
        case half
    }

    /// Drag Gesture Step
    public var dragStep: DragStep
    /// RateView Item Size
    public var itemSize: CGSize
    /// RateView Item Count
    public var itemCount: Int
    /// RateView Item Image
    public var itemImage: UIImage
    /// RateView Item Scale
    public var itemScale: CGFloat
    /// Item Default Color
    public var defaultColor: UIColor
    /// Selected Color
    public var selectedColor: UIColor

    /// init
    public init(dragStep: DragStep = .none,
                itemImage: UIImage = UIImage(),
                itemCount: Int = 5,
                itemSize: CGSize = CGSize(width: 44, height: 44),
                itemScale: CGFloat = 1,
                defaultColor: UIColor = UDRateColorTheme.rateStarUnselectedColor,
                selectedColor: UIColor = UDRateColorTheme.rateStarSelectedColor) {
        self.dragStep = dragStep
        self.itemImage = itemImage
        self.itemSize = itemSize
        self.itemCount = itemCount
        self.itemScale = itemScale
        self.defaultColor = defaultColor
        self.selectedColor = selectedColor
    }
}

public class UDRateView: UIView {
    public weak var delegate: UDRateViewDelegate?

    public private(set) var config = UDRateViewConfig()

    private var buttomView: UIView = UIView()

    private var rateStackView: UIStackView = UIStackView()

    private var contentView: UIView = UIView()

    private var rateViews: [UIView] = []

    private var customView: UIView?

    private var dragGesture: UIPanGestureRecognizer?
    private var tapGesture: UITapGestureRecognizer?

    private var selecedLoactionX: CGFloat = 0

    public override init(frame: CGRect) {
        super.init(frame: frame)

        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Update Rate Config
    /// - Parameter config:
    public func update(config: UDRateViewConfig) {
        self.config = config
        self.updateUI()
    }

    /// Set Rate Text
    /// - Parameters:
    ///   - text: content text
    ///   - textFont: text font
    ///   - textColor: text color
    ///   - textWidth: text width
    public func setRateText(_ text: String,
                            textFont: UIFont = UDFont.caption1,
                            textColor: UIColor = UDRateColorTheme.rateLabelColor,
                            textWidth: Int? = nil) {
        guard !text.isEmpty else {
            customView?.removeFromSuperview()
            customView = nil
            return
        }

        if let textLabel = customView as? UILabel {
            textLabel.text = text
            textLabel.snp.makeConstraints { (make) in
                make.top.equalTo(contentView.snp.bottom).offset(12)
                make.bottom.equalToSuperview().offset(-10)
                make.centerX.equalToSuperview()
                make.left.greaterThanOrEqualTo(12)
                make.right.lessThanOrEqualTo(12)
                if let width = textWidth {
                    make.width.equalTo(width)
                }
            }
        } else {
            customView?.removeFromSuperview()
            let textLabel = UILabel()
            self.customView = textLabel
            self.addSubview(textLabel)
            textLabel.text = text
            textLabel.textAlignment = .center
            textLabel.font = textFont
            textLabel.textColor = textColor
            textLabel.numberOfLines = 0
            textLabel.lineBreakMode = .byWordWrapping
            textLabel.lineBreakMode = .byTruncatingTail

            textLabel.snp.makeConstraints { (make) in
                make.top.equalTo(contentView.snp.bottom).offset(12)
                make.bottom.equalToSuperview().offset(-10)
                make.centerX.equalToSuperview()
                make.left.greaterThanOrEqualTo(12)
                make.right.lessThanOrEqualTo(12)
                if let width = textWidth {
                    make.width.equalTo(width)
                }
            }
        }
    }

    /// Rate Custom View
    /// - Parameter view: Custom View
    public func setRateCustomView(_ view: UIView?) {
        customView?.removeFromSuperview()

        guard let view = view else {
            customView = nil
            return
        }

        self.customView = view
        self.addSubview(view)
        view.snp.remakeConstraints { (make) in
            make.top.equalTo(contentView.snp.bottom).offset(12)
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }
    }

    private func initView() {
        contentView.addSubview(buttomView)
        self.addSubview(contentView)

        rateStackView.spacing = 0
        rateStackView.axis = .horizontal
        rateStackView.distribution = .fillEqually
        rateStackView.alignment = .fill

        contentView.clipsToBounds = true
        contentView.mask = rateStackView

        let width = config.itemSize.width * CGFloat(config.itemCount)
        let height = config.itemSize.height
        contentView.snp.makeConstraints { (make) in
            make.width.equalTo(width)
            make.height.equalTo(height)
            make.centerX.equalToSuperview()
            make.left.top.greaterThanOrEqualToSuperview()
            make.bottom.right.lessThanOrEqualToSuperview()
        }

        let dragGesture = UIPanGestureRecognizer(target: self,
                                                 action: #selector(dragRateView(gesture:)))

        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(tapRateView(gesture:)))

        self.dragGesture = dragGesture
        self.tapGesture = tapGesture
        self.addGestureRecognizer(dragGesture)
        self.addGestureRecognizer(tapGesture)
        updateUI()
    }

    @objc
    private func dragRateView(gesture: UIGestureRecognizer) {
        let locationX = gesture.location(in: contentView).x
        let width = contentView.frame.width

        switch gesture.state {
        case .ended:
            guard locationX > 0, locationX < width else {
                return
            }
            var length = config.itemSize.width
            switch config.dragStep {
            case .full:
                let position = Int(locationX / length) + 1
                let time = locationX.truncatingRemainder(dividingBy: length) / length * 0.5
                selecedLoactionX = CGFloat(position) * length - width
                UIView.animate(withDuration: TimeInterval(time)) {
                    self.buttomView.frame.origin = CGPoint(x: self.selecedLoactionX, y: 0)
                }
                self.delegate?.rateView(self, didSelectedStep: Double(position))
            case .half:
                length /= 2
                let position = Int(locationX / length) + 1
                let time = locationX.truncatingRemainder(dividingBy: length) / length * 0.5
                selecedLoactionX = CGFloat(position) * length - width
                UIView.animate(withDuration: TimeInterval(time)) {
                    self.buttomView.frame.origin = CGPoint(x: self.selecedLoactionX, y: 0)
                }
                self.delegate?.rateView(self, didSelectedStep: Double(position) / 2)
            case .normal:
                selecedLoactionX = length - width
                buttomView.frame.origin = CGPoint(x: selecedLoactionX, y: 0)
                self.delegate?.rateView(self, didSelectedStep: Double(locationX / config.itemSize.width) + 1)
            case .none:
                break
            }
        default:
            if locationX < 0 {
                buttomView.frame.origin = CGPoint(x: -width, y: 0)
            } else if locationX > width {
                buttomView.frame.origin = CGPoint(x: 0, y: 0)
            } else {
                let originX = locationX - width
                self.buttomView.frame.origin = CGPoint(x: originX, y: 0)
            }
        }
    }

    @objc
    private func tapRateView(gesture: UIGestureRecognizer) {
        let locationX = gesture.location(in: contentView).x
        let width = contentView.frame.width
        guard locationX > 0, locationX < width else {
            return
        }

        let position = Int(locationX / config.itemSize.width) + 1
        selecedLoactionX = CGFloat(position) * self.config.itemSize.width - width
        self.buttomView.frame.origin = CGPoint(x: selecedLoactionX, y: 0)

        for index in 1...position {
            guard let rateMaskView = rateViews[index - 1].mask as? UIImageView else { return }
            rateMaskView.transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
        }

        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.75,
                       initialSpringVelocity: 0,
                       options: [],
                       animations: {
                            for index in 1...position {
                                guard let rateMaskView = self.rateViews[index - 1].mask as? UIImageView else { return }
                                rateMaskView.transform = CGAffineTransform(scaleX: self.config.itemScale,
                                                                           y: self.config.itemScale)
                            }
                       },
                       completion: nil)

        self.delegate?.rateView(self, didSelectedStep: Double(Int(locationX / config.itemSize.width)) + 1)
    }

    private func updateUI() {
        let width = config.itemSize.width * CGFloat(config.itemCount)
        let height = config.itemSize.height

        buttomView.frame = CGRect(x: -width, y: 0, width: width, height: height)
        buttomView.backgroundColor = config.selectedColor

        rateStackView.frame = CGRect(x: 0, y: 0, width: width, height: height)

        contentView.backgroundColor = config.defaultColor
        contentView.snp.updateConstraints { (make) in
            make.width.equalTo(width)
            make.height.equalTo(height)
        }

        switch config.dragStep {
        case .none:
            dragGesture?.isEnabled = false
        case .full, .half, .normal:
            dragGesture?.isEnabled = true
        }

        for rateView in rateViews {
            guard let rateMaskView = rateView.mask as? UIImageView else { return }
            rateMaskView.image = config.itemImage
            rateMaskView.transform = CGAffineTransform(scaleX: self.config.itemScale, y: self.config.itemScale)
        }

        updateRateView()
    }

    private func updateRateView() {
        while config.itemCount != rateStackView.arrangedSubviews.count {
            if config.itemCount > rateStackView.arrangedSubviews.count {
                let rateMaskView = UIImageView(image: config.itemImage)
                rateMaskView.contentMode = .center
                let rateView = UIView()
                rateView.frame.size = config.itemSize
                rateMaskView.frame.size = config.itemSize
                rateMaskView.transform = CGAffineTransform(scaleX: self.config.itemScale, y: self.config.itemScale)
                rateView.mask = rateMaskView
                rateView.backgroundColor = .white
                rateViews.append(rateView)
                rateStackView.addArrangedSubview(rateView)
            } else if config.itemCount < rateStackView.arrangedSubviews.count {
                if let rateView = rateViews.last {
                    rateStackView.removeArrangedSubview(rateView)
                    rateViews.removeLast()
                }
            }
        }
    }
}
