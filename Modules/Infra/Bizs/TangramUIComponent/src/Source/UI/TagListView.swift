//
//  TagListView.swift
//  LarkUIKit
//
//  Created by bytedance on 2021/5/13.
//
import UIKit
import Foundation

final class PaddingLabel: UILabel {
    // 当文本宽度超过容器宽度时，不能由文本撑开，应该是外部指定的固定size
    var fixSize: CGSize?

    var padding = UIEdgeInsets.zero {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    var hInset: CGFloat {
        return padding.left + padding.right
    }

    var vInset: CGFloat {
        return padding.top + padding.bottom
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        if let fixSize = fixSize {
            return fixSize
        }
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + self.hInset,
                      height: size.height + self.vInset)
    }

    override func sizeToFit() {
        super.sizeToFit()
        let size = fixSize ?? CGSize(width: self.frame.size.width + self.hInset,
                                     height: self.frame.size.height + self.vInset)
        self.frame = CGRect(origin: self.frame.origin, size: size)
    }
}

public struct TagInfo: Equatable {
    public var text: String
    public var textColor: UIColor
    public var backgroundColor: UIColor

    public init(text: String,
                textColor: UIColor,
                backgroundColor: UIColor) {
        self.text = text
        self.textColor = textColor
        self.backgroundColor = backgroundColor
    }

    public func copy() -> TagInfo {
        return TagInfo(text: text,
                       textColor: (textColor.copy() as? UIColor) ?? TagListView.defaultTextColor,
                       backgroundColor: (backgroundColor.copy() as? UIColor) ?? TagListView.defaultBackgroundColor)
    }

    public static func == (lhs: TagInfo, rhs: TagInfo) -> Bool {
        return lhs.text == rhs.text &&
        lhs.textColor == rhs.textColor &&
        lhs.backgroundColor == rhs.backgroundColor
    }
}

public final class TagListView: UIView {
    public static var defaultFont: UIFont { UIFont.ud.caption3 }
    public static var defaultTextColor: UIColor { UIColor.ud.textCaption }
    public static var defaultBackgroundColor: UIColor { UIColor.ud.udtokenTagNeutralBgNormal }

    public typealias TagItem = (frame: CGRect, info: TagInfo)

    static let textPadding = UIEdgeInsets(top: 1.5, left: 4.0, bottom: 1.5, right: 4.0)
    // Tag间间距
    static let tagPaddingH: CGFloat = 6
    static let tagPaddingV: CGFloat = 4

    public init(frame: CGRect, tags: [TagItem], font: UIFont) {
        super.init(frame: frame)
        self.update(tags: tags, font: font)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(tags: [TagItem], font: UIFont) {
        var pool = self.subviews.compactMap({ $0 as? PaddingLabel })
        self.subviews.forEach({ $0.removeFromSuperview() })
        tags.forEach { tagItem in
            let tagView = pool.popLast() ?? PaddingLabel(frame: tagItem.frame)
            tagView.frame = tagItem.frame
            Self.config(tag: tagView, tagInfo: tagItem.info, font: font)
            self.addSubview(tagView)
        }
    }

    public static func tagView(tagInfo: TagInfo, font: UIFont, fixSize: CGSize) -> UIView {
        let tag = PaddingLabel(frame: .zero)
        tag.fixSize = fixSize
        config(tag: tag, tagInfo: tagInfo, font: font)
        return tag
    }

    /// Parameters
    ///     - size: container size
    ///     - tagInfos: tags
    ///     - font:
    ///     - numberOfLines: 最多展示多少行，当numberOfLines = 0时，表示不限制行数
    /// Return
    ///     - CGSize: TagListView尺寸
    ///     - [TagInfo]: 能展示下且携带位置信息（frame）的TagInfo
    public static func layout(size: CGSize, tagInfos: [TagInfo], font: UIFont, numberOfLines: Int) -> (CGSize, [TagItem]) {
        guard !tagInfos.isEmpty else { return (.zero, []) }
        // 当numberOfLines = 0时，表示不限制行数
        var numberOfLines = numberOfLines <= 0 ? Int.max : numberOfLines
        // 布局指针
        var top: CGFloat = 0
        var left: CGFloat = 0
        var computedTags = [TagItem]()
        for tagInfo in tagInfos {
            let tagSize = sizeFor(size, tagInfo: tagInfo, font: font)
            if top + tagSize.height > size.height { break } // 高度超过即终止
            if left + tagSize.width > size.width { // 宽度超过，需要换行
                top += tagSize.height + tagPaddingV
                left = 0
                numberOfLines -= 1
                // 1. 换行之后高度超过
                // 2. 每行第一个Tag宽度超出
                // 3. 超过最大行数
                if top + tagSize.height > size.height || tagSize.width > size.width || numberOfLines <= 0 {
                    break
                }
            }
            // 当前行能装下
            let tagFrame = CGRect(x: left, y: top, width: tagSize.width, height: tagSize.height)
            computedTags.append((tagFrame, tagInfo))
            left += tagSize.width + tagPaddingH
        }

        // 第一行第一个tag即超出，需用截断字符填充满
        if computedTags.isEmpty, var tagInfo = tagInfos.first {
            let tagSize = sizeFor(size, tagInfo: tagInfo, font: font)
            let tagFrame = CGRect(x: 0, y: 0, width: size.width, height: tagSize.height)
            computedTags.append((tagFrame, tagInfo))
        }

        // 计算容器size
        var maxWidth: CGFloat = 0
        var maxHeight: CGFloat = 0
        computedTags.forEach { tagInfo in
            maxWidth = max(maxWidth, tagInfo.frame.maxX)
            maxHeight = max(maxHeight, tagInfo.frame.maxY)
        }
        return (CGSize(width: maxWidth, height: maxHeight), computedTags)
    }

    private class func sizeFor(_ size: CGSize, tagInfo: TagInfo, font: UIFont) -> CGSize {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        paragraphStyle.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        let tagSize = NSAttributedString(
            string: tagInfo.text,
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
        ).componentTextSize(for: CGSize(width: CGFloat(MAXFLOAT), height: size.height), limitedToNumberOfLines: 1)
        return CGSize(width: tagSize.width + textPadding.left + textPadding.right, height: tagSize.height + textPadding.top + textPadding.bottom)
    }

    private static func config(tag: PaddingLabel, tagInfo: TagInfo, font: UIFont) {
        tag.padding = textPadding
        tag.font = font
        tag.text = tagInfo.text
        tag.layer.cornerRadius = 4
        tag.clipsToBounds = true
        tag.textColor = tagInfo.textColor
        tag.backgroundColor = tagInfo.backgroundColor
    }
}
