//
//  MyAIQuickActionLoadingView.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/12/2.
//

import Foundation
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignTheme

/// 快捷指令加载动画
public final class MyAIQuickActionLoadingView: UIView {
    private let loadingIcon: UIImageView
    private let iconColor: UIColor

    public init(frame: CGRect, iconColor: UIColor) {
        self.iconColor = iconColor
        // 添加loading动画
        self.loadingIcon = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: 21.auto(), height: 5.auto())))
        super.init(frame: frame)
        // 替换图片
        self.resetAnimationImages()
        self.loadingIcon.animationDuration = 1
        self.loadingIcon.contentMode = .scaleAspectFit
        self.addSubview(self.loadingIcon)
        self.loadingIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 下拉系统菜单，切换亮色、暗色模式，"..."颜色不会变，解决办法：实时监听暗色模式变化，动态调整图片
    /// 添加到父视图后，traitCollectionDidChange会立刻执行
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // animationImages被赋值后，isAnimating会重置为false，我们需要提前获取
        let needStartAnimating = self.loadingIcon.isAnimating
        // 替换图片
        self.resetAnimationImages()
        // 启动动画
        if needStartAnimating { self.loadingIcon.startAnimating() }
    }

    /// 替换图片
    private func resetAnimationImages() {
        // 这里需要取明确的颜色，UIImage.ud.colorize有bug
        var currColor = self.iconColor.alwaysLight
        if #available(iOS 13.0, *) { currColor = (UDThemeManager.getRealUserInterfaceStyle() == .dark) ? self.iconColor.alwaysDark : self.iconColor.alwaysLight }
        // animationImages用UIImage.withTintColor不生效，我们需要ud.colorize重新绘制一次
        self.loadingIcon.animationImages = [BundleResources.myai_loading_icon_01.ud.colorize(color: currColor),
                                            BundleResources.myai_loading_icon_02.ud.colorize(color: currColor),
                                            BundleResources.myai_loading_icon_03.ud.colorize(color: currColor),
                                            BundleResources.myai_loading_icon_04.ud.colorize(color: currColor),
                                            BundleResources.myai_loading_icon_05.ud.colorize(color: currColor),
                                            BundleResources.myai_loading_icon_06.ud.colorize(color: currColor)]
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        // 为了保证一定会执行动画，这里添加到视图后就启动动画
        if newSuperview != nil { self.loadingIcon.startAnimating() }
    }
}
