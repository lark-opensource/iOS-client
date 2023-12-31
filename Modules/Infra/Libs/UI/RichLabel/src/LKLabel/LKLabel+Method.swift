//
//  LKLabel+Method.swift
//  LarkUIKit
//
//  Created by qihongye on 2018/3/5.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation

public extension LKLabel {
    func setForceLayout(_ layout: LKTextLayoutEngine) {
        self.omittedValue = nil
        self.widthSizeCache = [:]
        self.inactiveAttributedText = nil
        self.activeLink = nil
        self.isTouchOutOfRangeText = nil
        self.tmpActiveLink = nil
        self.detectLinkList = []
        self.subviews.forEach({ $0.removeFromSuperview() })
        self.render.attachmentFrames = []

        guard let attrStr = layout.attributedText else {
            return
        }

        self.needSyncToLayoutAndRender = false
        self._attributedText = NSMutableAttributedString(attributedString: attrStr)
        self.needSyncToLayoutAndRender = true
        self.layout = layout.clone()
        self.render.attributedText = layout.attributedText
        if self.autoDetectLinks {
            self.detectLinks()
        }
        self.invalidateIntrinsicContentSize()
        self.intrinsicContentSizeBoundsSize = self.bounds.size
        self.setNeedsDisplay()
    }

    func addLKTextLink(link: LKTextLink) {
        self.textLinkList.append(link)
    }

    func removeLKTextLink(link: LKTextLink? = nil) {
        guard let link = link, self._attributedText != nil else {
            self.textLinkList = []
            return
        }

        if let idx = self.textLinkList.firstIndex(of: link) {
            self.textLinkList.remove(at: idx)
        }
    }

    // 给LKLabel中的某一段文字添加link
    func addLinkAt(urlLinkMap: [URL: NSRange]) {
        guard let attributedText = self.attributedText else {
            return
        }

        if self.hyperLinkList == nil && !urlLinkMap.isEmpty {
            self.hyperLinkList = []
        }

        let attrText = NSMutableAttributedString(attributedString: attributedText)

        urlLinkMap.forEach { kv in
            attrText.addAttributes(self.linkAttributes, range: kv.value)
            var lkLink = LKTextLink(range: kv.value, type: .link)
            lkLink.url = kv.key
            self.hyperLinkList?.append(lkLink)
        }

        self.attributedText = attrText
    }

    // 给指定链接的文本添加样式
    @discardableResult
    func addHyperlinkStyle(links: [String: URL]?) -> NSMutableAttributedString? {
        guard let attrText = self.attributedText as? NSMutableAttributedString else {
            return self.attributedText as? NSMutableAttributedString
        }

        self.hyperLinkList = []

        self.linkParser.processHyperlinkStyle(attrText, links: links)
        return attrText
    }

    func addRangeLinkStyle(_ attrText: NSMutableAttributedString, urlRangeMap: [NSRange: URL]?) -> NSMutableAttributedString {
        self.linkParser.processRangeLinkStyle(attrText, urlRangeMap: urlRangeMap)
        return attrText
    }
}

enum PointAt {
    case notInText
    case inText(PointAtInTextIndex)
    case outOfRangeText
}

extension LKLabel {

    // 给链接增加样式
    func addLinkStyle(attributedText: NSMutableAttributedString, links: [LKTextLink]?) -> NSMutableAttributedString {
        self.linkParser.processLinkStyle(attributedText, links: links)
        return attributedText
    }

    func addLinkStyleAtPrivateAttrString(attributedText: NSMutableAttributedString, links: [LKTextLink]?) {
        guard let linkList = links else {
            return
        }

        for result in linkList
            where result.range.location >= 0
                && result.range.location + result.range.length <= attributedText.length {
            attributedText.addAttributes(
                result.attributes ?? self.linkAttributes,
                range: result.range
            )
        }
    }

    func link(at index: CFIndex) -> LKTextLink? {
        for lkLink in self.textLinkList where lkLink.range.contains(index) {
            return lkLink
        }

        if self.autoDetectLinks {
            guard let links = self.detectLinkList else {
                return nil
            }

            for lkLink in links where lkLink.range.contains(index) {
                return lkLink
            }
        }

        return nil
    }

    // 判断点击的位置是不是链接
    func hyperlink(at index: CFIndex) -> LKTextLink? {
        guard let hyperLinkList = self.hyperLinkList else {
            return nil
        }

        for lkLink in hyperLinkList where lkLink.range.contains(index) {
            return lkLink
        }

        return nil
    }

    // point为UIView坐标系
    func attributedIndex(at point: CGPoint) -> PointAt {
        // 转换到render坐标系
        var point = convertPointWith(point, initialRect: self.bounds, toRect: self.render.textRect)
        let transform = CGAffineTransform(translationX: 0, y: self.render.textRect.height).scaledBy(x: 1, y: -1)
        point = point.applying(transform)

        if self.render.isPointAtOutOfRangeText(point) {
            return .outOfRangeText
        }
        let idx = self.render.pointAt(point)
        if idx.nearist == kCFNotFound {
            return .notInText
        }
        return .inText(.init(
            nearist: self.textParser.getOriginIndex(from: idx.nearist),
            other: self.textParser.getOriginIndex(from: idx.other)
        ))
    }

    func linkAtPoint(point: CGPoint) -> LKTextLink? {
        switch self.attributedIndex(at: point) {
        case .inText(let index):
            return self.link(at: index.nearist)
                ?? self.hyperlink(at: index.nearist)
                ?? self.link(at: index.other)
                ?? self.hyperlink(at: index.other)
        default:
            return nil
        }
    }

    public func appendAttachment(attachment: LKAttachment) {
        guard let attributedText = self.attributedText else {
            return
        }
        let tmpAttributeText = NSMutableAttributedString(attributedString: attributedText)

        tmpAttributeText.append(NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: [
            LKAttachmentAttributeName: attachment
        ]))

        self.attributedText = tmpAttributeText
    }

    public func appendAttachment(attachment: LKAsyncAttachment) {
        guard let attributedText = self.attributedText else {
            return
        }
        let tmpAttributeText = NSMutableAttributedString(attributedString: attributedText)

        tmpAttributeText.append(NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: [
            LKAttachmentAttributeName: attachment
        ]))

        self.attributedText = tmpAttributeText
    }

    // 检测链接
    func detectLinks() {
        guard let attrContent = self._attributedText else { return }

        // 得到block里需要的非引用属性，减少一次LKLabel.queue引用
        let contentString = attrContent.string
        let conetntRange = NSRange(location: 0, length: attrContent.length)
        let customLinkList = self.hyperLinkList ?? [] + self.textLinkList ?? []
        // matches比较耗时，放入子线程
        LKLabel.queue.async { [weak self] in
            guard let `self` = self, let dataDetector = self.dataDetector else { return }
            // 尝试解决EXC_BAD_ACCESS：http://t.wtturl.cn/eYRTsWM/，猜测是多线程问题
            var detectLinkList = dataDetector.matches(in: contentString, options: .reportProgress, range: conetntRange).map { LKTextLink(result: $0) }
            detectLinkList = self.deduplicateLinkList(from: detectLinkList, with: customLinkList)
            guard !detectLinkList.isEmpty else { return }
            // 主线程重新渲染内容
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self, let _attributedText = self._attributedText, contentString == _attributedText.string else { return }

                let attrStr = NSMutableAttributedString(attributedString: _attributedText)
                self.addLinkStyleAtPrivateAttrString(attributedText: attrStr, links: detectLinkList)
                // 需要把parserRange处理成originRange再添加至self.detectLinkList，因为在反向通过index找点击到的link时使用的是originRange
                // Jira：https://jira.bytedance.com/browse/SUITE-74083
                // fix version：3.16.0
                self.detectLinkList = self.detectLinkList ?? []
                self.detectLinkList?.append(contentsOf: detectLinkList.map({ (link) -> LKTextLink in
                    var tempLine = link
                    let originLength = self.attributedText?.length ?? 0
                    tempLine.range = self.textParser.parserRangeToOriginRange(link.range, length: originLength)
                    return tempLine
                }))
                self._attributedText = attrStr
                self.layout.layout(size: self.bounds.size)
                self.setNeedsDisplay()
            }
        }
    }

    // 外部自定义的Link不再重复识别链接 & 电话号码
    private func deduplicateLinkList(from detectLinkList: [LKTextLink], with customLinkList: [LKTextLink]) -> [LKTextLink] {
        guard !detectLinkList.isEmpty, !customLinkList.isEmpty else { return detectLinkList }
        let newDetectLinkList = detectLinkList.filter { linkList in
            return !customLinkList.contains(where: {
                NSLocationInRange(linkList.range.lowerBound, $0.range) ||
                NSLocationInRange(linkList.range.upperBound, $0.range)
            })
        }
        return newDetectLinkList
    }

    /// 查找包含Index的可点击区间的Index
    /// - Parameter index: 要查找的Index
    /// - Returns: 可点击区间的Index，-1 则为Notfound
    func indexAtTapableText(at index: CFIndex) -> Int {
        if index == kCFNotFound {
            return -1
        }
        for (i, tpRange) in self.tapableRangeList.enumerated() where tpRange.contains(index) {
            return i
        }
        return -1
    }
}
