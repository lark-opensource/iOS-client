//
//  NewMomentsUserInfoAndCreateTimeView.swift
//  Moment
//
//  Created by ByteDance on 2023/3/28.
//

import Foundation
import UIKit
import UniverseDesignColor
import CoreText
import LKCommonsLogging

private let emptyPlaceholder = " "//一个length为1的占位符。本来用的"\u{FFFC}",但它在iOS17上有bug。
final class NewMomentsUserInfoAndCreateTimeView: UIView {
    static let logger = Logger.log(NewMomentsUserInfoAndCreateTimeView.self, category: "Module.Moments.NewMomentsUserInfoAndCreateTimeView")

    struct MomentsUserAndCreateTimeInfo: Hashable {
        /// 名字属性
        var nameText: String
        /// 是否是官方号
        var isOfficialUser: Bool
        /// 额外展示的profile字段
        var extraFields: [String]
        /// 时间属性
        var createTimeText: String?
        /// 名字后面是否需要换行展示
        var newLineAfterName: Bool
        /// 名字字体
        var nameFont: UIFont
        /// 名字颜色
        var nameColor: UIColor
        /// extraFields、time的字体
        var subInfoFont: UIFont
        /// extraFields、time的颜色
        var subInfoColor: UIColor

        init(nameText: String,
             isOfficialUser: Bool,
             extraFields: [String],
             createTime: String? = nil,
             newLineAfterName: Bool,
             nameFont: UIFont,
             nameColor: UIColor,
             subInfoFont: UIFont,
             subInfoColor: UIColor) {
            self.nameText = nameText
            self.isOfficialUser = isOfficialUser
            self.extraFields = extraFields
            self.createTimeText = createTime
            self.newLineAfterName = newLineAfterName
            self.nameFont = nameFont
            self.nameColor = nameColor
            self.subInfoFont = subInfoFont
            self.subInfoColor = subInfoColor
        }
    }

    lazy var contentView: ComplexLabel = {
        return ComplexLabel(maxWidth: self.frame.width)
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(contentView)
    }

    func updateView(momentsUserAndCreateTimeInfo: MomentsUserAndCreateTimeInfo) {

        let types = Self.generateComplexLabelTypes(momentsUserAndCreateTimeInfo: momentsUserAndCreateTimeInfo)
        self.contentView.setContent(types)
    }

    func updateView(layoutInfo: ComplexLabelLayoutInfo) {
        self.contentView.applyLayoutInfo(layoutInfo)
    }

    static func generateComplexLabelTypes(momentsUserAndCreateTimeInfo: MomentsUserAndCreateTimeInfo) -> [ComplexLabelType] {
        var types = [ComplexLabelType]()
        types.append(.text(params: .init(text: momentsUserAndCreateTimeInfo.nameText,
                                         maxLine: 0,
                                         newLine: false,
                                         leftMargin: 0,
                                         font: momentsUserAndCreateTimeInfo.nameFont,
                                         color: momentsUserAndCreateTimeInfo.nameColor)))
        if momentsUserAndCreateTimeInfo.isOfficialUser {
            types.append(.view(params: .init(viewBlock: {
                OfficialUserLabel()
            }, size: OfficialUserLabel.suggestSize, leftMargin: 6)))
        }
        if momentsUserAndCreateTimeInfo.newLineAfterName {
            types.append(.newLine)
        }
        if !momentsUserAndCreateTimeInfo.extraFields.isEmpty {
            types.append(.text(params: .init(text: momentsUserAndCreateTimeInfo.extraFields[0],
                                             maxLine: 2,
                                             newLine: false,
                                             leftMargin: 6,
                                             font: momentsUserAndCreateTimeInfo.subInfoFont,
                                             color: momentsUserAndCreateTimeInfo.subInfoColor)))
            if momentsUserAndCreateTimeInfo.extraFields.count > 1 {
                types.append(.devide(params: .init(viewBlock: {
                    let view = UIView()
                    view.backgroundColor = UIColor.ud.lineDividerDefault
                    return view
                }, size: CGSize(width: 1, height: 10), leftMargin: 6, verticalLayout:
                        .bottom(margin: (momentsUserAndCreateTimeInfo.subInfoFont.lineHeight - 10) / 2))))
                types.append(.text(params: .init(text: momentsUserAndCreateTimeInfo.extraFields[1],
                                                 maxLine: 2,
                                                 newLine: false,
                                                 leftMargin: 6,
                                                 font: momentsUserAndCreateTimeInfo.subInfoFont,
                                                 color: momentsUserAndCreateTimeInfo.subInfoColor)))

                if momentsUserAndCreateTimeInfo.extraFields.count > 2 {
                    assertionFailure("only support less or equal to 2")
                }
            }
        }
        if let createTimeText = momentsUserAndCreateTimeInfo.createTimeText {
            types.append(.view(params: .init(viewBlock: {
                let view = UILabel()
                view.text = momentsUserAndCreateTimeInfo.createTimeText
                view.font = momentsUserAndCreateTimeInfo.subInfoFont
                view.textColor = momentsUserAndCreateTimeInfo.subInfoColor
                return view
            }, size: .init(width: createTimeText.lu.width(font: momentsUserAndCreateTimeInfo.subInfoFont), height: momentsUserAndCreateTimeInfo.subInfoFont.lineHeight),
                                             leftMargin: 8)))
        }

        return types
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

struct ComplexLabelTextParams {
    let text: String
    let maxLine: Int
    let newLine: Bool
    let leftMargin: CGFloat
    let font: UIFont
    let color: UIColor
}
struct ComplexLabelViewAndDevideParams {
    enum VerticalLayoutType {
        case center
        case bottom(margin: CGFloat)
    }
    let viewBlock: (() -> UIView)
    let size: CGSize
    let leftMargin: CGFloat
    let verticalLayout: VerticalLayoutType

    init(viewBlock: @escaping () -> UIView, size: CGSize, leftMargin: CGFloat, verticalLayout: VerticalLayoutType = .center) {
        self.viewBlock = viewBlock
        self.size = size
        self.leftMargin = leftMargin
        self.verticalLayout = verticalLayout
    }
}

enum ComplexLabelType {
    case newLine
    case text(params: ComplexLabelTextParams)
    case view(params: ComplexLabelViewAndDevideParams)
    case devide(params: ComplexLabelViewAndDevideParams) //特点：如果出现在一行的开头或末尾，则会不展示

    var leftMargin: CGFloat {
        switch self {
        case .devide(let params):
            return params.leftMargin
        case .view(let params):
            return params.leftMargin
        case .text(let params):
            return params.leftMargin
        case .newLine:
            return 0
        }
    }
}
class ComplexLabelItem {
    private let lineSpacing: CGFloat = {
        if #unavailable(iOS 14.0) {
            //iOS13及以下系统上 设置了行间距后布局计算会有问题 @jiaxiao
            return 0
        } else {
            return 6
        }
    }()
    let type: ComplexLabelType
    lazy var view: UIView? = {
        switch self.type {
        case .text(let params):
            let label = UILabel()
            label.numberOfLines = params.maxLine
            label.text = params.text
            label.backgroundColor = .clear
            label.font = params.font
            label.textColor = params.color
            return label
        case .view(let params):
            return params.viewBlock()
        case .devide(let params):
            return params.viewBlock()
        case .newLine:
            return nil
        }
    }()

    init(type: ComplexLabelType) {
        self.type = type
    }

    //（当前行剩余的）宽度能否展示下至少一个单词或一个view
    private func canDisplayWith(remainWidth: CGFloat) -> Bool {
        switch self.type {
        case .text(let params):
            //首位会有一个占位符emptyPlaceholder
            let ctString = CTTypesetterCreateWithAttributedString(getAttributedString(lineBreakMode: .byWordWrapping, lastFont: params.font, offsetX: 0))
            let emptyPlaceholderWidth = NSAttributedString(string: emptyPlaceholder, attributes: [.font: params.font])
                .boundingRect(with: UIScreen.main.bounds.size, context: nil).width
            let length = CTTypesetterSuggestLineBreak(ctString, 0, Double(remainWidth - params.leftMargin + emptyPlaceholderWidth))
            //如果length为1，表示仅能展示下占位符emptyPlaceholder，即实际上会直接换行。
            return length > 1
        case .devide(let params):
            return params.leftMargin + params.size.width <= remainWidth
        case .view(let params):
            return params.leftMargin + params.size.width <= remainWidth
        case .newLine:
            return true
        }
    }

    private func getAttributedString(lineBreakMode: NSLineBreakMode, lastFont: UIFont?, offsetX: CGFloat) -> NSAttributedString {
        guard case .text(let params) = type else {
            assertionFailure("unexpected type")
            return NSAttributedString(string: "")
        }
        var emptyPlaceholderAttrString: NSMutableAttributedString?
        if let lastFont = lastFont {
            //这个字符不会渲染，仅用于占个行高。保险起见color设置为clear
            emptyPlaceholderAttrString = NSMutableAttributedString(string: emptyPlaceholder, attributes: [.font: lastFont,
                                                                                                          .foregroundColor: UIColor.clear])
        }
        var emptyPlaceholderWidth = emptyPlaceholderAttrString?.boundingRect(with: UIScreen.main.bounds.size, context: nil).width ?? 0

        let paragraph = NSMutableParagraphStyle()
        paragraph.firstLineHeadIndent = offsetX == 0 ? 0 : offsetX + params.leftMargin - emptyPlaceholderWidth
        paragraph.lineBreakMode = lineBreakMode
        paragraph.lineSpacing = self.lineSpacing
        if #unavailable(iOS 15.0) {
            //iOS14以下不指定paragraph.minimumLineHeight的话 layoutManager算的文字高度会偏低 @jiaxiao
            paragraph.minimumLineHeight = params.font.lineHeight
        }
        let attributeString = NSMutableAttributedString(string: params.text, attributes: [
            .paragraphStyle: paragraph,
            .font: params.font,
            .foregroundColor: params.color
        ])
        if let emptyPlaceholderAttrString = emptyPlaceholderAttrString {
            emptyPlaceholderAttrString.addAttribute(.paragraphStyle, value: paragraph, range: .init(location: 0, length: emptyPlaceholderAttrString.length))
            attributeString.insert(emptyPlaceholderAttrString, at: 0)
        }
        return attributeString
    }

    private func nextLineOffset(offset: CGPoint, font: UIFont?, viewHeight: CGFloat?) -> CGPoint {
        return .init(x: 0, y: offset.y + (font?.lineHeight ?? viewHeight ?? 0) + self.lineSpacing)
    }

    struct LayoutResult {
        let layoutInfo: ComplexLabelItemLayoutInfo
        let offset: CGPoint
        let currentLineFont: UIFont?
        let currentLineHeight: CGFloat
        init(layoutInfo: ComplexLabelItemLayoutInfo, offset: CGPoint, currentLineFont: UIFont?, viewHeight: CGFloat?) {
            self.layoutInfo = layoutInfo
            self.offset = offset
            self.currentLineFont = currentLineFont
            self.currentLineHeight = currentLineFont?.lineHeight ?? viewHeight ?? 0
        }
    }

    func layout(maxWidth: CGFloat, offset: CGPoint, lastFont: UIFont?, minHeight: CGFloat?, nextItem: ComplexLabelItem?) -> LayoutResult {
        func nextLineOffset() -> CGPoint {
            return self.nextLineOffset(offset: offset, font: lastFont, viewHeight: minHeight)
        }
        func getX() -> CGFloat {
            if offset.x == 0 {
                return 0
            }
            return offset.x + self.type.leftMargin
        }

        if offset.x > 0,
           !self.canDisplayWith(remainWidth: maxWidth - offset.x) {
            return layout(maxWidth: maxWidth, offset: nextLineOffset(), lastFont: nil, minHeight: nil, nextItem: nextItem)
        }
        switch self.type {
        case .newLine:
            if offset.x == 0 {
                return LayoutResult(layoutInfo: ComplexLabelItemLayoutInfo(item: self, frame: .zero), offset: offset, currentLineFont: lastFont, viewHeight: minHeight)
            }
            return LayoutResult(layoutInfo: ComplexLabelItemLayoutInfo(item: self, frame: .zero), offset: nextLineOffset(), currentLineFont: nil, viewHeight: nil)
        case .text:
            return layoutText(maxWidth: maxWidth, offset: offset, lastFont: lastFont, minHeight: minHeight, nextItem: nextItem)
        case .devide(let params):
            guard let nextItem = nextItem,
                  offset.x != 0 else {
                return LayoutResult(layoutInfo: ComplexLabelItemLayoutInfo(item: self,
                                                                           frame: .zero) { [weak self] in
                    self?.view?.isHidden = true
                }, offset: offset, currentLineFont: lastFont, viewHeight: minHeight)
            }
            if !nextItem.canDisplayWith(remainWidth: maxWidth - offset.x - params.size.width - params.leftMargin) {
                return LayoutResult(layoutInfo: ComplexLabelItemLayoutInfo(item: self,
                                                                           frame: .zero) { [weak self] in
                    self?.view?.isHidden = true
                }, offset: nextLineOffset(), currentLineFont: nil, viewHeight: nil)
            }
            var lineHeight = lastFont?.lineHeight ?? max(minHeight ?? 0, params.size.height)
            var minY: CGFloat
            switch params.verticalLayout {
            case .center:
                minY = offset.y + (lineHeight - params.size.height) / 2
            case .bottom(let margin):
                minY = offset.y + lineHeight - params.size.height - margin
            }
            return LayoutResult(layoutInfo: ComplexLabelItemLayoutInfo(item: self,
                                                                       frame: .init(x: getX(),
                                                                                    y: minY,
                                                                                    width: params.size.width,
                                                                                    height: params.size.height)) { [weak self] in
                self?.view?.isHidden = false
            }, offset: .init(x: getX() + params.size.width, y: offset.y), currentLineFont: lastFont, viewHeight: params.size.height)
        case .view(let params):
            var lineHeight = lastFont?.lineHeight ?? max(minHeight ?? 0, params.size.height)
            var minY: CGFloat
            switch params.verticalLayout {
            case .center:
                minY = offset.y + (lineHeight - params.size.height) / 2
            case .bottom(let margin):
                minY = offset.y + lineHeight - params.size.height - margin
            }
            return LayoutResult(layoutInfo: ComplexLabelItemLayoutInfo(item: self,
                                                                       frame: .init(x: getX(),
                                                                                    y: minY,
                                                                                    width: params.size.width,
                                                                                    height: params.size.height)),
                                offset: .init(x: getX() + params.size.width, y: offset.y), currentLineFont: lastFont, viewHeight: params.size.height)
        }
    }

    private func layoutText(maxWidth: CGFloat, offset: CGPoint, lastFont: UIFont?, minHeight: CGFloat?, nextItem: ComplexLabelItem?) -> LayoutResult {
        guard case .text(let params) = type else {
            assertionFailure("unexpected type")
            return LayoutResult(layoutInfo: ComplexLabelItemLayoutInfo(item: self, frame: .zero), offset: offset, currentLineFont: lastFont, viewHeight: minHeight)
        }
        guard !params.text.isEmpty else {
            return LayoutResult(layoutInfo: ComplexLabelItemLayoutInfo(item: self, frame: .zero), offset: offset, currentLineFont: lastFont, viewHeight: minHeight)
        }
        if params.newLine, offset.x > 0 {
            return layoutText(maxWidth: maxWidth, offset: nextLineOffset(offset: offset, font: lastFont, viewHeight: minHeight), lastFont: nil, minHeight: nil, nextItem: nextItem)
        }

        let layoutManager = NSLayoutManager()
        layoutManager.usesFontLeading = true
        let textContainer = NSTextContainer(size: .init(width: maxWidth, height: .greatestFiniteMagnitude))
        textContainer.lineBreakMode = .byWordWrapping
        textContainer.maximumNumberOfLines = 0
        textContainer.lineFragmentPadding = 0
        let textStorage = NSTextStorage(attributedString: self.getAttributedString(lineBreakMode: .byWordWrapping, lastFont: lastFont, offsetX: offset.x))
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let location = layoutManager.location(forGlyphAt: layoutManager.numberOfGlyphs - 1)
        var lastGlyphRect = layoutManager.boundingRect(forGlyphRange: .init(location: layoutManager.numberOfGlyphs - 1, length: 1), in: textContainer)

        if params.maxLine > 0 {
            var lineHeight = params.font.lineHeight
            var firstLineHeight = max(lastFont?.lineHeight ?? 0, lineHeight)
            var maxTotalHeight = firstLineHeight + (lineHeight + lineSpacing) * CGFloat(params.maxLine - 1)
            if lastGlyphRect.maxY > ceil(maxTotalHeight) {
                let lastLineMinY: CGFloat = params.maxLine == 1 ? 0 : maxTotalHeight - lineHeight
                let lastLineHeight: CGFloat = params.maxLine == 1 ? firstLineHeight : lineHeight
                lastGlyphRect = .init(x: maxWidth, y: lastLineMinY, width: 0, height: lastLineHeight)
            }
        }

        var breakLine: Bool = lastGlyphRect.minY > 0 //是否换行
        var biggerFont = (lastFont?.lineHeight ?? 0 > params.font.lineHeight) ? lastFont : params.font
        return LayoutResult(layoutInfo: ComplexLabelItemLayoutInfo(item: self,
                                                                   frame: .init(x: 0, y: offset.y, width: maxWidth, height: lastGlyphRect.maxY)) { [weak self] in
            guard let self = self,
                  let label = self.view as? UILabel else {
                assertionFailure("unexpected view")
                return
            }
            label.attributedText = self.getAttributedString(lineBreakMode: .byTruncatingTail, lastFont: lastFont, offsetX: offset.x)
        }, offset: .init(x: lastGlyphRect.maxX, y: offset.y + lastGlyphRect.minY),
                            currentLineFont: breakLine ? params.font : biggerFont,
                            viewHeight: breakLine ? nil : minHeight)

    }
}

class ComplexLabelItemLayoutInfo {
    var item: ComplexLabelItem
    var frame: CGRect
    var onApplyLayoutBlock: (() -> Void)? //这个block里的逻辑要保证在主线程执行
    init(item: ComplexLabelItem, frame: CGRect, onApplyLayoutBlock: (() -> Void)? = nil) {
        self.item = item
        self.frame = frame
        self.onApplyLayoutBlock = onApplyLayoutBlock
    }
}

class ComplexLabelLayoutInfo {
    var itemsLayoutInfo: [ComplexLabelItemLayoutInfo]
    var size: CGSize
    init(itemsLayoutInfo: [ComplexLabelItemLayoutInfo], size: CGSize) {
        self.itemsLayoutInfo = itemsLayoutInfo
        self.size = size
    }
}

class ComplexLabel: UIView {
    private var maxWidth: CGFloat {
        didSet {
            guard !content.isEmpty else { return }
            layout()
        }
    }
    private var content: [ComplexLabelItem] = []

    init(maxWidth: CGFloat) {
        self.maxWidth = maxWidth
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(_ types: [ComplexLabelType]) {
        self.content = types.compactMap({ type in
            ComplexLabelItem(type: type)
        })
        for view in self.subviews {
            view.removeFromSuperview()
        }
        for item in self.content {
            if let view = item.view {
                addSubview(view)
            }
        }
        layout()
    }

    // 当前这个ComplexLabel只在Component里用，按预期是走不到这条链路。如果以后走到了再多测测。 @jiaxiao
    private func layout() {
        NewMomentsUserInfoAndCreateTimeView.logger.info("ComplexLabel layout")
        let layoutInfo = Self.generateLayoutInfo(content: self.content, maxWidth: self.maxWidth)
        self.applyLayoutInfo(layoutInfo)
    }

    func applyLayoutInfo(_ layoutInfo: ComplexLabelLayoutInfo) {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        for itemLayoutInfo in layoutInfo.itemsLayoutInfo {
            if let view = itemLayoutInfo.item.view {
                addSubview(view)
                view.frame = itemLayoutInfo.frame
            }
            itemLayoutInfo.onApplyLayoutBlock?()
        }
    }

    static func generateLayoutInfo(types: [ComplexLabelType], maxWidth: CGFloat) -> ComplexLabelLayoutInfo {
        let content = types.compactMap({ type in
            ComplexLabelItem(type: type)
        })
        return generateLayoutInfo(content: content, maxWidth: maxWidth)
    }

    static func generateLayoutInfo(content: [ComplexLabelItem], maxWidth: CGFloat) -> ComplexLabelLayoutInfo {
        var itemsLayoutInfo = [ComplexLabelItemLayoutInfo]()
        var offset: CGPoint = .zero
        var lastFont: UIFont?
        var minHeight: CGFloat?
        var loggerAdditionalData = [String: String]()
        for (i, item) in content.enumerated() {
            var nextItem: ComplexLabelItem?
            if i < content.count - 1 {
                nextItem = content[i + 1]
            }
            let result = item.layout(maxWidth: maxWidth, offset: offset, lastFont: lastFont, minHeight: minHeight, nextItem: nextItem)
            itemsLayoutInfo.append(result.layoutInfo)
            offset = result.offset
            minHeight = result.currentLineHeight
            lastFont = result.currentLineFont
            loggerAdditionalData["frame\(i)"] = result.layoutInfo.frame.debugDescription
            loggerAdditionalData["offset\(i)"] = offset.debugDescription
        }
        let height = offset.x == 0 ? offset.y : offset.y + (minHeight ?? 0)
        let width = offset.y == 0 ? offset.x : maxWidth
        loggerAdditionalData["height"] = height.description
        loggerAdditionalData["width"] = width.description
        NewMomentsUserInfoAndCreateTimeView.logger.info("ComplexLabel applyLayoutInfo", additionalData: loggerAdditionalData)
        return .init(itemsLayoutInfo: itemsLayoutInfo, size: .init(width: width, height: height))
    }
}
