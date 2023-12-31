//
//  InlineAIVoiceContentHeaderView.swift
//  LarkAIInfra
//
//  Created by ByteDance on 2023/9/24.
//

import Foundation
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon

final class InlineAIVoiceContentHeaderView: UIView {
    
    /// 点击关闭回调
    var onClickClose: (() -> Void)?
    
    /// tabs切换回调
    var tabIndexChanged: ((Int) -> Void)? {
        get { tabsView.indexChanged }
        set { tabsView.indexChanged = newValue }
    }
    
    private lazy var closeBtn: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = UDColor.bgBody
        let image = UDIcon.upBoldOutlined.getResizeImageBySize(.init(width: 20, height: 20))?.withRenderingMode(.alwaysTemplate)
        btn.setImage(image, for: .normal)
        btn.tintColor = UDColor.iconN2
        btn.addTarget(self, action: #selector(onClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UDColor.textTitle
        label.textAlignment = .center
        return label
    }()
    
    private lazy var tabsView: InlineAIVoiceTabsView = {
        let tabs = InlineAIVoiceTabsView()
        return tabs
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        
        closeBtn.layer.masksToBounds = true
        closeBtn.layer.cornerRadius = 32 / 2
        self.addSubview(closeBtn)
        closeBtn.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(32)
        }
        
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(closeBtn.snp.trailing)
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
        titleLabel.isHidden = true
        
        self.addSubview(tabsView)
        tabsView.snp.makeConstraints {
            $0.leading.equalTo(closeBtn.snp.trailing)
            $0.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }
        tabsView.isHidden = true
    }
    
    @objc
    private func onClick() {
        onClickClose?()
    }
}

extension InlineAIVoiceContentHeaderView {
    
    func setTitle(_ title: String?) {
        titleLabel.isHidden = false
        tabsView.isHidden = true
        titleLabel.text = title
    }
    
    func setTabTitles(_ titles: [String]) {
        titleLabel.isHidden = true
        tabsView.isHidden = false
        tabsView.setTitles(titles)
    }
}
