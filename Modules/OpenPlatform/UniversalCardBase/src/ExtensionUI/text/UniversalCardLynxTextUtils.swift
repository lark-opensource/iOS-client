//
//  UniversalCardLynxTextUtils.swift
//  LarkMessageCard
//
//  Created by majiaxin.jx on 2022/11/22.
//

import Foundation
import LKRichView
import LarkEmotion
import LarkExtensions
import UniverseDesignColor
import RustPB
import LarkRichTextCore

enum ElementTag: Int8, LKRichElementTag {
    case container = 0
    case link = 1
    case at = 2
    case codeBlock = 100
    case listItemImg = 101
    var typeID: Int8 { return rawValue }
}

struct Styles {
    // 默认内边距, 避免部分太大的 emoji 被截断
    static let defaultTextPadding: NumbericValue = NumbericValue.em(0.1)
    static let defaultTextPaddingPixel: CGFloat = 1
    static let textFont: UIFont = UIFont.systemFont(ofSize: 14)
    static let maxFontSize: CGFloat = 16
    static let tagPaddingHorizontal: CGFloat = 4
    static let tagPaddingVertical: CGFloat = 2
    static let tagMarginHorizontal: CGFloat = 2
    static let tagBorderNormalRadius: CGFloat = 4
    static let tagBorderTableRadius: CGFloat = 10
    static let minTextSize: CGFloat = 9
    static let imgHeightWidthRatioLimit: CGFloat = 16.0 / 9
}

extension LKRichElement {
    static func richElement(
        fromTextViewProps props: TextViewProps,
        atUsers: [String: UniversalCardLynxAtUser],
        images: [String : Basic_V1_RichTextElement.ImageProperty]?,
        limitWidth: CGFloat,
        isME:  (String) -> Bool
    ) -> LKRichElement {
        let textViewContainer = LKBlockElement(tagName: ElementTag.container)
        var defaultColor: UIColor?
        if let color = props.contentProps?.first(where: { $0.plainTextProps?.textColor != nil })?.plainTextProps?.textColor {
            defaultColor = UIColor.btd_color(withARGBHexString: color)
        }
        textViewContainer.style.from(
            textViewStyle: props,
            lineHeight: Self.getLineHeight(props: props),
            defaultColor: defaultColor
        )
        textViewContainer.style.maxWidth(.point(limitWidth))
        
        let disableAtStyle = props.disableAtStyle ?? false
        let disableTagStyle = props.disableTagStyle ?? false
        let isFontSizeLimite = props.isFontSizeLimit ?? false
        // 根组件的子节点
        var textViewChildrens: [Node] = []
        // 临时存储容器
        var tempChildrens: [Node] = []
        
        func appendBlockElement(el: LKBlockElement) {
            if !tempChildrens.isEmpty {
                let blockElement = LKBlockElement(tagName: ElementTag.container)
                // 保证根组件的子节点宽度撑满，否则会因为自适应导致对齐方式出错
                blockElement.style.width(.percent(100))
                blockElement.children(tempChildrens)
                if let node = tempChildrens.last { blockElement.style.color(node.style.color) }
                tempChildrens = []
                textViewChildrens.append(blockElement)
            }
            textViewChildrens.append(el)
        }

        /*
         * tags 的计算逻辑, 用于解决 richview 无法准确的末尾截断 text_tag 导致截断时 ... 显示不全. 所以内部做计算,自己加 ...
         * 1. 非特化逻辑, 预期所有组件都要参与计算, 因为存在混排情况. 目前仅实现了纯 textTag 不考虑混排场景.
         * 2. 混排场景在裁剪时应该也会因为宽度计算出问题, 后续有需求需要将每个 element 宽度返回
         */
        var currentWidth: CGFloat = 0
        var widthNotEnough: Bool = false
        var currentLine = 1
        let maxLine = props.maxLines ?? Int.max
        // 逐个解析内部子元素
        if let tags = props.contentProps {
            tags.enumerated().forEach { (index, contentProps) in
                // 子元素的限制宽度需要去掉父元素的内边距
                let limitWidth = limitWidth - Styles.defaultTextPaddingPixel * 2
                // text tag
                if let props = contentProps.textTagProps, let content = props.content {
                    // 空间不足, 直接结束
                    guard !widthNotEnough else { return }
                    // 获取字体
                    var font = UIFont.systemFont(ofSize: 10)
                    if let fontSize = props.textSize {
                        font = UIFont.systemFont(ofSize: fontSize, weight: props.tagStyle == .table ? .semibold : .medium)
                    }
                    // 省略符宽度
                    let ellipsisWidth = String("...").getStrWidth(font: font) + 1
                    // 标签宽度
                    let tagWidth = String(content).getStrWidth(font: font,weight: props.tagStyle == .table ? .semibold : .medium)
                        + (disableTagStyle ? CGFloat(0) : Styles.tagPaddingHorizontal * 2)
                    let spaceWidth = getTextTagSpaceWidth(currentChildren: tempChildrens)
                    tempChildrens.append(spaceElement(width: spaceWidth))
                    currentWidth += spaceWidth
                    let isLastTag = (index == tags.count - 1)
                    let isLastLine = currentLine == maxLine
                    let isNewLine = currentWidth == 0

                    // Case 1: 当前行空间足够的情况, 直接添加标签
                    let isCurrentLineEnough =
                    // 新行,无论如何都放一个
                    isNewLine ||
                    // Case 1-1: 不是最后一行, 并且剩余空间足够
                    (!isLastLine && currentWidth + tagWidth < limitWidth) ||
                    // Case 1-2: 是最后一行, 且非最后一个, 且剩余空间(包括...) 足够
                    (isLastLine && !isLastTag && currentWidth + tagWidth < limitWidth - ellipsisWidth) ||
                    // Case 1-3: 是最后一行, 且是最后一个, 且剩余空间(包括...) 足够, 也是直接添加标签
                    (isLastLine && isLastTag && currentWidth + tagWidth < limitWidth)

                    // Case 2: 剩余空间不够, 且换行空间足够, 直接换行加入标签
                    let isNewLineEnough = !isCurrentLineEnough && !isLastLine &&
                    (
                        // Case 2-1: 不是倒数第二行, 直接放入整个元素
                        (currentLine != maxLine - 1) ||
                        // Case 2-1: 是倒数第二行, 同时是最后一个元素, 直接放入整个元素
                        (currentLine == maxLine - 1 && isLastTag) ||
                        // Case 2-1: 是倒数第二行, 不是最后一个元素, 在空间足够的情况下放入元素
                        (currentLine == maxLine - 1 && !isLastTag && tagWidth < limitWidth - ellipsisWidth)
                    )

                    // 这行和换行空间都不够, 直接插入 ... 结束
                    // 若是新行,且不是最后一行,或是最后一个, 则以省略的方式插入.
                    guard isCurrentLineEnough || isNewLineEnough || (isNewLine && (!isLastLine || isLastTag))  else {
                        textViewContainer.style.lineCamp(.none)
                        let text = LKTextElement(text: "...")
                        text.style.font(UIFont.systemFont(ofSize: 10))
                        text.style.color(UIColor.ud.textTitle)
                        tempChildrens.append(text)
                        widthNotEnough = true
                        return
                    }
                    if !isLastLine && !isCurrentLineEnough && isNewLineEnough {
                        tempChildrens.append(LKTextElement(text: "\n"))
                        currentLine += 1
                        currentWidth = 0
                    }
                    let (textTag, tagWidthResult) = textTagElement(
                         props: props,
                         isSizeLimit: true,
                         limitWidth: isLastLine && !isLastTag ? limitWidth - ellipsisWidth : limitWidth,
                         disableTagStyle: disableTagStyle,
                         verticalAlign: .middle
                    )
                    currentWidth += tagWidthResult
                    tempChildrens.append(textTag)
                    return
                }
                
                if let tag = tempChildrens.last?.tag, tag == Tag.textTagContainer.rawValue, !widthNotEnough {
                    tempChildrens.append(self.spaceElement(width: Styles.tagMarginHorizontal * 2))
                    currentWidth += Styles.tagMarginHorizontal * 2
                }
                
                // 纯文本
                if let props = contentProps.plainTextProps,
                   let text = plainTextElement(props: props, isSizeLimit: isFontSizeLimite, limitWidth: limitWidth) {
                    if let maxLines = props.maxLines { currentLine += maxLines }
                    // 若当前生成节点为 block 元素, 为了避免后面的其他元素受到影响, 将前后的元素也打包到 block 中
                    if let textBlock = text as? LKBlockElement {
                        appendBlockElement(el: textBlock)
                    } else {
                        tempChildrens.append(text)
                    }
                    return
                }
                // at
                if let props = contentProps.atProps,
                   let at = atElement(props: props, atUsers: atUsers, isME: isME, disableAtStyle: disableAtStyle, isSizeLimit: isFontSizeLimite) {
                    tempChildrens.append(at)
                    return
                }
                // link
                if let props = contentProps.linkProps,
                   let link = linkElement(props: props, isSizeLimit: isFontSizeLimite){
                    tempChildrens.append(link)
                    return
                }
                // emotion
                if let props = contentProps.emojProps,
                   let emotion = emotionElemnet(props: props, isSizeLimit: isFontSizeLimite) {
                    tempChildrens.append(emotion)
                    return
                }
                // code block
                if let codeBlockProps = contentProps.codeBlockProps,
                   let codeProperty = try? Basic_V1_RichTextElement.CodeBlockV2Property(jsonString: codeBlockProps) {
                    let elementID = contentProps.id ?? UUID().uuidString
                    let codeBlock = codeBlockElement(property: codeProperty, elementID: elementID)
                    appendBlockElement(el: codeBlock)
                    return
                }
                // list
                if let listProps = contentProps.listProps {
                    let list = listElement(props: listProps, atUsers: atUsers, images: images, limitWidth: limitWidth, disableAtStyle: disableAtStyle, disableTagStyle: disableTagStyle, isFontSizeLimit: isFontSizeLimite, isMe: isME)
                    appendBlockElement(el: list)
                    return
                }
            }
            if textViewChildrens.count == 0 {
                textViewContainer.children(tempChildrens)
            } else {
                let blockElement = LKBlockElement(tagName: ElementTag.container)
                blockElement.style.width(.percent(100))
                blockElement.children(tempChildrens)
                blockElement.style.padding(top: Styles.defaultTextPadding, bottom: Styles.defaultTextPadding)
                if let node = tempChildrens.last { blockElement.style.color(node.style.color) }
                textViewChildrens.append(blockElement)
                textViewContainer.children(textViewChildrens)
            }
        }
        return textViewContainer
    }
    
    private static func spaceElement(width: CGFloat) -> Node {
        let text = LKInlineElement(tagName: Tag.container)
        text.style.width(.point(0.1))
        text.style.padding(right: .point(width/2), left: .point(width/2))
        return text
    }
    
    private static func getTextTagSpaceWidth(currentChildren: [Node]) -> CGFloat {
        if currentChildren.isEmpty {
            return 0
        } else if let node = currentChildren.last, node.hasClassName(ClassName.br) {
            return 0
        } else if let tag = currentChildren.last?.tag, tag != Tag.textTagContainer.rawValue {
            return Styles.tagMarginHorizontal * 2
        } else {
            return Styles.tagMarginHorizontal
        }
    }
    
    // 标签组件
    private static func textTagElement(
        props: TextTagProps,
        isSizeLimit: Bool,
        limitWidth: CGFloat,
        disableTagStyle: Bool,
        verticalAlign: VerticalAlign
    ) -> (Node, CGFloat) {
        var width:CGFloat = 0
        var textContent = props.content ?? ""
        let fontWeight = props.tagStyle == .table ? FontWeight.semibold : FontWeight.medium
        let padding = Styles.tagPaddingHorizontal * 2
        if let content = props.content, let fontSize = props.textSize {
            let font = UIFont.systemFont(ofSize: fontSize, weight: props.tagStyle == .table ? .semibold : .medium)
            let contentWidth = content.getStrWidth(font: font, weight: fontWeight)
            if contentWidth > limitWidth - padding {
                // 省略号宽度
                let ellipsisWidth = String("...").getStrWidth(font: font, weight: fontWeight)
                textContent = content.cut(
                    cutWidth: limitWidth - ellipsisWidth - padding - 1, // 多预留一个像素, 消除小数引起的误差
                    font: font, weight: fontWeight
                ) + "..."
                width = String(textContent).getStrWidth(font: font, weight: fontWeight)
            } else {
                width = contentWidth
            }
        }
        let text = LKTextElement(text: textContent)
        text.style.from(textStyle: props, isSizeLimit: isSizeLimit)
        text.style.fontWeight(fontWeight)
        // 不需要 tag 样式时作为普通文本处理, 需要的时候套一层外壳加背景色
        if disableTagStyle {
            return (text, width)
        } else {
            width += padding
            let container = textTagContainer(props: props, isSizeLimit: isSizeLimit, verticalAlign: verticalAlign).addChild(text)
            container.style.lineCamp(.init(maxLine: 1, blockTextOverflow: ""))
            return (container, width)
        }
    }

    // 标签容器
    private static func textTagContainer(props: TextTagProps, isSizeLimit: Bool, verticalAlign: VerticalAlign) -> Node {
        let block = LKInlineBlockElement(tagName: Tag.textTagContainer)
        block.style.from(textStyle: props, isSizeLimit: isSizeLimit)
        if let bgColorToken = props.tagBGColorToken, let color = UDColor.getValueByBizToken(token: bgColorToken) {
            block.style.backgroundColor(color)
        }
        block.style.padding(
            top: .point(Styles.tagPaddingVertical),
            right: .point(Styles.tagPaddingHorizontal),
            bottom: .point(Styles.tagPaddingVertical),
            left: .point(Styles.tagPaddingHorizontal)
        )
        block.style.verticalAlign(verticalAlign)
        let borderRadius = props.tagStyle == TextTagProps.TagStyle.table ? Styles.tagBorderTableRadius : Styles.tagBorderNormalRadius
        let lengthSize = LengthSize(
            width: .point(borderRadius),
            height: .point(borderRadius)
        )
        block.style.borderRadius(
            topLeft: lengthSize,
            topRight: lengthSize,
            bottomRight: lengthSize,
            bottomLeft: lengthSize
        )
        return block
    }
    
    // 纯文本
    private static func plainTextElement(props: TextProps, isSizeLimit: Bool, limitWidth: CGFloat) -> Node? {
        let text = LKTextElement(text: props.content ?? "")
        text.classNames = [ClassName.plaintText]
        if (props.content == "\n") { text.classNames.append(ClassName.br)}
        text.style.color(UIColor.ud.textTitle)
        text.style.from(textStyle: props, isSizeLimit: isSizeLimit)
        text.style.lineCamp(LineCamp(maxLine: props.maxLines ?? 1, blockTextOverflow: "..."))
        // 如果有指定最大行数, 则使用 blockElement 嵌套, 以实现达到最大行数时裁剪的逻辑
        if let maxLines = props.maxLines, let font = text.style.font, let content = props.content {
            let textWidth = content.width(with: font)
            let lineCount = content.components(separatedBy: "\n").count - 1
            if textWidth > limitWidth * CGFloat(maxLines) || lineCount > maxLines {
                let container = LKBlockElement(tagName: Tag.container)
                container.style.lineCamp(LineCamp(maxLine: maxLines, blockTextOverflow: "..."))
                container.style.color(text.style.color)
                container.addChild(text)
                container.style.textAlign(.center)
                return container
            }
        }
        return text
    }
    
    // at 人
    private static func atElement(
        props: AtProps,
        atUsers: [String: UniversalCardLynxAtUser],
        isME:  (String) -> Bool,
        disableAtStyle: Bool,
        isSizeLimit: Bool
    ) -> Node? {
        func atContent(_ content: String?) -> String {
            guard let content = content else { return "@" }
            return content.starts(with: "@") ? content : "@\(content)"
        }

        let at = LKAnchorElement(tagName: ElementTag.at, classNames: [ClassName.atInnerGroup], text: atContent(props.content), href: "")
        at.style.from(textStyle: props, isSizeLimit: isSizeLimit)
        // props 中的 userid 是 op userid, atUser 中的 userid 是 LarkUserId
        if let userId = props.userId, let atUser = atUsers[userId], atUser.content.count > 0 {
            if disableAtStyle {
                //转发场景禁用at的样式
                let at = LKTextElement(text: atContent(atUser.content))
                at.style.color(UIColor.ud.textTitle)
                at.style.from(textStyle: props, isSizeLimit: isSizeLimit)
                return at
            }
            at.text = atContent(atUser.content)
            at.href = atUser.userID
            at.style.color(nil)
            if isME(userId) || isME(atUser.userID) {
                at.classNames = [ClassName.atMe]
                return LKInlineBlockElement(tagName: Tag.at, classNames: [ClassName.atMe]).addChild(at)
            } else {
                at.classNames = [ClassName.atInnerGroup]
                return LKInlineElement(tagName: Tag.at, classNames: [ClassName.atInnerGroup]).addChild(at)
            }
        }
        return at
    }
    
    // 超链接
    private static func linkElement(
        props: LinkProps,
        isSizeLimit: Bool
    ) -> Node? {
        let link = LKAnchorElement(tagName:ElementTag.link, text: props.content ?? "",  href: props.iosUrl ?? props.url)
        link.style.from(textStyle: props, isSizeLimit: isSizeLimit, defaultFontColor: UIColor.ud.textLinkNormal)
        if props.textDecoration == nil || props.textDecoration?.isEmpty == true {
            // 若textDecoration为nil时, 不设置line会导致link文本增加下划线产生视觉问题
            link.style.textDecoration(.init(line: TextDecoration.Line(), style: .solid))
        }
        return link
    }
    
    // 表情
    private static func emotionElemnet(
        props: EmojProps,
        isSizeLimit: Bool
    ) -> Node? {
        guard let emotionKey = props.key else { return nil }
        if let icon = EmotionResouce.shared.imageBy(key: emotionKey) {
            let imgElement = LKImgElement(
                classNames: [ClassName.emotion],
                img: icon.cgImage
            )
            let emojiText = EmotionResouce.shared.i18nBy(key: emotionKey) ?? emotionKey
            imgElement.defaultString = "[\(emojiText)]"
            return imgElement
        }
        // 如果表情违规的话需要显示违规提示文案
        if EmotionResouce.shared.isDeletedBy(key: emotionKey) {
            let illegaText = EmotionResouce.shared.getIllegaDisplayText()
            let textElement = LKTextElement(text: "[\(illegaText)]")
            textElement.style.color(UIColor.ud.N500)
            return textElement
        }
        return LKTextElement(text: "[\(emotionKey)]")
    }
    
    private static func codeBlockElement(property: Basic_V1_RichTextElement.CodeBlockV2Property, elementID: String) -> LKBlockElement {
        let codeElement = CodeParseUtils.parseToLKRichElement(property: property, elementId: "", config: CodeParseConfig())
        let contentElement = LKBlockElement(id: elementID, tagName: ElementTag.codeBlock).children([codeElement])
        return contentElement
    }
    
    private static func listElement(
        props: [ListItemProps],
        atUsers: [String: UniversalCardLynxAtUser],
        images: [String : Basic_V1_RichTextElement.ImageProperty]?,
        limitWidth: CGFloat,
        disableAtStyle: Bool,
        disableTagStyle: Bool,
        isFontSizeLimit: Bool,
        isMe: (String) -> Bool
    ) -> LKBlockElement {
        let rootElement = LKBlockElement(tagName: ElementTag.container)
        // 列表不受对齐属性控制, 强制左对齐
        rootElement.style.textAlign(.left)
        var children: [Node] = []
        for prop in props {
            if let elements = buildListItemContent(items: prop.items, atUsers: atUsers, images: images, limitWidth: limitWidth, disableAtStyle: disableAtStyle, disableTagStyle: disableTagStyle, isFontSizeLimit: isFontSizeLimit, isMe: isMe) {
                let listItem = listItemElement(props: prop, elements: elements)
                children.append(listItem)
            }
        }
        return rootElement.children(children)
    }
    
    private static func listItemElement(
        props: ListItemProps,
        elements: LKBlockElement
    ) -> LKBlockElement {
        let level = props.level ?? 0
        let order = props.order ?? 1
        let contents = LKListItemElement(tagName: Tag.li, iconColor: UIColor.ud.colorfulBlue, ulIconSize: 7, olIconSize: 15).children([elements])
        contents.isLineBreak = true
        
        if props.type == .ol {
            var olType: OrderListType
            switch level % 3 {
            case 0:
                olType = .number
            case 1:
                olType = .lowercaseA
            case 2:
                olType = .lowercaseRoman
            default:
                olType = .number
            }
            return buildListElement(level: level, create: {
                LKOrderedListElement(tagName: Tag.ol, start: order, olType: olType)
            }, contents: contents)
        } else {
            var ulType: UnOrderListType
            switch level % 3 {
            case 0:
                ulType = .disc
            case 1:
                ulType = .circle
            case 2:
                ulType = .square
            default:
                ulType = .disc
            }
            return buildListElement(level: level, create: {
                LKUnOrderedListElement(tagName: Tag.ul, ulType: ulType)
            }, contents: contents)
        }
    }
    
    private static func buildListElement(
        level: Int,
        create: () -> LKBlockElement,
        contents: LKListItemElement
    ) -> LKBlockElement {
        let rootList = create()
        var parentList = rootList
        for _ in 0..<level {
            let child = create()
            parentList.children([child])
            parentList = child
        }
        parentList.children([contents])
        return rootList
    }
    
    private static func buildListItemContent(
        items: [ContentProps]?,
        atUsers: [String: UniversalCardLynxAtUser],
        images: [String : Basic_V1_RichTextElement.ImageProperty]?,
        limitWidth: CGFloat,
        disableAtStyle: Bool,
        disableTagStyle: Bool,
        isFontSizeLimit: Bool,
        isMe: (String) -> Bool
    ) -> LKBlockElement? {
        guard let items = items, !items.isEmpty else {
            return nil
        }
        let container = LKBlockElement(tagName: ElementTag.container)
        var tempChildren: [Node] = []
        var children: [Node] = []
        let fontSize = getListFontSize(items: items, isFontSizeLimit: isFontSizeLimit)
        
        func appendTempChildren() {
            guard !tempChildren.isEmpty else {
                return
            }
            let blockElement = LKBlockElement(tagName: ElementTag.container)
            blockElement.style.width(.percent(100))
            blockElement.children(tempChildren)
            if let node = tempChildren.last { blockElement.style.color(node.style.color) }
            tempChildren = []
            children.append(blockElement)
        }
        
        for item in items {
            if let tagProps = item.textTagProps {
                let width = getTextTagSpaceWidth(currentChildren: tempChildren)
                tempChildren.append(spaceElement(width: width))
                let tag = listItemTagElement(props: tagProps, isSizeLimit: isFontSizeLimit, limitWidth: limitWidth, disableTagStyle: disableTagStyle, verticalAlign: .baseline)
                tempChildren.append(tag)
                continue
            }
            
            if let tag = tempChildren.last?.tag, tag == Tag.textTagContainer.rawValue {
                tempChildren.append(spaceElement(width: Styles.tagMarginHorizontal * 2))
            }
            
            if let plainTextProps = item.plainTextProps,
               let plainText = plainTextElement(props: plainTextProps, isSizeLimit: isFontSizeLimit, limitWidth: limitWidth) {
                tempChildren.append(plainText)
            } else if let atProps = item.atProps,
                      let at = atElement(props: atProps, atUsers: atUsers, isME: isMe, disableAtStyle: disableAtStyle, isSizeLimit: isFontSizeLimit) {
                tempChildren.append(at)
            } else if let linkProps = item.linkProps,
                      let link = linkElement(props: linkProps, isSizeLimit: isFontSizeLimit) {
                tempChildren.append(link)
            } else if let emojProps = item.emojProps,
                      let emotion = emotionElemnet(props: emojProps, isSizeLimit: isFontSizeLimit) {
                tempChildren.append(emotion)
            } else if let imageID = item.imageProps?.image_id,
                      let imgProps = images?[imageID] {
                appendTempChildren()
                let img = listItemImageElement(id: item.id ?? UUID().uuidString, props: imgProps, limitWidth: limitWidth, fontSize: fontSize)
                children.append(img)
            }
        }
        if children.isEmpty {
            return container.children(tempChildren)
        } else {
            appendTempChildren()
            return container.children(children)
        }
    }
    
    private static func listItemImageElement(id: String, props: Basic_V1_RichTextElement.ImageProperty, limitWidth: CGFloat, fontSize: CGFloat) -> LKBlockElement {
        let heightWidthRatio = min(CGFloat(props.originHeight) / CGFloat(props.originWidth), Styles.imgHeightWidthRatioLimit)
        // 传入最大宽度走attachment内部的宽度限制逻辑达到撑满一行的效果
        let size = CGSize(width: limitWidth, height: limitWidth * heightWidthRatio)
        let attachment = LKAsyncRichAttachmentImp(
            size: size,
            viewProvider: {
                UniversalCardListItemImageView(property: props, ratioLimit: Styles.imgHeightWidthRatioLimit)
            },
            ascentProvider: { _ in
                return UIFont.systemFont(ofSize: fontSize).ascender
            },
            verticalAlign: .baseline
        )
        
        let container = LKBlockElement(id: id, tagName: ElementTag.listItemImg)
        let element = LKAttachmentElement(attachment: attachment)
        return container.addChild(element)
    }
    
    private static func listItemTagElement(
        props: TextTagProps,
        isSizeLimit: Bool,
        limitWidth: CGFloat,
        disableTagStyle: Bool,
        verticalAlign: VerticalAlign
    ) -> Node {
        let text = LKTextElement(text: props.content ?? "")
        text.style.from(textStyle: props, isSizeLimit: isSizeLimit)
        text.style.fontWeight(FontWeight.medium)
        if disableTagStyle {
            return text
        } else {
            let container = textTagContainer(props: props, isSizeLimit: isSizeLimit, verticalAlign: verticalAlign).addChild(text)
            container.style.textOverflow(.noWrapEllipsis)
            return container
        }
    }
    
    private static func getListFontSize(items: [ContentProps], isFontSizeLimit: Bool) -> CGFloat {
        var fontSize = Styles.textFont.pointSize
        items.forEach { item in
            guard let size = item.plainTextProps?.textSize ?? item.atProps?.textSize ?? item.linkProps?.textSize else {
                return
            }
            fontSize = size
        }
        if isFontSizeLimit && fontSize > Styles.maxFontSize {
            fontSize = Styles.maxFontSize
        }
        return fontSize
    }
    
    private static func getLineHeight(props: TextViewProps) -> CGFloat {
        var maxTextSize: CGFloat = Styles.minTextSize
        props.contentProps?.forEach({ props in
            guard let fontSize = props.plainTextProps?.textSize ?? props.atProps?.textSize ?? props.linkProps?.textSize else {
                return
            }
            if fontSize > maxTextSize {maxTextSize = fontSize }
        })
        let lineHeight = UIFont.systemFont(ofSize: maxTextSize).figmaHeight
        return lineHeight
    }
}

extension LKRichStyle {
    fileprivate func from(
        textViewStyle style: TextViewStyle,
        lineHeight textViewLineHeight: CGFloat,
        defaultColor: UIColor? = nil
    ) {
        lineHeight(.point(textViewLineHeight))
        if let bgColor = style.bgColor {
            backgroundColor(UIColor.btd_color(withARGBHexString: bgColor))
        }
        if let maxLine = style.maxLines {
            lineCamp(LineCamp(maxLine: maxLine, blockTextOverflow: "..."))
        }
        if let textColor = style.textColor {
            color(UIColor.btd_color(withARGBHexString: textColor))
        } else if let defaultColor = defaultColor {
            color(defaultColor)
        } else {
            color(UIColor.ud.textTitle)
        }
        // iOS 只有行高, 目前这个值仅 Android 有用
        // let lineSpacing = style.lineSpacing
        // iOS 使用 LineCamp, 实际不生效, 仅 Android 有用
        // let ellipsize = style.ellipsize
        
        if let align = style.align {
            switch align {
            case .left: textAlign(.left)
            case .center: textAlign(.center)
            case .right: textAlign(.right)
            default: break
            }
        }
        let edge = Styles.defaultTextPadding
        var edges = Edges(edge, edge, edge, edge)
        if let paddingTop = style.paddingTop {edges.top = .point(paddingTop)}
        if let paddingLeft = style.paddingLeft {edges.left = .point(paddingLeft)}
        if let paddingBottom = style.paddingBottom {edges.bottom = .point(paddingBottom)}
        if let paddingRight = style.paddingRight {edges.right = .point(paddingRight)}
        padding(top: edges.top, right: edges.right, bottom: edges.bottom, left: edges.left)
        verticalAlign(.middle)
    }
    
    fileprivate func from(textStyle style: TextStyle, isSizeLimit: Bool, defaultFontColor: UIColor? = nil) {
        
        // 字体尺寸 计算
        var size = Styles.textFont.pointSize
        if let inputSize = style.textSize {
            size = inputSize
        }
        
        if isSizeLimit && size > Styles.maxFontSize  {
            size = Styles.maxFontSize
        }

        font(UIFont.systemFont(ofSize: size))
        fontSize(.point(size))

        // 字体颜色 计算
        if let textColorToken = style.textColorToken, let textColor = UDColor.getValueByBizToken(token: textColorToken) {
            color(textColor)
        } else if let textColor = style.textColor {
            color(UIColor.btd_color(withARGBHexString: textColor))
        } else {
            if let defaultFontColor = defaultFontColor {
                color(defaultFontColor)
            } else {
                color(UIColor.ud.textTitle)
            }
        }
        // 字体背景色 计算
        if let bgColor = style.textBgColor {
            backgroundColor(UIColor.btd_color(withARGBHexString: bgColor))
        }
        
        // 字体样式 计算
        var lineSet = TextDecoration.Line()
        var isBold = false
        var isItalic = false
        if let decoration = style.textDecoration {
            decoration.forEach { decoration in
                switch decoration {
                case .strikethrough: lineSet.insert(.lineThrough)
                case .underline: lineSet.insert(.underline)
                case .bold: isBold = true
                case .italic: isItalic = true
                case .unknown: break
                }
            }
            textDecoration(.init(line: lineSet, style: .solid))
            if isBold { fontWeight(.semibold)}
            if isItalic { fontStyle(.italic)}
        }
    }
}
