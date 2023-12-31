//
//  MinutesExitTranslationView.swift
//  Minutes
//
//  Created by yangyao on 2021/2/26.
//

import UIKit

final class MinutesExitTranslationView: UIView {
    lazy var exitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(BundleI18n.Minutes.MMWeb_G_ExitTranslation, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(exitTranslate), for: .touchUpInside)
        return button
    }()

    private lazy var languageButton: MinutesChooseLanguageButton = {
        let button = MinutesChooseLanguageButton()
        button.addTarget(self, action: #selector(selectLanguage), for: .touchUpInside)
        return button
    }()

    func setLanguage(_ lanaguge: String) {
        languageButton.middleLabel.text = lanaguge
    }

    @objc func exitTranslate() {
        exitTranslateBlock?()
    }

    @objc func selectLanguage() {
        selectLanguageBlock?()
    }

    var exitTranslateBlock: (() -> Void)?
    var selectLanguageBlock: (() -> Void)?

    private var bgColor = UIColor.dynamic(light: UIColor.ud.primaryOnPrimaryFill, dark: UIColor.ud.bgFloatOverlay)
    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.ud.setShadowColor(UIColor.ud.staticBlack.withAlphaComponent(0.08))
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 2
        layer.shadowOpacity = 1.0

        backgroundColor = UIColor.ud.bgFloat
        addSubview(exitButton)
        addSubview(languageButton)
        
        exitButton.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(20)
            maker.top.equalToSuperview().offset(12)
            maker.height.equalTo(19)
            maker.width.lessThanOrEqualToSuperview().multipliedBy(0.5)
        }

        languageButton.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-20)
            maker.centerY.equalTo(exitButton)
            maker.width.lessThanOrEqualToSuperview().multipliedBy(0.5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
