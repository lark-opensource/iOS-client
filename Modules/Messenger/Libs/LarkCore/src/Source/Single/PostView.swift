//
//  PostView.swift
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
import LKCommonsLogging

struct LKLabelLoggerImpl: LKLabelLogger {
    let logger = Logger.log(LKLabel.self)

    func debug(_ message: String, error: Error?, file: String, method: String, line: Int) {
        logger.debug(message, additionalData: nil, error: error, file: file, function: method, line: line)
    }

    func info(_ message: String, error: Error?, file: String, method: String, line: Int) {
        logger.info(message, additionalData: nil, error: error, file: file, function: method, line: line)
    }

    func error(_ message: String, error: Error?, file: String, method: String, line: Int) {
        logger.error(message, additionalData: nil, error: error, file: file, function: method, line: line)
    }
}

open class PostView: UIView {

    private var isReply: Bool
    private var isUntitledPost: Bool = true

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        self.addSubview(titleLabel)
        titleLabel.isHidden = true
        return titleLabel
    }()

    var tapHandler: (() -> Void)?

    public var fontSize: CGFloat
    public var numberOfLines: Int
    public var contentLabel: LKSelectionLabel!

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

    public init(titleLines: Int = 2, numberOfLines: Int = 0, fontSize: CGFloat = 16, delegate: LKLabelDelegate, isReply: Bool, tapHandler: (() -> Void)? = nil) {

        self.fontSize = fontSize
        self.isReply = isReply
        self.numberOfLines = numberOfLines

        super.init(frame: .zero)

        self.backgroundColor = UIColor.clear
        self.tapHandler = tapHandler

        // contentLabel
        var contentLabel = LKSelectionLabel()
        if let selectionLabel = (contentLabel as LKLabel).lu.setProps(fontSize: fontSize, numberOfLine: numberOfLines, textColor: UIColor.ud.N900) as? LKSelectionLabel {
            contentLabel = selectionLabel
        }
        #if DEBUG
        contentLabel.seletionDebugOptions = LKSelectionLabelDebugOptions([.printTouchEvent])
        #endif
        contentLabel.options = [
            .cursorColor(UIColor.ud.colorfulBlue),
            .selectionColor(UIColor.ud.colorfulBlue.withAlphaComponent(0.16)),
            .cursorTouchHitTestInsets(UIEdgeInsets(top: -14, left: -25, bottom: -14, right: -25))
        ]
        contentLabel.debugOptions = [.logger(LKLabelLoggerImpl())]
        contentLabel.lineSpacing = 1
        contentLabel.delegate = delegate
        self.addSubview(contentLabel)
        self.contentLabel = contentLabel

        self.titleLabel.numberOfLines = titleLines

        updateContentLabelConstraints()
    }

    private func updateContentLabelConstraints() {
        contentLabel.snp.remakeConstraints { (make) in
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

    /// 设置 contentLabel 属性和内容.
    ///
    /// - Parameters:
    ///   - contentMaxWidth: 内容最大宽度,必须设置.
    ///   - attributedText: attributedText
    ///   - rangeLinkMap: 文本中 url 对应的 range 字典, 用于渲染 url 链接, 通过 delegate 的方式处理点击.
    ///   - tapableRangeList: 文本中需要点击区域的, 通过 delegate 的方式处理点击.
    ///   - invaildLinkMap: 文本中普通 string 渲染成 url 样式, 通过 invaildLinkBlock 处理点击.
    ///   - invaildLinkBlock: 处理普通 string 的点击事件.
    public func setContentLabel(
        contentMaxWidth: CGFloat,
        titleText: String = "",
        isUntitledPost: Bool,
        attributedText: NSAttributedString,
        rangeLinkMap: [NSRange: URL] = [:],
        tapableRangeList: [NSRange] = [],
        textLinkMap: [NSRange: String] = [:],
        linkAttributes: [NSAttributedString.Key: Any]? = nil,
        textLinkBlock: ((String) -> Void)? = nil) {

        if !isUntitledPost {
            self.titleLabel.font = UIFont.ud.headline
            self.titleLabel.text = titleText
        }

        if isUntitledPost != self.isUntitledPost {
            self.isUntitledPost = isUntitledPost
            self.isShowTitle = !(self.isUntitledPost || self.isReply)
        }

        self.contentLabel.preferredMaxLayoutWidth = contentMaxWidth
        self.contentLabel.numberOfLines = numberOfLines
        self.contentLabel.rangeLinkMapper = rangeLinkMap
        self.contentLabel.tapableRangeList = tapableRangeList
        if let linkAttributes = linkAttributes {
            self.contentLabel.linkAttributes = linkAttributes
        }
        self.contentLabel.removeLKTextLink()
        textLinkMap.forEach { [weak self] (range, url) in
            var textLink = LKTextLink(range: range, type: .link)
            textLink.linkTapBlock = { (_, _) in
                textLinkBlock?(url)
            }
            self?.contentLabel.addLKTextLink(link: textLink)
        }

        let attribute = outOfRangeAttributes
        let outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: attribute)
        self.contentLabel.outOfRangeText = outOfRangeText
        self.contentLabel.attributedText = attributedText
    }
}
