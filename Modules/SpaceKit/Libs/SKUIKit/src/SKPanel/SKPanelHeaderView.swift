//
// Created by duanxiaochen.7 on 2021/9/1.
// Affiliated with SKUIKit.
//
// Description:

import Foundation
import UIKit
import SKFoundation
import SnapKit
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor

public final class SKPanelHeaderView: UIView {

    private lazy var closeButton = UIButton().construct { it in
        it.setImage(UDIcon.closeSmallOutlined, withColorsForStates: [
            (UDColor.iconN1, .normal),
            (UDColor.iconN3, .highlighted),
            (UDColor.iconDisabled, .disabled)
        ])
        it.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
    }

    private lazy var titleView = UILabel().construct { it in
        // 先不接入 UDFont，避免跟随字体设计放大
        it.font = .systemFont(ofSize: 17, weight: .medium)
        it.textColor = UDColor.textTitle
        it.textAlignment = .center
        // 降低标题的压缩优先级，避免超长标题影响计算内容的合适宽度
        it.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    public private(set) lazy var accessoryButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        return button
    }()

    private lazy var bottomSeparator = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }

    public override init(frame: CGRect) {
        super.init(frame: .zero)
        // 背景颜色设置在 header 上是为了照顾 containerView 存在向上阴影的情形，在这个场景下 containerView 不能设置圆角，所以圆角只能设置在 header 上，那颜色也只能设置在 header 上
        // 如果把阴影放到 header 上也不是不行，但是外面可能需要显式将阴影去除，不太优雅
        // 如果业务方需要 header 有不同的颜色，可以在 init 之后单独设置 backgroundColor
        backgroundColor = UDColor.bgBody
        layer.cornerRadius = 12
        layer.maskedCorners = .top

        addSubview(closeButton)
        addSubview(titleView)
        addSubview(accessoryButton)
        addSubview(bottomSeparator)

        closeButton.snp.makeConstraints { make in
            make.leading.equalTo(safeAreaLayoutGuide.snp.leading).inset(16)
            make.top.equalToSuperview().inset(14)
            make.width.height.equalTo(24)
        }
        
        titleView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(closeButton)
            make.leading.greaterThanOrEqualTo(closeButton.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }

        accessoryButton.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.centerY.equalTo(titleView)
            make.left.equalTo(titleView.snp.right).offset(8)
        }
        
        bottomSeparator.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
    }
    
    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }
    
    public var titleCenterY: ConstraintItem {
        titleView.snp.centerY
    }

    public var titleLineBreakMode: NSLineBreakMode {
        get {
            return titleView.lineBreakMode
        }
        set {
            titleView.lineBreakMode = newValue
        }
    }

//    public func setTitleScaleTextToFit(_ scales: Bool) {
//        if scales {
//            titleView.adjustsFontSizeToFitWidth = true
//            titleView.minimumScaleFactor = 14 / 17
//        } else {
//            titleView.adjustsFontSizeToFitWidth = false
//        }
//    }
    
    public func setTitle(_ text: String?) {
        titleView.text = text
    }
    
    public func setCloseButtonAction(_ action: Selector, target: Any?) {
        closeButton.addTarget(target, action: action, for: .touchUpInside)
    }
    
    public func toggleCloseButton(isHidden: Bool) {
        closeButton.isHidden = isHidden
    }

    public func toggleSeparator(isHidden: Bool) {
        bottomSeparator.isHidden = isHidden
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
