//
//  MomentTrampleViewCell.swift
//  Moment
//
//  Created by ByteDance on 2022/6/29.
//

import Foundation
import LarkUIKit
import UIKit
import SnapKit

final class MomentTrampleViewCell: UITableViewCell {
    /// 文本Label（点踩的理由label）
    private lazy var titleLabel: UILabel = {
        let trampleLabel = UILabel()
        trampleLabel.numberOfLines = 0
        trampleLabel.textColor = UIColor.ud.textTitle
        trampleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        return trampleLabel
    }()
    enum Cons {
        static var iosLRMargin: CGFloat { 16 }
        static var iosTBMargin: CGFloat { 12 }
        static var padMargin: CGFloat { 12 }
    }
    /// 回调函数用于检测当前提交状态
    var onTapCallBack: (() -> Void)?
    /// 隐藏的点击按钮
    private lazy var hiddenBtn: UIButton = {
        let hiddenBtn = UIButton()
        hiddenBtn.backgroundColor = UIColor.clear
        hiddenBtn.isUserInteractionEnabled = true
        hiddenBtn.addTarget(self, action: #selector(tapCell), for: .touchUpInside)
        return hiddenBtn
    }()
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    var feedbackInfo: TrampleModel? {
        didSet {
            updateUI()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpUI()
    }

    private func setUpUI() {
        /// 设置背景颜色
        self.backgroundColor = UIColor.ud.bgFloat
        self.selectionStyle = .none
        /// 添加隐藏的点击按钮
        self.contentView.addSubview(hiddenBtn)
        hiddenBtn.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        /// 添加titleLabel（点踩内容的label）
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            if !Display.pad {
                make.top.equalToSuperview().offset(Cons.iosTBMargin)
                make.left.equalToSuperview().offset(Cons.iosLRMargin)
                make.right.equalToSuperview().offset(-Cons.iosLRMargin)
                make.bottom.equalToSuperview().offset(-Cons.iosTBMargin)
            } else {
                make.left.top.equalToSuperview().offset(Cons.padMargin)
                make.right.bottom.equalToSuperview().offset(-Cons.padMargin)
            }
        }
        /// 选定后cell的边框颜色
        layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        layer.cornerRadius = 10
        clipsToBounds = true
    }

    fileprivate func updateUI() {
        guard let feedbackInfo = feedbackInfo else {
            return
        }
        titleLabel.text = feedbackInfo.content
        titleLabel.textColor = feedbackInfo.selected ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle
        layer.borderWidth = feedbackInfo.selected ? 1 : 0
        backgroundColor = feedbackInfo.selected ? UIColor.ud.primaryContentDefault.withAlphaComponent(0.08) : UIColor.ud.bgFloat
    }

    @objc
    private func tapCell() {
        guard let feedbackInfo = feedbackInfo else {
            return
        }
        feedbackInfo.selected = !feedbackInfo.selected
        updateUI()
        self.onTapCallBack?()
    }
}
