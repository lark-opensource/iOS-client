//
//  BTConditionLoadingCell.swift
//  SKBitable
//
//  Created by bytedance on 2022/8/31.
//

import Foundation
import UIKit
import SKUIKit
import SnapKit
import SKFoundation
import SKResource
import UniverseDesignColor

public final class BTConditionLoadingCell: UICollectionViewCell {
    private lazy var containerView = UIView().construct { it in
        it.backgroundColor = UDColor.bgFiller
        it.layer.cornerRadius = 8
    }
    
    private lazy var textView = UITextView().construct { it in
        it.delegate = self
        it.textAlignment = .center
        it.backgroundColor = .clear
        //设为true 在代理里面禁掉所有的交互事件
        it.isEditable = true
        it.isScrollEnabled = false
        //只能设置一种颜色
        it.linkTextAttributes =  [
            NSAttributedString.Key.foregroundColor: UDColor.colorfulBlue
        ]
    }
    
    public var didTapRetry: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }
    
    private func setUpView() {
        contentView.addSubview(containerView)
        self.backgroundColor = .clear
        containerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        containerView.addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview().offset(4)
        }
    }
    
    public func updateText(_ text: String) {
        let attStr = NSMutableAttributedString(string: text)
        //点击超链接
        attStr.addAttribute(NSAttributedString.Key.link, value: "btconditionRetry://", range: (text as NSString).range(of: BundleI18n.SKResource.Bitable_DataReference_TryAgain_Button))
        textView.attributedText = attStr
        textView.textColor = UDColor.textPlaceholder
        textView.font = .systemFont(ofSize: 16)
    }
    
    public func getCellWidth(height: CGFloat) -> CGFloat {
        return textView.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: height)).width + 8
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BTConditionLoadingCell: UITextViewDelegate {
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
     
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.scheme  ==  "btconditionRetry"{
            didTapRetry?()
            return false
        }
        return true
    }
}
