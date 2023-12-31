//
//  BTFieldEditSetView.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/9/16.
//  


import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignSwitch
import SKResource
import UIKit

// 带 udSwitch 控件的长条
struct BTFieldWithSwitchItemConfig {
    var topTitleLabel: String?
    var content: String
    var isSelected: Bool = false
}


final class BTFieldWithSwitchItemView: UIView {
    
    struct Metric {
        static var topSpacing: CGFloat = 14
        static var topTitleHeight: CGFloat = 20
        static var spacingBetweenTopTitleAndContent: CGFloat = 2
        static var contentContainerHeight: CGFloat = 52
        
        static var totalHeight: CGFloat {
            return topSpacing + topTitleHeight + spacingBetweenTopTitleAndContent + contentContainerHeight
        }
        
        static var totalHeightWithoutTopTitle: CGFloat {
            return topSpacing + contentContainerHeight
        }
    }
    
    /// switch
    lazy var udSwitch = UDSwitch()
    
    var switchValueChanged: ((Bool) -> Void)? {
        didSet {
            udSwitch.valueChanged = switchValueChanged
        }
    }
    
    /// 顶部按钮
    private lazy var topTitleLabel = UILabel().construct { it in
        it.textColor = UDColor.textPlaceholder
        it.font = .systemFont(ofSize: 14)
    }
    /// 正文容器
    private let contentContainerView = UIView()
    /// 内容正文
    private let contentLabel = UILabel().construct { it in
        it.textColor = UDColor.textTitle
        it.numberOfLines = 0
        it.lineBreakMode = .byWordWrapping
        it.setContentCompressionResistancePriority(.required, for: .horizontal)
        it.font = .systemFont(ofSize: 16)
    }
    
    init(uiConfig: BTFieldWithSwitchItemConfig) {
        super.init(frame: .zero)
        setUpUI(uiConfig: uiConfig)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSelected(_ isSelected: Bool) {
        udSwitch.setOn(isSelected, animated: false)
    }

    func setUpUI(uiConfig: BTFieldWithSwitchItemConfig) {
        addSubview(topTitleLabel)
        addSubview(contentContainerView)
        contentContainerView.addSubview(contentLabel)
        contentContainerView.addSubview(udSwitch)
        contentContainerView.layer.cornerRadius = 10
        contentContainerView.backgroundColor = UDColor.bgFloat
        
        let topTitleLabelHeight = uiConfig.topTitleLabel == nil ? 0 : Metric.topTitleHeight
        
        topTitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.height.equalTo(topTitleLabelHeight)
            make.top.equalToSuperview().offset(Metric.topSpacing)
        }
        
        contentContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topTitleLabel.snp.bottom).offset(Metric.spacingBetweenTopTitleAndContent)
            make.height.equalTo(52)
        }
        contentLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(udSwitch.snp.left).offset(-12)
            make.left.equalToSuperview().offset(16)
        }
        
        udSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.equalTo(48)
            make.height.equalTo(28)
            make.right.equalToSuperview().offset(-16)
        }
        
        topTitleLabel.text = uiConfig.topTitleLabel
        contentLabel.text = uiConfig.content
        setSelected(uiConfig.isSelected)
    }
}
