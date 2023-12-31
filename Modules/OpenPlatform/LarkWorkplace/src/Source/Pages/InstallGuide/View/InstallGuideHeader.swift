//
//  InstallGuideHeader.swift
//  LarkWorkplace
//
//  Created by tujinqiu on 2020/3/13.
//

import UIKit
import UniverseDesignIcon

/// 主要用于展示 skipButton
final class InstallGuideHeader: UIView {

    let hasSafeArea: Bool

    private var isFromOperation: Bool

    private let skipButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitleColor(UIColor.ud.textPlaceholder, for: .normal)
        // font 使用 ud token 初始化
        // swiftlint:disable init_font_with_token
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        // swiftlint:enable init_font_with_token
        btn.backgroundColor = UIColor.clear
        btn.setTitle(BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideInstallSkip, for: .normal)
        btn.setTitleColor(UIColor.ud.textLinkNormal, for: .normal)
        btn.setTitleColor(UIColor.ud.textLinkPressed, for: .highlighted)
        btn.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        btn.addTarget(self, action: #selector(tapSkipBtn(sender:)), for: .touchUpInside)
        return btn
    }()

    private let backButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = UIColor.clear
        btn.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        btn.addTarget(self, action: #selector(tapBackBtn(sender:)), for: .touchUpInside)
        return btn
    }()

    var skipHandler: (() -> Void)?

    init(hasSafeArea: Bool, isFromOperation: Bool) {   // 传入参数控制是初次onBoarding 配置不同的文案
        self.hasSafeArea = hasSafeArea
        self.isFromOperation = isFromOperation
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(skipButton)
        addSubview(backButton)
        // 从「小灯泡」进入后，没有「跳过按钮」，而是用 backbutton 返回
        skipButton.isHidden = isFromOperation
        backButton.isHidden = !isFromOperation
    }

    private func setupConstraints() {
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(10)
            make.width.height.equalTo(24)
        }
        skipButton.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-16)
            let top = hasSafeArea ? 50 : 34
            make.top.equalToSuperview().offset(top)
        }
    }

    @objc
    private func tapSkipBtn(sender: UIButton) {
        skipHandler?()
    }

    @objc
    private func tapBackBtn(sender: UIButton) {
        // 与 skip 一致
        skipHandler?()
    }
}
