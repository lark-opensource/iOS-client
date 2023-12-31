//
//  FeedCellQuoteView.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/5/19.
//  

import UIKit
import SnapKit
import Foundation
import SKFoundation
import UniverseDesignColor

/// FeedCell上的引文视图
class FeedCellQuoteView: UIView {
    
    /// 左侧的竖线
    private lazy var indicatorView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.N400
        v.layer.masksToBounds = true
        return v
    }()
    
    /// 引文label
    private lazy var label: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 14)
        v.textColor = UDColor.textCaption
        v.numberOfLines = 1
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        
        clipsToBounds = true // 避免indicatorView高度超出边界
        
        addSubview(indicatorView)
        indicatorView.snp.makeConstraints {
            $0.left.centerY.equalToSuperview()
            $0.height.equalTo(14)
            $0.width.equalTo(2)
        }
        indicatorView.layer.cornerRadius = 1
        
        addSubview(label)
        label.snp.makeConstraints {
            $0.left.equalTo(indicatorView.snp.right).offset(5)
            $0.right.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }
    }
}

extension FeedCellQuoteView {
    
    /// 设置引文字符
    func setQuote(text: String?) {
        label.text = text
    }
}
