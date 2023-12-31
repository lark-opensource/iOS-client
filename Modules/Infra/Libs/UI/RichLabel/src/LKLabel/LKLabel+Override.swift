//
//  LKLabel+Override.swift
//  LarkUIKit
//
//  Created by Yuguo on 2017/12/15.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation
extension LKLabel {
    open override var backgroundColor: UIColor? {
        didSet {
            self.render.backgroundColor = backgroundColor
        }
    }

    open override var bounds: CGRect {
        didSet {
            if bounds != oldValue {
                setNeedsDisplay()
            }
        }
    }

    open override func draw(_ rect: CGRect) {
        self.drawText(in: rect)
    }

    @objc
    open func drawText(in rect: CGRect) {
        // 内容只能绘制到这片区域，超出内容不绘制
        let insetsRect = self.bounds.inset(by: self.textInsets)
        guard let attributedText = self._attributedText,
              !attributedText.string.isEmpty else {
            return super.draw(insetsRect)
        }

        guard let context = UIGraphicsGetCurrentContext() else { return }
        // 在纯frame场景下会有drawText的rect跟原始大小不相关的情况 #2594
        if self.layout.lines.isEmpty || rect.size != self.intrinsicContentSizeBoundsSize {
            _ = self.sizeThatFits(insetsRect.size)
        }
        if let paragraphStyle = self._attributedText?.attribute(NSAttributedString.Key.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
            self.render.textAlign = paragraphStyle.alignment
        } else {
            self.render.textAlign = self.textAlignment
        }
        self.render.bounds = self.bounds
        self.render.insetsRect = self.textInsets
        self.render.lineSpacing = self.layout.lineSpacing
        self.render.isFuzzyPointAt = self.isFuzzyPointAt
        self.render.fuzzyEdgeInsets = self.fuzzyEdgeInsets
        self.render.textSize = self.layout.textSize
        self.render.textVerticalAlignment = self.textVerticalAlignment
        self.render.outOfRangeTextLayout = self.layout.outOfRangeTextLayout?.clone()
        self.render.isOutOfRange = self.layout.isOutOfRange
        self.render.lines = self.layout.lines
        self.render.draw(context: context, debug: debug)
        self.omittedValue = self.render.isOutOfRange

        if let firstAtPointRect = self.firstAtPointRect {
            self.delegate?.showFirstAtRect(firstAtPointRect)
        }
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        guard self._attributedText != nil else {
            return super.sizeThatFits(size)
        }
        var labelSize = self.layout.layout(size: size)
        labelSize.width += self.textInsets.left + self.textInsets.right
        labelSize.height += self.textInsets.top + self.textInsets.bottom
        self.intrinsicContentSizeBoundsSize = labelSize

        return labelSize
    }

    override open var intrinsicContentSize: CGSize {
        switch (self.intrinsicContentSizeBoundsSize.width, self.intrinsicContentSizeBoundsSize.height) {
        case (-1, -1), (0, _), (_, 0):
            return self.sizeThatFits(CGSize(width: -1, height: -1))
        case (self.bounds.width, self.bounds.height):
            return self.sizeThatFits(self.bounds.size)
        default:
            return self.sizeThatFits(CGSize(width: self.bounds.size.width, height: LKTextLayoutEngineImpl.MAX_FLOAT))
        }
    }

    open override func invalidateIntrinsicContentSize() {
        self.intrinsicContentSizeBoundsSize = CGSize(width: -1, height: -1)
        super.invalidateIntrinsicContentSize()
    }

    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        self.tmpActiveLink = nil
        if self.isHidden {
            return nil
        }

        for subview in self.subviews {
            let newPoint = self.convert(point, to: subview)
            if let view = subview.hitTest(newPoint, with: event) {
                return view
            }
        }

        switch self.attributedIndex(at: point) {
        case .notInText:
            return nil
        case .outOfRangeText:
            self.isTouchOutOfRangeText = true
            return self
        case .inText(let index):
            self.tapTextIndex = self.indexAtTapableText(at: index.nearist)
            if self.tapTextIndex != -1 {
                return self
            }
            self.tapTextIndex = self.indexAtTapableText(at: index.other)
            if self.tapTextIndex != kCFNotFound {
                return self
            }

            if let link = getTmpActiveLink(index.nearist) ?? getTmpActiveLink(indexAtTapableText(at: index.other)) {
                self.tmpActiveLink = link
                return self
            }
        }
        return nil
    }

    func getTmpActiveLink(_ index: CFIndex) -> LKTextLink? {
        var tmpLink: LKTextLink?
        if self.autoDetectLinks || self.hyperlinkMapper != nil || !self.textLinkList.isEmpty {
            // 点击了自动识别的链接
            tmpLink = self.link(at: index)

            if tmpLink == nil {
                tmpLink = self.hyperlink(at: index)
            }
        }
        if tmpLink != nil {
            return tmpLink
        }
        return nil
    }

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.activeLink = self.tmpActiveLink
        if let touch = touches.first {
            tapPoint = convertPointWith(touch.location(in: self),
                                        initialRect: self.bounds,
                                        toRect: self.render.textRect)
        }
    }

    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let touchPos = touch.location(in: self)
        let pointAtType = self.attributedIndex(at: touchPos)

        if case .inText(let index) = pointAtType,
           self.tapTextIndex != -1,
           (self.tapTextIndex != self.indexAtTapableText(at: index.nearist)
            || self.tapTextIndex != self.indexAtTapableText(at: index.other)) {
            self.tapTextIndex = -1
        }
        if self.activeLink != nil,
           self.activeLink!.accessibilityValue != self.linkAtPoint(point: touchPos)?.accessibilityValue {
            self.activeLink = nil
            return
        }
        if self.isTouchOutOfRangeText == true {
            if self.render.visibleTextRange == nil {
                self.isTouchOutOfRangeText = nil
                return
            }

            switch pointAtType {
            case .notInText, .inText:
                self.isTouchOutOfRangeText = false
            default:
                break
            }
            return
        }
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.isTouchOutOfRangeText == true {
            self.isTouchOutOfRangeText = nil
            self.delegate?.tapShowMore(self)
            self.activeLink = nil
            self.tapPoint = nil
            return
        }

        if self.tapTextIndex != -1 || self.activeLink != nil {
            if let attrText = self.attributedText,
                self.tapTextIndex >= 0,
                self.tapTextIndex < self.tapableRangeList.count {

                let tapRange = self.tapableRangeList[self.tapTextIndex]
                while true {
                    if tapRange.upperBound > attrText.length {
                        self.debugOptions?.logger?.error("Out of bounds! text: \(attrText.string), tapRange: \(tapRange)", error: nil)
                        break
                    }
                    let tapText = attrText.attributedSubstring(from: tapRange).string

                    if self.delegate?.attributedLabel(self, didSelectText: tapText, didSelectRange: tapRange) == false {
                        self.tapPoint = nil
                        return
                    }
                    break
                }
            }

            if let linkTapBlock = self.activeLink?.linkTapBlock {
                linkTapBlock(self, self.activeLink!)
                self.activeLink = nil
                self.tapPoint = nil
                return
            }

            if let activeLink = self.activeLink {
                if let link = activeLink.url {
                    self.delegate?.attributedLabel(self, didSelectLink: link)
                    self.activeLink = nil
                    return
                }
                if let phoneNumber = activeLink.phoneNumber {
                    self.delegate?.attributedLabel(self, didSelectPhoneNumber: phoneNumber)
                    self.activeLink = nil
                    return
                }
                switch activeLink.type {
                case NSTextCheckingResult.CheckingType.link,
                     NSTextCheckingResult.CheckingType.phoneNumber:
                    break
                case NSTextCheckingResult.CheckingType.regularExpression:
                    if let delegate = self.delegate,
                        let originText = self.attributedText,
                       activeLink.range.upperBound <= originText.length,
                       activeLink.range.lowerBound >= 0 {
                        let didSelectText = originText.attributedSubstring(from: activeLink.range).string
                        _ = delegate.attributedLabel(
                            self, didSelectText: didSelectText, didSelectRange: activeLink.range
                        )
                    }
                    self.activeLink = nil
                default:
                    self.activeLink = nil
                    self.tapPoint = nil
                    return
                }
            }
            self.tapPoint = nil
            return
        }
        self.tapPoint = nil
    }

    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.activeLink != nil {
            self.activeLink = nil
        }
        if self.isTouchOutOfRangeText != nil {
            self.isTouchOutOfRangeText = nil
        }
        self.tapPoint = nil
    }
}
