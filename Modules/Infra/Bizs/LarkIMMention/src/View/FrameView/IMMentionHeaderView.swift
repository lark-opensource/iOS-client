//
//  IMMentionHeaderView.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/21.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon

final class IMMentionHeaderView: UIView {
    var lineView = UIView()
    var closeBtn  = UIButton()
    var titleLabel = UILabel()
    var multiBtn = UIButton()
    var isCloseBtn = true
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = UIColor.ud.bgBody
        addSubview(lineView)
        lineView.snp.makeConstraints {
            $0.height.equalTo(12)
            $0.top.leading.trailing.equalToSuperview()
        }
        let line = UIView()
        line.backgroundColor = UIColor.ud.N300
        line.layer.cornerRadius = 2
        lineView.addSubview(line)
        line.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(4)
            $0.width.equalTo(40)
        }
        
        changeToCloseBtn()
        addSubview(closeBtn)
        closeBtn.snp.makeConstraints {
            $0.height.equalTo(22)
            $0.width.equalTo(22)
            $0.bottom.equalToSuperview().offset(-8)
            $0.leading.equalToSuperview().offset(16)
        }
        
        titleLabel.text = BundleI18n.LarkIMMention.Lark_IM_SelectWhatToMention_Title
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        addSubview(titleLabel)
        
        multiBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        multiClear()
        multiBtn.setTitle(BundleI18n.LarkIMMention.Lark_Mention_Multiselect_Mobile, for: .normal)
        multiBtn.setTitle(BundleI18n.LarkIMMention.Lark_Legacy_Sure, for: .selected)
        multiBtn.setTitle(BundleI18n.LarkIMMention.Lark_Legacy_Sure, for: [.selected, .highlighted])
        multiBtn.setContentHuggingPriority(UILayoutPriority(rawValue: 500), for: .horizontal)
        addSubview(multiBtn)
        multiBtn.snp.makeConstraints {
            $0.height.equalTo(22)
            $0.bottom.equalToSuperview().offset(-8)
            $0.trailing.equalToSuperview().offset(-16)
            $0.width.lessThanOrEqualTo(90)
           
        }
        titleLabel.snp.makeConstraints{
            $0.height.equalTo(24)
            $0.bottom.equalToSuperview().offset(-8)
            $0.centerX.equalToSuperview()
        }
    }
    
    // MARK: - 头部样式设置函数
    // 左按钮设置为关闭
    func changeToCloseBtn() {
        closeBtn.setImage(UDIcon.getIconByKey(.closeSmallOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        isCloseBtn = true
    }
    
    // 左按钮设置为返回
    func changeToLeftBtn() {
        closeBtn.setImage(UDIcon.getIconByKey(.leftSmallCcmOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        isCloseBtn = false
    }
    
    // 多选设置为初始样式
    func multiClear() {
        multiBtn.isUserInteractionEnabled = true
        multiBtn.alpha = 1
        multiBtn.setTitleColor(UIColor.ud.textTitle, for: .normal)
        multiBtn.setTitleColor(UIColor.ud.textTitle, for: .selected)
    }
    
    // 多选能够点击
    func multiEnableClick() {
        multiBtn.isUserInteractionEnabled = true
        multiBtn.alpha = 1
        multiBtn.setTitleColor(UIColor.ud.textLinkHover, for: .normal)
        multiBtn.setTitleColor(UIColor.ud.textLinkHover, for: .selected)
    }
}
