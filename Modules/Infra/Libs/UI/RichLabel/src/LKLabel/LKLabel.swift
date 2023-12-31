//
//  LKLabel.swift
//  LarkUIKit
//
//  Created by 齐鸿烨 on 2017/8/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreText

public let CTFontAttributeName = NSAttributedString.Key(rawValue: kCTFontNameAttribute as String)
public let CTRunDelegateAttributeName = NSAttributedString.Key(rawValue: kCTRunDelegateAttributeName as String)
public let LKPaddingInsectAttributeName = NSAttributedString.Key(rawValue: "LKPaddingInsectAttributeName")
public let LKCornerRadiusAttributeName = NSAttributedString.Key(rawValue: "LKCornerRadiusAttributeName")
public let LKAtAttributeName = NSAttributedString.Key(rawValue: "LKAtAttributeName")
public let LKAtBackgroungColorAttributeName = NSAttributedString.Key(rawValue: "LKAtBackgroungColorAttributeName")
public let LKBackgroundColorAttributeName = NSAttributedString.Key(rawValue: "LKBackgroundColorAttributeName")
public let LKLinkAttributeName = NSAttributedString.Key(rawValue: "LKLinkAttributeName")
public let LKPointAttributeName = NSAttributedString.Key(rawValue: "LKPointAttributeName")
public let LKPointRadiusAttributeName = NSAttributedString.Key(rawValue: "LKPointRadiusAttributeName")
public let LKPointInnerRadiusAttributeName = NSAttributedString.Key(rawValue: "LKPointInnerRadiusAttributeName")
public let LKAttachmentAttributeName = NSAttributedString.Key(rawValue: "LKAttachmentAttributeName")
public let LKAtStrAttributeName = NSAttributedString.Key(rawValue: "LKAtStrAttributeName")
public let LKLabelAttachmentPlaceHolderStr = "\u{FFFC}"
public let LKEmojiAttributeName = NSAttributedString.Key(rawValue: "LKEmojiAttributeName")
public let LKGlyphTransformAttributeName = NSAttributedString.Key(rawValue: "LKGlyphTransformAttributeName")
public let LKCharacterLeftKernAttributeName = NSAttributedString.Key(rawValue: "LKCharacterLeftKernAttributeName")
public let LKCharacterRightKernAttributeName = NSAttributedString.Key(rawValue: "LKCharacterRightKernAttributeName")
public let LKLineAttributeName = NSAttributedString.Key(rawValue: "LKLineAttributeName")

@inline(__always)
func DEBUG(true: () -> Void, false: (() -> Void) = {}) {
    #if DEBUG
    `true`()
    #else
    `false`()
    #endif
}

public enum LKTextVerticalAlignment: Int {
    case top, middle, bottom
}

@available(*, deprecated, message: "LKLabel is out of date，please use LKRichView")
open class LKLabel: UIView {
    public override init(frame: CGRect) {
        self.textParser = LKTextParserImpl()
        self.textParser.defaultFont = self.font
        super.init(frame: frame)
        self.layout.defaultFont = self.font
        self.isAccessibilityElement = true
        self.accessibilityTraits = UIAccessibilityTraits.staticText
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var debugOptions: [LKLabelDebugOptions]?

    public var isOpenTooLongEmoticonBugFix: Bool {
        get {
            return (textParser as? LKTextParserImpl)?.isOpenTooLongEmoticonBugFix ?? false
        }
        set {
            (textParser as? LKTextParserImpl)?.isOpenTooLongEmoticonBugFix = newValue
        }
    }

    // Label基础属性
    open var numberOfLines: Int = 0 {
        didSet {
            self.layout.numberOfLines = numberOfLines
            self.render.numberOfLines = numberOfLines
        }
    }

    open var lineSpacing: CGFloat = 0 {
        didSet {
            self.layout.lineSpacing = lineSpacing
        }
    }

    open var preferredMaxLayoutWidth: CGFloat = -1 {
        didSet {
            self.layout.preferMaxWidth = self.preferredMaxLayoutWidth
        }
    }

    open var textColor: UIColor! = UIColor.black {
        didSet {
            self.render.textColor = textColor
        }
    }

    open var font: UIFont! = UIFont.systemFont(ofSize: UIFont.systemFontSize) {
        didSet {
            self.render.font = font
            self.textParser.defaultFont = font
            self.layout.defaultFont = font
        }
    }

    open var textAlignment: NSTextAlignment! = .left {
        didSet {
            self.paragraphStyle.alignment = textAlignment
            self.render.textAlign = textAlignment
        }
    }

    open var textVerticalAlignment: LKTextVerticalAlignment = .middle

    open var lineBreakMode: NSLineBreakMode! = .byWordWrapping {
        didSet {
            self.paragraphStyle.lineBreakMode = lineBreakMode
        }
    }

    open var textParser: LKTextParser

    lazy open var linkParser: LKLinkParserImpl = {
        return LKLinkParserImpl(linkAttributes: self.linkAttributes)
    }()

    var needSyncToLayoutAndRender = true
    var _attributedText: NSMutableAttributedString? {
        didSet {
            if needSyncToLayoutAndRender {
                self.layout.attributedText = self._attributedText
                self.render.attributedText = self._attributedText
            }
        }
    }

    open var attributedText: NSAttributedString? {
        get {
            return self.textParser.originAttrString
        }
        set {
            if newValue == nil || !newValue!.isEqual(attributedText) {
                self.omittedValue = nil
                self.widthSizeCache = [:]
                self.intrinsicContentSizeBoundsSize = CGSize(width: -1, height: -1)

                self.inactiveAttributedText = nil
                self.activeLink = nil
                self.isTouchOutOfRangeText = nil
                if attributedText != nil {
                    self.hyperLinkList = []
                    self.detectLinkList = []
                }
            }

            if let attrText = newValue {
                self.subviews.forEach({ $0.removeFromSuperview() })
                self.render.attachmentFrames = []

                self.textParser.originAttrString = attrText
                self.textParser.parse()
                self.linkParser.originAttrString = self.textParser.renderAttrString
                self.linkParser.parserIndicesToOriginIndices = self.textParser.parserIndicesToOriginIndices
                self.linkParser.parse()

                self._attributedText = self.linkParser.renderAttrString
                if self.autoDetectLinks {
                    self.detectLinks()
                }
            } else {
                self._attributedText = nil
            }
            self.invalidateIntrinsicContentSize()
            self.setNeedsDisplay()
        }
    }

    open var text: String? {
        get {
            return self.attributedText?.string
        }
        set {
            if newValue != nil {
                self.attributedText = NSAttributedString(
                    string: newValue!,
                    attributes: [
                        .paragraphStyle: self.paragraphStyle.copy(),
                        .font: self.font.copy(),
                        NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): self.textColor.cgColor.copy() as Any
                    ]
                )
            } else {
                self.attributedText = nil
            }
        }
    }

    public var visibleTextRange: NSRange? {
        guard let visibleTextRange = self.render.visibleTextRange,
            visibleTextRange.length > 0 else {
            return nil
        }
        let lowerBound = self.textParser.getOriginIndex(from: visibleTextRange.lowerBound)
        let upperBound = self.textParser.getOriginIndex(from: visibleTextRange.upperBound - 1) + 1
        return NSRange(
            location: lowerBound,
            length: upperBound - lowerBound
        )
    }

    public var firstAtPointRect: CGRect? {
        return (self.render as? LKTextDrawPoint)?.firstAtPointRect
    }

    public weak var delegate: LKLabelDelegate?

    public var activeLinkAttributes: [NSAttributedString.Key: Any] = [LKBackgroundColorAttributeName: UIColor.gray]

    public var linkAttributes: [NSAttributedString.Key: Any] =
        [NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): UIColor.blue.cgColor] {
        didSet {
            self.linkParser.linkAttributes = linkAttributes
        }
    }

    // 是否自动检测链接, default is true
    public var autoDetectLinks = true

    public var tapableRangeList: [NSRange] {
        get {
            return self.linkParser.tapableRangeList
        }
        set {
            self.linkParser.tapableRangeList = newValue
        }
    }

    /// used for rich text tap
    public var tapPoint: CGPoint?

    public var rangeLinkMapper: [NSRange: URL]? {
        get {
            return self.linkParser.rangeLinkMapper
        }
        set {
            self.linkParser.rangeLinkMapper = newValue
        }
    }

    public var textCheckingDetecotor: NSRegularExpression? {
        set {
            if newValue == self.textCheckingDetecotor {
                return
            }

            self.dataDetector = newValue
        }
        get {
            return nil
        }
    }

    // 超出展示区域后展示的内容
    public var outOfRangeText: NSAttributedString? {
        didSet {
            self.layout.outOfRangeText = outOfRangeText
        }
    }

    public var isFuzzyPointAt: Bool = false {
        didSet {
            self.render.isFuzzyPointAt = isFuzzyPointAt
        }
    }

    public var fuzzyEdgeInsets: UIEdgeInsets = .zero {
        didSet {
            self.render.fuzzyEdgeInsets = fuzzyEdgeInsets
        }
    }

    public var debug: LKTextRenderDebugOptions?

    static var queue: DispatchQueue = DispatchQueue(label: "LkLabel.OperationQueue",
                                                    qos: .background)

    lazy var render: LKTextRenderEngine = {
        return LKTextRenderEngineImpl(view: self)
    }()

    lazy var layout: LKTextLayoutEngine = LKTextLayoutEngineImpl()

    var paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle() {
        didSet {
            if let attrStr = self.attributedText, attrStr.attribute(.paragraphStyle, at: 0, effectiveRange: nil) == nil {
                let mutableAttrStr = NSMutableAttributedString(attributedString: attrStr)
                let range = NSRange(location: 0, length: mutableAttrStr.length)
                mutableAttrStr.addAttribute(.paragraphStyle, value: self.paragraphStyle, range: range)
                self.attributedText = mutableAttrStr
            }
        }
    }

    // 绘制内容需要多大的size，算了textInsets。
    var intrinsicContentSizeBoundsSize: CGSize = CGSize(width: -1, height: -1)

    var isTouchOutOfRangeText: Bool?

    var widthSizeCache: [CGFloat: CGSize] = [:]

    var dataDetector: NSRegularExpression?

    // 检测到的链接，self.autoDetectLinks为true时有值
    var detectLinkList: [LKTextLink]?

    // 文本链接对应的范围
    var hyperLinkList: [LKTextLink]? {
        get {
            return self.linkParser.hyperLinkList
        }
        set {
            self.linkParser.hyperLinkList = newValue
        }
    }

    var textLinkList: [LKTextLink] {
        get {
            return self.linkParser.textLinkList
        }
        set {
            self.linkParser.textLinkList = newValue
        }
    }

    var tmpActiveLink: LKTextLink?

    var activeLink: LKTextLink? {
        didSet {
            if activeLink == oldValue {
                return
            }
            let activeAttributes = activeLink?.activeAttributes ?? self.activeLinkAttributes
            if let activeLink = self.activeLink, !activeAttributes.isEmpty {
                self.inactiveAttributedText = self._attributedText
                // range需要转换，原因参考LKLinkParserImpl.parse()
                if self.inactiveAttributedText != nil, let activeRange = self.linkParser.originRangeToParserRange(activeLink.range) {
                    let mutableAttrStr = NSMutableAttributedString(attributedString: self.inactiveAttributedText!)
                    // activeRange是否有效
                    let rangeIsValid = NSLocationInRange(NSMaxRange(activeRange) - 1, NSRange(location: 0, length: mutableAttrStr.length))
                    if activeRange.length > 0, rangeIsValid {
                        mutableAttrStr.addAttributes(activeAttributes, range: activeRange)
                    }
                    self._attributedText = mutableAttrStr
                    self.intrinsicContentSizeBoundsSize = .zero
                    self.setNeedsDisplay()
                    CATransaction.flush()
                }
            } else if self.inactiveAttributedText != nil {
                self._attributedText = NSMutableAttributedString(attributedString: self.inactiveAttributedText!)
                self.inactiveAttributedText = nil
                self.intrinsicContentSizeBoundsSize = .zero
                self.setNeedsDisplay()
            } else {
                self.inactiveAttributedText = nil
            }
        }
    }

    var tapTextIndex: Int = -1

    var omittedValue: Bool? {
        didSet {
            guard let omittedValue = omittedValue else {
                return
            }
            if omittedValue != oldValue {
                self.delegate?.shouldShowMore(self, isShowMore: omittedValue)
            }
        }
    }

    var inactiveAttributedText: NSAttributedString?

    // 是否能全部展示出来
    var isOmitted: ((Bool) -> Void)?

    // 指定文本链接映射关系
    var hyperlinkMapper: [String: URL]? {
        get {
            return self.linkParser.hyperlinkMapper
        }
        set {
            self.linkParser.hyperlinkMapper = newValue
        }
    }

    // label的padding (5, 5, 5, 5)表示向内偏移5
    var textInsets: UIEdgeInsets = .zero {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    // MARK: Accessibility
    open override var accessibilityLabel: String? {
        get { return self.text }
        set { self.text = newValue }
    }
    open override var accessibilityAttributedLabel: NSAttributedString? {
        get { return self.attributedText }
        set { self.attributedText = newValue }
    }
}
