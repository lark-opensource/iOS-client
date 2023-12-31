//
//  ThemeSettingViewController.swift
//  TangramUIComponentDev
//
//  Created by 袁平 on 2021/7/1.
//

import Foundation
import UIKit
import UniverseDesignFont
import UniverseDesignTheme

@available(iOS 13.0, *)
class ThemeSettingViewController: UIViewController {
    let darkMode = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Theme Setting"
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(darkMode)
        darkMode.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        darkMode.addTarget(self, action: #selector(onThemeChanged), for: .valueChanged)
        darkMode.isOn = UDThemeManager.userInterfaceStyle == .dark

        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.text = "是否开启DarkMode"
        label.font = UIFont.ud.title4
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(darkMode.snp.top).offset(-12)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    @objc
    func onThemeChanged() {
        UDThemeManager.setUserInterfaceStyle(darkMode.isOn ? .dark : .light)
    }
}
