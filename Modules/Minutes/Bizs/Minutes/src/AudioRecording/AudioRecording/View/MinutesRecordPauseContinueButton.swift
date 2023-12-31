//
//  MinutesRecordPauseContinueButton.swift
//  Minutes
//
//  Created by yangyao on 2021/3/15.
//

import UIKit
import UniverseDesignIcon

class MinutesRecordPauseContinueButton: UIView {
    var isPausing: Bool = false {
        didSet {
            pauseButton.isHidden = isPausing
            continueButton.isHidden = !isPausing
        }
    }
    var pressCallback: (() -> Void)?

    private lazy var pauseButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.pauseFilled, iconColor: UIColor.ud.functionInfoContentDefault, size: CGSize(width: 30, height: 28)), for: .normal)

        button.layer.cornerRadius = 22
        button.addTarget(self, action: #selector(onBtnPress), for: .touchUpInside)
        return button
    }()

    private lazy var continueButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(BundleI18n.Minutes.MMWeb_G_Resume, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.3), for: .highlighted)
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.layer.cornerRadius = 22
        button.addTarget(self, action: #selector(onBtnPress), for: .touchUpInside)
        return button
    }()

    @objc func onBtnPress() {
        pressCallback?()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(pauseButton)
        addSubview(continueButton)

        layer.cornerRadius = 26
        layer.borderWidth = 2
        layer.ud.setBorderColor(UIColor.ud.lmTokenRecordingBtnBorderGray)

        pauseButton.snp.makeConstraints { (maker) in
            maker.edges.equalTo(continueButton)
        }

        continueButton.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(4)
            maker.right.equalToSuperview().offset(-4)
            maker.top.equalToSuperview().offset(4)
            maker.bottom.equalToSuperview().offset(-4)
            maker.height.equalTo(44)
            maker.width.equalTo(132)
        }

        continueButton.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
