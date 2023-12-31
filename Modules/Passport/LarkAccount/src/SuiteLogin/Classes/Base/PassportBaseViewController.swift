//
//  PassportBaseViewController.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/7/6.
//

import Foundation
import LarkUIKit
import UniverseDesignTheme
import SnapKit
import UniverseDesignColor

class PassportBaseViewController: UIViewController {

    lazy var topGradientMainCircle = GradientCircleView()
    lazy var topGradientSubCircle = GradientCircleView()
    lazy var topGradientRefCircle = GradientCircleView()
    lazy var blurEffectView = UIVisualEffectView()

    override func viewDidLoad() {
        view.backgroundColor = UIColor.ud.bgLogin
        makeBackgroundView()
        super.viewDidLoad()
    }

}

// MARK: - UI
extension PassportBaseViewController {

    func makeBackgroundView() {
        var isDarkModeTheme: Bool = false
        if #available(iOS 13.0, *) {
            isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }

        self.view.addSubview(topGradientMainCircle)
        self.view.addSubview(topGradientSubCircle)
        self.view.addSubview(topGradientRefCircle)
        topGradientMainCircle.snp.makeConstraints { (make) in
            make.left.equalTo(-40.0 / 375 * view.frame.width)
            make.top.equalTo(0.0)
            make.width.equalToSuperview().multipliedBy(120.0 / 375)
            make.height.equalToSuperview().multipliedBy(96.0 / 812)
        }
        topGradientSubCircle.snp.makeConstraints { (make) in
            make.left.equalTo(-16.0 / 375 * view.frame.width)
            make.top.equalTo(-112.0 / 812 * view.frame.height)
            make.width.equalToSuperview().multipliedBy(228.0 / 375)
            make.height.equalToSuperview().multipliedBy(220.0 / 812)
        }
        topGradientRefCircle.snp.makeConstraints { (make) in
            make.left.equalTo(150.0 / 375 * view.frame.width)
            make.top.equalTo(-22.0 / 812 * view.frame.height)
            make.width.equalToSuperview().multipliedBy(136.0 / 375)
            make.height.equalToSuperview().multipliedBy(131.0 / 812)
        }
        self.view.addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        setGradientLayerColors(isDarkModeTheme: isDarkModeTheme)
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            // 如果当前设置主题一致，则不需要切换资源
            return
        }

        setGradientLayerColors(isDarkModeTheme: UDThemeManager.getRealUserInterfaceStyle() == .dark)
    }

    private func setGradientLayerColors(isDarkModeTheme: Bool) {
        topGradientMainCircle.setColors(color: UIColor.ud.rgb("#1456F0"), opacity: 0.16)
        topGradientSubCircle.setColors(color: UIColor.ud.rgb("#336DF4"), opacity: 0.16)
        topGradientRefCircle.setColors(color: UIColor.ud.rgb("#2DBEAB"), opacity: 0.10)
        blurEffectView.effect = isDarkModeTheme ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .light)
    }
}

