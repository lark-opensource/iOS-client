//
//  AddRecommandView.swift
//  AnimatedTabBar
//
//  Created by ByteDance on 2023/11/21.
//

import UIKit
import FigmaKit
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignTheme

final class AddRecommandView: UIView {
    
    // 添加按钮点击事件
    var addEvent: (() -> Void)?
    
    /// 是否显示背景
    private var isDisplayBackground: Bool

    private lazy var addButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.addBoldOutlined,
                                            iconColor: UIColor.ud.iconN1,
                                            size: CGSize(width: 16, height: 16)), for: .normal)
        button.setTitle(BundleI18n.AnimatedTabBar.Lark_Core_More_AddApp_Button, for: .normal)
        button.setTitleColor(UIColor.ud.iconN1, for: .normal)
        button.titleLabel?.font = UIFont.ud.title3
        button.backgroundColor = UIColor.ud.bgFloat//UIColor.ud.primaryOnPrimaryFill
        button.layer.cornerRadius = 22
        let spacing: CGFloat = 4
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(addBtnTapped), for: .touchUpInside)
        if !isDarkMode {
            button.smallShadow()
        }
        return button
    }()

    private lazy var gradientMaskLayer: CAGradientLayer = {
        let layer = FKGradientLayer(direction: .bottomToTop, colors: [
            UIColor.black.cgColor,
            UIColor.clear.cgColor
        ])
        layer.locations = [0.4, 1.0]
        return layer
    }()

    /// 渐变背景
    private lazy var backgroundBlueView: UIView = {
        let blurView = VisualBlurView()
        blurView.fillColor = UIColor.ud.bgFloat
        blurView.blurRadius = 60.0
        blurView.fillOpacity = 0.5
        return blurView
    }()

    init(frame: CGRect, isDisplayBackground: Bool = false) {
        self.isDisplayBackground = isDisplayBackground
        super.init(frame: frame)
        if isDisplayBackground {
            self.addSubview(backgroundBlueView)
            backgroundBlueView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        self.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.width.equalTo(102)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        backgroundBlueView.layer.mask = gradientMaskLayer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(event: (() -> Void)? = nil) {
        self.addEvent = event
    }

    var isDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return UDThemeManager.getRealUserInterfaceStyle() == .dark
        } else {
            return false
        }
    }

    @objc
    func addBtnTapped() {
        addEvent?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientMaskLayer.frame = bounds
    }

    /// 下拉系统菜单，切换亮色、暗色模式，"..."颜色不会变，解决办法：实时监听暗色模式变化，动态调整图片
    /// 添加到父视图后，traitCollectionDidChange会立刻执行
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            return
        }
        // UX说DM不加
        if !isDarkMode {
            addButton.smallShadow()
        } else {
            addButton.layer.ud.setShadowColor(UIColor.clear)
        }
    }
}
