//
//  NewPostView.swift
//  LarkCore
//
//  Created by JackZhao on 2021/10/11.
//

import UIKit
import SnapKit
import LarkUIKit
import LKRichView
import LarkFoundation
import LKCommonsLogging
import CoreGraphics
import Foundation

// 使用新富文本渲染框架的postView
open class NewPostView: UIView {
    private var isReply: Bool
    private var isUntitledPost: Bool = true

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.textAlignment = .left
        titleLabel.lineBreakMode = .byTruncatingTail
        self.addSubview(titleLabel)
        titleLabel.isHidden = true
        return titleLabel
    }()

    var tapHandler: (() -> Void)?

    public var fontSize: CGFloat
    public var numberOfLines: Int
    lazy var richview: LKRichView = {
        var postView = LKRichView(frame: .zero)
        return postView
    }()

    public private(set) var isShowTitle: Bool = false {
        didSet {
            if oldValue != isShowTitle {
                titleLabel.isHidden = !isShowTitle
                updateContentLabelConstraints()
            }
        }
    }

    var topRelativeItem: ConstraintItem {
        if isShowTitle {
            return self.titleLabel.snp.bottom
        } else {
            return self.snp.top
        }
    }

    public lazy var outOfRangeAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.ud.N900,
        .font: UIFont.systemFont(ofSize: fontSize)
    ]

    public var preferredMaxLayoutWidth: CGFloat {
        didSet {
            richview.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        }
    }

    public init(titleLines: Int = 2,
                numberOfLines: Int = 0,
                fontSize: CGFloat = 16,
                isReply: Bool,
                preferredMaxLayoutWidth: CGFloat,
                tapHandler: (() -> Void)? = nil) {

        self.fontSize = fontSize
        self.isReply = isReply
        self.numberOfLines = numberOfLines
        self.preferredMaxLayoutWidth = preferredMaxLayoutWidth

        super.init(frame: .zero)
        self.titleLabel.numberOfLines = numberOfLines

        self.backgroundColor = UIColor.clear
        self.tapHandler = tapHandler

        // richview
        self.addSubview(richview)
        richview.preferredMaxLayoutWidth = preferredMaxLayoutWidth

        self.titleLabel.numberOfLines = titleLines

        updateContentLabelConstraints()
    }

    public static var empty: NewPostView { NewPostView(isReply: false, preferredMaxLayoutWidth: 0) }

    private func updateContentLabelConstraints() {
        richview.snp.remakeConstraints { (make) in
            make.left.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.top.equalTo(self.topRelativeItem).offset(isShowTitle ? 8 : 0)
        }

        if isShowTitle {
            titleLabel.snp.remakeConstraints { (make) in
                make.top.left.equalToSuperview()
                make.right.lessThanOrEqualToSuperview()
            }
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.tapHandler == nil {
            super.touchesBegan(touches, with: event)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.tapHandler == nil {
            super.touchesMoved(touches, with: event)
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.tapHandler == nil {
            super.touchesCancelled(touches, with: event)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let handler = self.tapHandler {
            handler()
        } else {
            super.touchesEnded(touches, with: event)
        }
    }

    public func setContent(title: String,
                           isUntitledPost: Bool,
                           element: LKRichElement) {
        if !isUntitledPost {
            self.titleLabel.font = UIFont.ud.headline
            self.titleLabel.text = title
        }

        if isUntitledPost != self.isUntitledPost {
            self.isUntitledPost = isUntitledPost
            self.isShowTitle = !(self.isUntitledPost || self.isReply)
        }
        richview.documentElement = element
    }

    public func setAttributeTitle(title: NSAttributedString,
                                      isUntitledPost: Bool,
                                      element: LKRichElement) {
        self.titleLabel.attributedText = title
        self.isShowTitle = true
        self.isUntitledPost = false
        richview.documentElement = element
    }

    public func loadStyleSheets(_ styleSheets: [CSSStyleSheet]) {
        richview.loadStyleSheets(styleSheets)
    }

    public func bindEvent(selectorLists: [[CSSSelector]], isPropagation: Bool) {
        richview.bindEvent(selectorLists: selectorLists, isPropagation: isPropagation)
    }

    public func setRichViewDelegate(_ delegate: LKRichViewDelegate) {
        self.richview.delegate = delegate
    }
}
