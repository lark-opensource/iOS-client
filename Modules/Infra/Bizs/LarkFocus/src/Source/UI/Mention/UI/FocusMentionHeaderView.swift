//
//  FocusMentionTitleView.swift
//  LarkFocus
//
//  Created by 白镜吾 on 2023/1/9.
//

import UIKit
import Foundation
import UniverseDesignIcon

protocol FocusMentioHeaderViewDelegate: AnyObject {
    func closePanel()
}

final class FocusMentioHeaderView: UIView {
    private lazy var closeBtn  = UIButton()
    private lazy var titleLabel = UILabel()

    weak var delegate: FocusMentioHeaderViewDelegate?
    
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
            make.height.equalTo(22)
            make.width.equalTo(22)
            make.bottom.equalToSuperview().offset(-8)
            make.leading.equalToSuperview().offset(16)
        }

        titleLabel.text = BundleI18n.LarkFocus.Lark_Profile_StatusNoteSelectMentions_Title
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints{ make in
            make.height.equalTo(24)
            make.top.equalToSuperview().offset(7)
            make.bottom.equalToSuperview().offset(-8)
            make.centerX.equalToSuperview()
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
