//
//  ViewToolBar.swift
//  SKBitable
//
//  Created by X-MAN on 2023/8/29.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon

fileprivate final class RecordCountIndicator: UIView {
    private lazy var recordCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textCaption
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    private lazy var indicator: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(indicator)
        addSubview(recordCountLabel)
        indicator.snp.makeConstraints { make in
            make.size.equalTo(14)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        recordCountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalTo(indicator.snp.leading)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(text: String, image: UIImage?) {
        recordCountLabel.text = text
        indicator.image = image
    }
}

final class ViewToolBar: UIView {
    
    private let statMargin: CGFloat = 16
    private let actionMargin: CGFloat = 6
    private let iconWidth: CGFloat = 44
    private let iconHeight: CGFloat = 36
        
    var statActionClick: (() -> Void)?
    var firstClick: (() -> Void)?
    var secondClick: (() -> Void)?
    var thirdClick: (() -> Void)?
    
    lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0.5, y: 0) // 渐变起点位于视图顶部中央
        layer.endPoint = CGPoint(x: 0.5, y: 1) // 渐变终点位于视图底部中央
        return layer
    }()
    
    private lazy var indicator: RecordCountIndicator = {
        let indicator = RecordCountIndicator(frame: .zero)
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(statTap))
        indicator.addGestureRecognizer(tapGes)
        return indicator
    }()
    
    private lazy var firstButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(firstButtonClick), for: .touchUpInside)
        return button
    }()
    
    private lazy var secondButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(secondButtonClick), for: .touchUpInside)
        return button
    }()
    
    private lazy var thirdButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(thirdButtonClick), for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        clipsToBounds = true
        layer.insertSublayer(gradientLayer, at: 0)
        updateDarkMode()
        
        addSubview(indicator)
        addSubview(thirdButton)
        addSubview(secondButton)
        addSubview(firstButton)
        thirdButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-actionMargin)
            make.centerY.equalToSuperview()
            make.width.equalTo(iconWidth)
            make.height.equalTo(iconHeight)
        }
        secondButton.snp.makeConstraints { make in
            make.right.equalTo(thirdButton.snp.left)
            make.centerY.equalToSuperview()
            make.width.equalTo(iconWidth)
            make.height.equalTo(iconHeight)
        }
        firstButton.snp.makeConstraints { make in
            make.right.equalTo(secondButton.snp.left)
            make.centerY.equalToSuperview()
            make.width.equalTo(iconWidth)
            make.height.equalTo(iconHeight)
        }
        indicator.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(statMargin)
            make.height.equalToSuperview()
            make.right.lessThanOrEqualTo(firstButton.snp.left)
        }
        
    }
    
    func setData(_ model: ViewToolBarData) {
        let iconSize = CGSize(width: 18, height: 18)
        let tintColor = UDColor.iconN2
        if let text = model.stat?.text {
            var image = model.stat?.icon?.image
            image = image?.ud.resized(to: CGSize(width: 14, height: 14))
            image = image?.ud.withTintColor(UDColor.iconN3)
            indicator.set(text: text, image: image)
            indicator.isHidden = false
        } else {
            indicator.isHidden = true
        }
        
        if let menu = model.toolMenu.safe(index: 2) {
            thirdButton.isHidden = false
            var icon = menu.icon?.image?.ud.resized(to: iconSize)
            if menu.icon?.style == nil || menu.icon?.style == .normal {
                icon = icon?.ud.withTintColor(tintColor)
            }
            thirdButton.setImage(icon, for: .normal)
        } else {
            thirdButton.isHidden = true
        }
        if let menu = model.toolMenu.safe(index: 1) {
            secondButton.isHidden = false
            var icon = menu.icon?.image?.ud.resized(to: iconSize)
            if menu.icon?.style == nil || menu.icon?.style == .normal {
                icon = icon?.ud.withTintColor(tintColor)
            }
            secondButton.setImage(icon, for: .normal)
        } else {
            secondButton.isHidden = true
        }
        if let menu = model.toolMenu.safe(index: 0) {
            firstButton.isHidden = false
            var icon = menu.icon?.image?.ud.resized(to: iconSize)
            if menu.icon?.style == nil || menu.icon?.style == .normal {
                icon = icon?.ud.withTintColor(tintColor)
            }
            firstButton.setImage(icon, for: .normal)
        } else {
            firstButton.isHidden = true
        }
        if thirdButton.isHidden && secondButton.isHidden {
            firstButton.snp.remakeConstraints { make in
                make.right.equalToSuperview().offset(-actionMargin)
                make.centerY.equalToSuperview()
                make.width.equalTo(iconWidth)
                make.height.equalTo(iconHeight)
            }
        } else if thirdButton.isHidden && !secondButton.isHidden {
            secondButton.snp.remakeConstraints { make in
                make.right.equalToSuperview().offset(-actionMargin)
                make.centerY.equalToSuperview()
                make.width.equalTo(iconWidth)
                make.height.equalTo(iconHeight)
            }
            
            firstButton.snp.remakeConstraints { make in
                make.right.equalTo(secondButton.snp.left)
                make.centerY.equalToSuperview()
                make.width.equalTo(iconWidth)
                make.height.equalTo(iconHeight)
            }
        }
    }
    
    @objc
    private func firstButtonClick() {
        firstClick?()
    }
    
    @objc
    private func secondButtonClick() {
        secondClick?()
    }
    
    @objc
    private func thirdButtonClick() {
        thirdClick?()
    }
    
    @objc
    private func statTap() {
        statActionClick?()
    }
    
    private func updateGradientLayerFrame() {
        // 最小 maxWindowWidth，不然宽窄变化时渐变色跟不上动画
        gradientLayer.frame = CGRectMake(0, 0, max(self.layer.bounds.width, maxWindowWidth), self.layer.bounds.height)
    }
    
    var maxWindowWidth: CGFloat = 1366 {
        didSet {
            updateGradientLayerFrame()
        }
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        updateGradientLayerFrame()
    }
    
    func updateDarkMode() {
        gradientLayer.ud.setColors([BTContainer.Constaints.viewCatalogueBottomColor, UDColor.bgBody])
    }
    
}
