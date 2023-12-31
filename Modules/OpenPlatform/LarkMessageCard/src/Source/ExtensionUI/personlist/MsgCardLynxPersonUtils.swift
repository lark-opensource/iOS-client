//
//  MsgCardLynxPersonUtils.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2023/6/15.
//

import Foundation
import LKRichView
import LarkExtensions
import UniverseDesignFont
import UniverseDesignColor

// Float 的最大数,用于不定值计算
fileprivate let maxFloat = CGFloat.greatestFiniteMagnitude
// Size 的最大数,用于不定值计算
fileprivate let maxSize = CGSize(width: maxFloat, height: maxFloat)

struct PersonWithSize {
    let person: Person
    let index: Int
    let avatarSize: CGFloat
    let contentWidth: CGFloat
    let limitWidth: CGFloat
}

extension NumbericValue {
    // NumbericValue.value 便利构造函数
    fileprivate static func value(_ value: CGFloat) -> NumbericValue? {
        return NumbericValue(LKRichStyleValue(.inherit, value))
    }
}

extension Person {
    func getContent() -> String {
        return content ?? BundleI18n.LarkMessageCard.OpenPlatform_CardCompt_UnknownUser
    }
}

let containerPadding: CGFloat = 2
let avatarMarginRight: CGFloat = 4
let avatarDefaultPadding: CGFloat = -2

extension LKRichElement {
    
    static func richElement(
        formPersonListProps props: PersonListProps,
        limitWidth: CGFloat
    ) -> LKRichElement {
        let personList = LKBlockElement(tagName: Tag.container)
        let showAvatar = props.showAvatar ?? false
        let showName = props.showName ?? true
        guard showName || showAvatar else { return  personList}
        // 当前所有的子组件
        var childrenArr: [Node] = []
        personList.style.width(.point(limitWidth))
        if let align = props.align {
            switch align {
                case .left: personList.style.textAlign(.left)
                case .center: personList.style.textAlign(.center)
                case .right: personList.style.textAlign(.right)
                default: break
            }
        }
        personList.style.padding(top: .point(containerPadding), right: .point(0), bottom: .point(containerPadding), left: .point(0))

        if !showName && showAvatar {
            childrenArr = Self.parseAvatarListChildrenNode(formPersonListProps: props, limitWidth: limitWidth)
        } else {
            childrenArr = Self.parseNameListChildrenNode(formPersonListProps: props, limitWidth: limitWidth)
        }

        personList.children(childrenArr)
        return personList
    }

    // 将 personlist 数据解析为头像列表形式的数据
    static func parseAvatarListChildrenNode(
        formPersonListProps props: PersonListProps,
        limitWidth: CGFloat
    ) -> [Node] {
        var childrenArr: [Node] = []
        let avatarSize = props.styles.avatarSize
        let moreSize = props.styles.moreSize
        let moreColor = UIColor(hexString: props.styles.moreColor) ?? UIColor.ud.bgFiller
        let moreTextFont = UIFont.systemFont(ofSize: props.styles.moreTextSize)
        let moreTextColor = UIColor(hexString: props.styles.moreTextColor) ?? UIColor.ud.textLinkNormal
        let maxCount = props.styles.moreMaxCount
        let listElement = UniversalCardAvatarListElement(
            limitWidth: limitWidth,
            persons: props.persons,
            avatarSize: avatarSize,
            moreInfo: MoreInfo(
                moreSize: moreSize,
                moreColor: moreColor,
                moreTextColor: moreTextColor,
                moreTextFont: moreTextFont,
                moreMaxCount: maxCount
            )
        )
        let attachment = LKAttachmentElement(attachment: listElement)
        let moreContainer = LKInlineBlockElement(tagName: Tag.more, style: LKRichStyle()).addChild(attachment)
        childrenArr.append(moreContainer)
        return childrenArr
    }

    // 将 personlist 数据解析为人员列表形式的数据
    static func parseNameListChildrenNode(
        formPersonListProps props: PersonListProps,
        limitWidth: CGFloat
    ) -> [Node] {
        var childrenArr: [Node] = []
        let avatarSize = props.styles.avatarSize

        let nameFont = UIFont.systemFont(ofSize: props.styles.nameSize)
        let nameColor = UIColor(hexString: props.styles.nameColor) ?? UIColor.ud.textLinkNormal
        let moreSize = props.styles.moreSize
        let moreColor = UIColor(hexString: props.styles.moreColor) ?? UIColor.ud.bgFiller
        let moreTextFont = UIFont.systemFont(ofSize: props.styles.moreTextSize)
        let moreTextColor = UIColor(hexString: props.styles.moreTextColor) ?? UIColor.ud.textLinkNormal
        let margin = props.styles.margin
        let showAvatar = props.showAvatar ?? false
        // 限制行数, 开发者设的
        let limitLine = props.lines ?? Int.max
        // 限制宽度, 既行宽, 由父视图控制
        let lineWidth = CGFloat(limitWidth - 1)
        // 总个数
        let totalCount = props.persons.count
        // 省略号宽度
        let ellipsisWidth = String("...").getStrWidth(font: nameFont)
        // 当前所在行
        var currentLine = 1
        // 当前行 已用宽度
        var currentWidth = CGFloat(0)
        // 是否已经完成计算
        var isFinished = false


        func calculatePersonList(
            index: Int,
            person: Person
        ) {
            guard !isFinished else { return }
            // 是否是最后一个人
            let isLastPerson = index == props.persons.count - 1
            // 显示头像时, 是头像 + 间距,
            let widthWithoutName = showAvatar ? avatarSize + avatarMarginRight :
                // 不显示头像时根据是否最后一个, 来添加逗号宽度,
                isLastPerson ? 0 : String(
                    BundleI18n.LarkMessageCard.OpenPlatform_Common_Comma
                ).getWidth(font: nameFont)
            
            // 最长允许的人名宽度
            let maxNameWidth = lineWidth - ellipsisWidth - widthWithoutName
            // 是否最后一行
            let isLastLine = currentLine == limitLine
            // 是否新行
            let isNewLine = currentWidth == 0
            // 是否第一行
            let isFirstLine = currentLine == 1
            // 剩余宽度
            let leftWidth = lineWidth - currentWidth
            // 人名组件宽度
            let nameWidth = person.getContent().getStrWidth(font: nameFont)
            // 每个完整人名的右间距
            let marginRight = !isLastPerson && (showAvatar && leftWidth - nameWidth > margin.right) ? margin.right : 0
            let nameElement = Self.name(
                formPerson: PersonWithSize(
                    person: person,
                    index: index,
                    avatarSize: avatarSize,
                    contentWidth: nameWidth,
                    limitWidth: maxNameWidth - marginRight
                ),
                font: nameFont,
                textColor: nameColor,
                withAvatar: showAvatar,
                withSeparator: !showAvatar && !isLastPerson,
                marginTop: currentLine != 1 ? margin.top : 0,
                marginRight: marginRight
            )

            // 更多组件

            let moreWidth = showAvatar ? avatarSize : String(
                BundleI18n.LarkMessageCard.OpenPlatform_CardForMyAi_PplCntAppend(count: totalCount - (index + 1))
            ).getStrWidth(font: moreTextFont)

            // case 1: 放得下 人名 的场景:
            // case 1-1: 不是最后一行,且剩余的空间可以放得下 人名
            if !isLastLine && (nameWidth + widthWithoutName + marginRight < leftWidth) {
                childrenArr.append(nameElement)
                currentWidth += min(nameWidth + widthWithoutName + marginRight, leftWidth)
                return
            }
            // case 1-2: 不是最后一行, 且是新行, 直接放入人名(人名超长会截断), 并结束
            else if !isLastLine && isNewLine  {
                childrenArr.append(nameElement)
                currentWidth += min(nameWidth + widthWithoutName + marginRight, leftWidth)
                return
            }

            // case 1-3: 不是最后一行, 且完整的一行放不下人名, 且这行剩余的空间可以显示人名一个字以上, 则放入人名 + ...
            else if !isLastLine && (nameWidth + widthWithoutName > lineWidth) &&
                        (person.getContent().substring(to: 1).getWidth(font: nameFont) + widthWithoutName + ellipsisWidth < leftWidth) {
                let nameElement = Self.name(
                    formPerson: PersonWithSize(
                        person: person,
                        index: index,
                        avatarSize: avatarSize,
                        contentWidth: nameWidth,
                        limitWidth: leftWidth - ellipsisWidth - widthWithoutName
                    ),
                    font: nameFont,
                    textColor: nameColor,
                    withAvatar: showAvatar,
                    withSeparator: !showAvatar && !isLastPerson,
                    marginTop: currentLine != 1 ? margin.top : 0,
                    marginRight: 0
                )
                childrenArr.append(nameElement)
                currentWidth += min(Self.getElementWidth(element: nameElement), leftWidth)
                return
            }
            // case 1-4: 最后一行,且剩余的空间可以放得下 人名 + more
            else if isLastLine && (nameWidth + widthWithoutName + marginRight + moreWidth < leftWidth) {
                childrenArr.append(nameElement)
                currentWidth += min(nameWidth + widthWithoutName + marginRight, leftWidth)
                return
            }
            // case 7.4: 新增需求, 如果是第一行,第一个元素的情况下, 一个都放不下, 为了避免只有 (+ X),至少强行放入一个
            else if isFirstLine && isNewLine &&
                        (person.getContent().substring(to: 1).getWidth(font: nameFont) + widthWithoutName + ellipsisWidth + moreWidth < leftWidth) {
                let nameElement = Self.name(
                    formPerson: PersonWithSize(
                        person: person,
                        index: index,
                        avatarSize: avatarSize,
                        contentWidth: nameWidth,
                        limitWidth: leftWidth - ellipsisWidth - widthWithoutName - moreWidth
                    ),
                    font: nameFont,
                    textColor: nameColor,
                    withAvatar: showAvatar,
                    withSeparator: !showAvatar && !isLastPerson,
                    marginTop: currentLine != 1 ? margin.top : 0,
                    marginRight: 0
                )
                childrenArr.append(nameElement)
                currentWidth += min(Self.getElementWidth(element: nameElement), leftWidth)
                return
            }
            // case 1-5: 是最后一个人, 且这一行能放得下 并结束
            else if isLastPerson && (nameWidth + widthWithoutName < leftWidth) {
                childrenArr.append(nameElement)
                isFinished = true
                return
            }
            // case 1-6: 是最后一个人, 且是新行,  放入人名(人名超长会截断), 并结束
            else if isLastPerson && isNewLine {
                childrenArr.append(nameElement)
                isFinished = true
                return
            }


            // case 2: 放不下的场景
            // case 2-1: 当前不是最后一行: 换行,并且重新计算宽度
            if !isLastLine {
                currentWidth = 0
                currentLine += 1
                return calculatePersonList(
                    index: index,
                    person: person
                )
            }
            // case 2-2: 当前是最后一行, 放入 +more, 包含这个放不进的
            else {
                // 更多组件计数包含当前人名
                let moreElementWithThis = showAvatar ?
                    Self.avatarMoreElement(
                        count: totalCount - index,
                        maxCount: props.styles.moreMaxCount,
                        moreSize: moreSize,
                        moreColor: moreColor,
                        moreTextFont: moreTextFont,
                        moreTextColor: moreTextColor,
                        marginTop: margin.top
                    ) :
                    Self.textMoreElement(
                        count: totalCount - index,
                        maxCount: props.styles.moreMaxCount,
                        maxWidth: lineWidth,
                        moreTextFont: moreTextFont,
                        moreTextColor: moreTextColor
                    )
                childrenArr.append(moreElementWithThis)
                isFinished = true
                return
            }
        }

        for (index, person) in props.persons.enumerated() {
            guard !isFinished else { break }
            calculatePersonList(index: index, person: person)
        }
        return childrenArr
    }
    
    // 生成 + more 标签
    static func textMoreElement(
        count: Int,
        maxCount: Int,
        maxWidth: CGFloat,
        moreTextFont: UIFont,
        moreTextColor: UIColor
    ) -> LKRichElement {
        let style = LKRichStyle()
        style.maxWidth(NumbericValue.value(maxWidth))
        style.font(moreTextFont)
        style.fontSize(.point(moreTextFont.pointSize))
        style.color(moreTextColor)
        let element = LKTextElement(
            id: "", style: style, text: BundleI18n.LarkMessageCard.OpenPlatform_CardForMyAi_PplCntAppend(count: count)
        )
        // 使用块级元素包裹, 确保统一换行, 内部不出现折行
        return LKInlineBlockElement(tagName: Tag.more).addChild(element)
    }

    static func avatarMoreElement(
        count: Int,
        maxCount: Int,
        moreSize: CGFloat,
        moreColor: UIColor,
        moreTextFont: UIFont,
        moreTextColor: UIColor,
        marginTop: CGFloat
    ) -> LKRichElement {

        let textStyle = LKRichStyle()
        textStyle.verticalAlign(.middle)
        textStyle.textAlign(.center)
        textStyle.color(moreTextColor)
        textStyle.font(moreTextFont)
        textStyle.fontSize(.point(moreTextFont.pointSize))

        let element = LKTextElement(id: "", style: textStyle, text: "+\(count > maxCount ? 99 : count)")


        let textContainerStyle = LKRichStyle()
        textContainerStyle.height(.point(moreSize))
        textContainerStyle.width(.point(moreSize))
        let lengthSize = LengthSize(width: .point(moreSize/2), height: .point(moreSize/2))
        textContainerStyle.borderRadius(
            topLeft: lengthSize,
            topRight: lengthSize,
            bottomRight: lengthSize,
            bottomLeft: lengthSize
        )
        textContainerStyle.padding(
            top: .point((moreSize - moreTextFont.pointSize)/2 - 1),
            right: .point(avatarDefaultPadding),
            bottom: .point(0),
            left: .point(avatarDefaultPadding)
        )
        textContainerStyle.backgroundColor(moreColor)
        textContainerStyle.verticalAlign(.middle)
        textContainerStyle.textAlign(.center)
        let textContainer = LKInlineBlockElement(tagName: Tag.more, style: textContainerStyle).addChild(element)

        let containerStyle = LKRichStyle()
        containerStyle.padding(
            top: .point(marginTop),
            right: .point(0),
            bottom: .point(0),
            left: .point(0)
        )
        // 使用块级元素包裹, 确保统一换行, 内部不出现折行
        return LKInlineBlockElement(tagName: Tag.container, style: containerStyle).addChild(textContainer)
    }
    
    // 生成 人名 标签
    static func name(
        formPerson personInfo: PersonWithSize,
        font: UIFont,
        textColor: UIColor,
        withAvatar: Bool,
        withSeparator: Bool,
        marginTop: CGFloat,
        marginRight: CGFloat
    ) -> LKRichElement {
        var content = personInfo.person.getContent()
        if personInfo.contentWidth > personInfo.limitWidth {
            content = content.cut(cutWidth: personInfo.limitWidth, font: font) + "..."
        }
        let container = LKInlineBlockElement(id: personInfo.person.id ?? "", tagName: Tag.person)
        if (withAvatar) {
            let avatar = LKAttachmentElement(
                attachment: UniversalCardAvatarElement(
                    size: CGSize(width: personInfo.avatarSize, height: personInfo.avatarSize),
                    person: personInfo.person
                )
            )
            container.addChild(avatar)
            container.addChild(Self.spaceElement(width: avatarMarginRight))
            container.style.verticalAlign(VerticalAlign.middle)
            container.style.padding(
                top: .point(marginTop),
                right: .point(marginRight),
                bottom: .point(0),
                left: .point(0)
            )
        }

        let name = LKTextElement(style: Self.nameStyle(font: font, color: textColor), text: content)
        container.addChild(name)
        // 根据情况添加逗号
        if (withSeparator) { container.addChild(Self.commaElement(font: font)) }
        
        return container
    }

    private static func spaceElement(width: CGFloat) -> Node {
        let text = LKInlineElement(tagName: Tag.container)
        text.style.width(.point(0.1))
        text.style.padding(right: .point(width/2), left: .point(width/2))
        return text
    }
    
    static func nameStyle(font: UIFont, color: UIColor) -> LKRichStyle {
        let style = LKRichStyle()
        style.font(font)
        style.fontSize(.point(font.pointSize))
        style.color(color)
        style.textDecoration(.init(line: TextDecoration.Line(), style: .solid))
        return style
    }
    
    static func commaElement(font: UIFont) -> LKRichElement {
        let comma = LKTextElement(text: BundleI18n.LarkMessageCard.OpenPlatform_Common_Comma)
        comma.style.color(UIColor.ud.textPlaceholder)
        comma.style.font(font)
        comma.style.fontSize(.point(font.pointSize))
        return comma
    }
    
    static func getElementWidth(element: LKRichElement) -> CGFloat {
        return LKRichViewCore().createRenderer(element)?
            .layout(maxSize, context: nil)
            .width ?? 0
    }
}
