//
//  MomentsCommentReplyView.swift
//  Moment
//
//  Created by liluobin on 2021/1/27.
//

import Foundation
import UIKit
import RichLabel
import LarkCore

final class MomentsCommentReplyView: UIView {

    static let replayViewHeight: CGFloat = 21

    let lineView = UIView()

    lazy var textLabel: LKLabel = {
        let fontColor = UIColor.ud.N500
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: fontColor,
            .font: UIFont.systemFont(ofSize: 14)
        ]
        let outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: attributes)
        let label: LKLabel = LKLabel(frame: .zero).lu.setProps(
            fontSize: 14,
            numberOfLine: 1,
            textColor: fontColor
        )
        /**
         lu.setProps 内部会关闭 translatesAutoresizingMaskIntoConstraints
         使用frame布局需要为true, 否则无效
         */
        label.translatesAutoresizingMaskIntoConstraints = true
        label.autoDetectLinks = false
        label.outOfRangeText = outOfRangeText
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 1
        return label
    }()

    init(replyComment: NSAttributedString, preferredMaxWidth: CGFloat) {
        super.init(frame: .zero)
        setupUI()
        updateViewWith(replyComment: replyComment, preferredMaxWidth: preferredMaxWidth)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        self.addSubview(lineView)
        lineView.backgroundColor = UIColor.ud.udtokenQuoteBarBg
        textLabel.backgroundColor = .clear
        self.addSubview(textLabel)
    }

    func updateViewWith(replyComment: NSAttributedString, preferredMaxWidth: CGFloat) {
        let width: CGFloat = 2
        self.lineView.layer.cornerRadius = width / 2.0
        self.lineView.layer.masksToBounds = true
        self.lineView.frame = CGRect(x: 0, y: (MomentsCommentReplyView.replayViewHeight - 14) / 2.0, width: width, height: 14)
        self.textLabel.preferredMaxLayoutWidth = preferredMaxWidth - 6
        self.textLabel.frame = CGRect(x: 6, y: 0, width: preferredMaxWidth - 6, height: MomentsCommentReplyView.replayViewHeight)
        self.textLabel.attributedText = replyComment
    }
}
