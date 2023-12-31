//
//  final class LanguagePickerActionPanelHeader.swift
//  LarkAudio
//
//  Created by 白镜吾 on 2023/2/16.
//

import UIKit
import Foundation
import UniverseDesignIcon
import UniverseDesignColor

protocol LanguagePickerHeaderDelegate: AnyObject {
    func closePanel()
}

final class LanguagePickerHeader: UIView {
    private lazy var closeBtn = UIButton()
    private lazy var titleLabel = UILabel()

    weak var delegate: LanguagePickerHeaderDelegate?

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.backgroundColor = UIColor.ud.bgBody
        setCloseBtn()
        addSubview(closeBtn)
        closeBtn.snp.makeConstraints { make in
            make.size.equalTo(22)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }

        titleLabel.text = BundleI18n.LarkAudio.Lark_IM_AudioToTextSelectLangugage_Title
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.center.equalToSuperview()
        }
    }

    // MARK: - 头部样式设置函数
    // 左按钮设置为关闭
    func setCloseBtn() {
        closeBtn.setImage(UDIcon.getIconByKey(.closeSmallOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        closeBtn.addTarget(self, action: #selector(close(_:)), for: .touchUpInside)
    }

    @objc
    func close(_ sender: UIButton) {
        delegate?.closePanel()
    }
}
