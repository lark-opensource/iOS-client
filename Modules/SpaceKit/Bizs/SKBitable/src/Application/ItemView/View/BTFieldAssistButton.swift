//
//  BTFieldAssistButton.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/9/23.
//  


import SKUIKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignLoading
import UniverseDesignIcon

final class BTFieldAssistButton: BTHighlightableButton {
    struct Metric {
        static var iconSize: CGSize = CGSize(width: 18, height: 18)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.normalBackgroundColor = UDColor.bgBody
        self.highlightBackgroundColor = UDColor.fillHover
        self.setTitleColor(UDColor.textTitle, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        self.widthInset = -BTFieldLayout.Const.containerPadding
        self.heightInset = -BTFieldLayout.Const.containerPadding
        self.layer.cornerRadius = 4
        self.clipsToBounds = true
    }
    
    func config(image: UIImage?, color: UIColor = UDColor.iconN2) {
        self.setImage(image?.ud.withTintColor(color).ud.resized(to: Metric.iconSize), for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class BTFieldEditButton: BTHighlightableButton {
    
    // MARK: - public
    
    var isLoading: Bool = false {
        didSet {
            updateLoading()
        }
    }
    
    var editType: BTFieldEditButtonType = .none {
        didSet {
            updateUI()
        }
    }
    
    // MARK: - life cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        imageView?.superview?.addSubview(spin)
        updateLoading()
        
        layer.addSublayer(dashBorderLayer)
        dashBorderLayer.ud.setStrokeColor(UDColor.lineBorderCard)
        
        updateUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateLoading()
        
        spin.frame = imageView?.frame ?? .zero
        
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height * 0.5)
        dashBorderLayer.path = path.cgPath
    }
    
    // MARK: - private
    
    private struct Const {
        static let iconTextSpace = 4.0
    }
    
    private let dashBorderLayer = CAShapeLayer().construct { it in
        it.strokeColor = UDColor.lineBorderCard.cgColor
        it.fillColor = nil
        it.lineWidth = 1.0
        it.lineDashPattern = [3, 2]
    }
    
    private lazy var spin: UDSpin = {
        let spinSize = BTFV2Const.Dimension.valueAssistBtnInternalSize
        let c1 = UDSpinIndicatorConfig(size: spinSize, color: UDColor.primaryContentDefault)
        let c2 = UDSpinConfig(indicatorConfig: c1, textLabelConfig: nil)
        return UDSpin(config: c2)
    }()
    
    private func updateUI() {
        updateVisibility()
        updateTapArea()
        updateImageHighlight()
        updateBorder()
        updateCornerRadius()
        updateBackgroundColor()
        updateImage()
        updateTitle()
        updateContentAligment()
        updateLoading()
        setNeedsLayout()
    }
    
    private func updateVisibility() {
        switch editType {
        case .none:
            isHidden = true
        case .dashLine, .fixedTopRightRoundedButton, .centerVerticallyWithIconText, .emptyRoundDashButton, .placeholder:
            isHidden = false
        }
    }
    
    private func updateImageHighlight() {
        switch editType {
        case .none, .dashLine, .placeholder:
            adjustsImageWhenHighlighted = false
        case .fixedTopRightRoundedButton, .centerVerticallyWithIconText, .emptyRoundDashButton:
            adjustsImageWhenHighlighted = true
        }
    }
    
    private func updateBorder() {
        switch editType {
        case .none, .dashLine, .fixedTopRightRoundedButton, .centerVerticallyWithIconText, .placeholder:
            dashBorderLayer.isHidden = true
        case .emptyRoundDashButton:
            dashBorderLayer.isHidden = false
        }
    }
    
    private func updateCornerRadius() {
        switch editType {
        case .none, .dashLine, .centerVerticallyWithIconText, .placeholder:
            layer.cornerRadius = 0
            layer.masksToBounds = false
        case .emptyRoundDashButton:
            // 这里不 maskToBounds，不然圆形虚线边框会被裁切
            layer.cornerRadius = bounds.size.height * 0.5
            layer.masksToBounds = false
        case .fixedTopRightRoundedButton:
            layer.cornerRadius = 4.0
            layer.masksToBounds = true
        }
    }
    
    private func updateBackgroundColor() {
        switch editType {
        case .none, .dashLine, .emptyRoundDashButton, .centerVerticallyWithIconText, .placeholder:
            normalBackgroundColor = .clear
            highlightBackgroundColor = .clear
            disabledBackgroundColor = .clear
        case .fixedTopRightRoundedButton:
            normalBackgroundColor = UDColor.N900.withAlphaComponent(0.05)
            highlightBackgroundColor = UDColor.N900.withAlphaComponent(0.10)
            disabledBackgroundColor = UDColor.N900.withAlphaComponent(0.02)
        }
    }
    
    private func updateImage() {
        switch editType {
        case .none, .placeholder:
            setImage(nil, for: .normal)
        case .dashLine:
            let sizeVal = BTFV2Const.Dimension.valueAssistBtnInternalSize
            let imageSize = CGSize(width: sizeVal, height: sizeVal)
            let image = UDIcon.reduceOutlined.ud.withTintColor(UDColor.iconN3).ud.resized(to: imageSize)
            setImage(image, for: .normal)
        case .emptyRoundDashButton(let image), .fixedTopRightRoundedButton(let image):
            let sizeVal = BTFV2Const.Dimension.valueAssistBtnInternalSize
            let imageSize = CGSize(width: sizeVal, height: sizeVal)
            let image = image.ud.withTintColor(UDColor.iconN3).ud.resized(to: imageSize)
            setImage(image, for: .normal)
        case .centerVerticallyWithIconText(let image, _):
            let sizeVal = BTFV2Const.Dimension.valueAssistBtnInternalSize
            let imageSize = CGSize(width: sizeVal, height: sizeVal)
            let image = image.ud.withTintColor(UDColor.iconN1).ud.resized(to: imageSize)
            setImage(image, for: .normal)
        }
    }
    
    private func updateTitle() {
        switch editType {
        case .none, .dashLine, .emptyRoundDashButton, .fixedTopRightRoundedButton:
            setTitle(nil, for: .normal)
            contentEdgeInsets = .zero
            titleEdgeInsets = .zero
        case .centerVerticallyWithIconText(_, let text):
            setTitleColor(UDColor.textTitle, for: .normal)
            titleLabel?.font = UDFont.body0
            setTitle(text, for: .normal)
            contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: Const.iconTextSpace)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: Const.iconTextSpace, bottom: 0, right: -Const.iconTextSpace)
        case .placeholder(let text):
            setTitleColor(UDColor.textPlaceholder, for: .normal)
            titleLabel?.font = UDFont.body0
            setTitle(text, for: .normal)
        }
    }
    
    private func updateContentAligment() {
        switch editType {
        case .none, .dashLine:
            contentHorizontalAlignment = .left
        case .fixedTopRightRoundedButton, .emptyRoundDashButton, .centerVerticallyWithIconText:
            contentHorizontalAlignment = .center
        case .placeholder:
            contentHorizontalAlignment = .right
        }
    }
    
    private func updateTapArea() {
        switch editType {
        case .fixedTopRightRoundedButton:
            // 固定右上的点击按钮，加大按钮的点击区域
            widthInset = -BTFV2Const.Dimension.valueAssistHSpace
            heightInset = -BTFV2Const.Dimension.valueAssistHSpace
        case .none, .dashLine, .emptyRoundDashButton, .centerVerticallyWithIconText, .placeholder:
            widthInset = 0
            heightInset = 0
        }
    }
    
    private func updateLoading() {
        if case .placeholder = editType {
            return
        }
        spin.isHidden = !isLoading
        imageView?.isHidden = isLoading
    }
}
