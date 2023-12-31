//
//  MergeForwardView.swift
//  LarkCore
//
//  Created by chengzhipeng-bytedance on 2018/6/14.
//

import Foundation
import UIKit
import LarkUIKit
import LarkFoundation
import SnapKit
import RichLabel

public final class MergeForwardView: UIView {

    enum Cons {
        static var titleFont: UIFont { UIFont.ud.headline }
        static var contentFont: UIFont { UIFont.ud.body2 }
    }

    var titleLabel: UILabel = .init()
    var contentLabel: LKLabel = .init()
    var tapHandler: (() -> Void)?

    public init(titleLines: Int = 2, contentLabelLines: Int = 4, tapHandler: (() -> Void)?) {
        super.init(frame: .zero)

        self.tapHandler = tapHandler

        // title
        let titleLabel = UILabel()
        titleLabel.font = Cons.titleFont
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = titleLines
        titleLabel.textColor = UIColor.ud.N900
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.right.equalToSuperview()
            make.left.equalTo(9)
        }
        self.titleLabel = titleLabel

        // line
        let line = UIView()
        line.layer.cornerRadius = 2
        line.backgroundColor = UIColor.ud.colorfulYellow
        self.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.equalTo(3)
            make.bottom.top.equalTo(self.titleLabel)
        }

        // contentLabel
        let contentLabel = LKLabel()
        contentLabel.backgroundColor = UIColor.clear
        contentLabel.font = Cons.contentFont
        contentLabel.textColor = UIColor.ud.N600
        contentLabel.numberOfLines = contentLabelLines
        contentLabel.textAlignment = .left
        contentLabel.lineSpacing = 2
        self.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalTo(0)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.bottom.right.equalToSuperview()
        }
        self.contentLabel = contentLabel

        // Gesture
        self.lu.addTapGestureRecognizer(action: #selector(mergeForwardViewTapped), target: self)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(contentMaxWidth: CGFloat, title: String, attributeText: NSAttributedString) {
        self.titleLabel.text = title

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.N600,
            .font: UIFont.systemFont(ofSize: 14)
        ]
        let outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: attributes)
        self.contentLabel.outOfRangeText = outOfRangeText
        self.contentLabel.preferredMaxLayoutWidth = contentMaxWidth
        self.contentLabel.attributedText = attributeText
    }

    @objc
    fileprivate func mergeForwardViewTapped() {
        self.tapHandler?()
    }
}
