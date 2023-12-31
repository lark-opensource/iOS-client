//
//  ReferenceListLayout.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/4/10.
//

import Foundation
import LKRichView
import LarkRichTextCore
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTheme

/// layout后的结果
public class ReferenceListLayout {
    /// 提示文案、布局信息
    public var tripString: LKRichElement = LKTextElement(text: "")
    public var tripStringCore = LKRichViewCore()
    /// 文档内容、布局信息
    public var referenceList: LKRichElement = LKTextElement(text: "")
    public var referenceListCore = LKRichViewCore()
    /// 布局大小
    public var size: CGSize = .zero

    /// 设置padding、"..."等统一样式
    private static func fixElement(element: LKRichElement) -> LKRichElement {
        // 需要包一层LKInlineBlockElement，不然textOverflow不生效
        let inlineBlockElement = LKInlineBlockElement(tagName: RichViewAdaptor.Tag.span)
        inlineBlockElement.addChild(element)
        inlineBlockElement.style.textOverflow(.noWrapCustom("..."))
        // 设置"..."的字体大小、颜色、底部对齐
        inlineBlockElement.style.color(UIColor.ud.textLinkNormal)
        inlineBlockElement.style.fontSize(.point(16.auto()))
        inlineBlockElement.style.verticalAlign(.middle)
        // 让每个链接单独占一行，设置间距
        let blockElement = LKBlockElement(tagName: RichViewAdaptor.Tag.span)
        blockElement.addChild(inlineBlockElement)
        blockElement.style.margin(top: .point(0), right: .point(0), bottom: .point(ReferenceListView.verticalSpacing), left: .point(0))
        return blockElement
    }

    /// 展示所有文档
    public static func layoutForAll(props: ReferenceListViewProps, size: CGSize) -> ReferenceListLayout {
        let tripString = ReferenceListLayout.createTrip(props: props, icon: UDIcon.upBoldOutlined.ud.colorize(color: UIColor.ud.iconN2))
        // 引用内容，每个链接单独占一行，所以每个链接是个LKBlockElement，所以外层容器也是LKBlockElement
        let referenceList = LKBlockElement(tagName: RichViewAdaptor.Tag.span)
        props.referenceList.forEach({ referenceList.addChild(ReferenceListLayout.fixElement(element: $0)) })
        // 组装结果
        let layout = ReferenceListLayout()
        layout.tripString = tripString
        layout.tripStringCore.load(renderer: layout.tripStringCore.createRenderer(tripString))
        _ = layout.tripStringCore.layout(size)
        layout.referenceList = referenceList
        layout.referenceListCore.load(renderer: layout.referenceListCore.createRenderer(referenceList))
        _ = layout.referenceListCore.layout(size)
        layout.size = CGSize(
            width: max(layout.tripStringCore.size.width, layout.referenceListCore.size.width),
            height: 8 + layout.tripStringCore.size.height + layout.referenceListCore.size.height
        )
        return layout
    }

    /// 只展示提示文案
    public static func layoutForTrip(props: ReferenceListViewProps, size: CGSize) -> ReferenceListLayout {
        let tripString = ReferenceListLayout.createTrip(props: props, icon: UDIcon.downBoldOutlined.ud.colorize(color: UIColor.ud.iconN2))
        // 组装结果
        let layout = ReferenceListLayout()
        layout.tripString = tripString
        layout.tripStringCore.load(renderer: layout.tripStringCore.createRenderer(tripString))
        _ = layout.tripStringCore.layout(size)
        layout.size = CGSize(width: layout.tripStringCore.size.width, height: layout.tripStringCore.size.height)
        return layout
    }

    /// 创建提示文案
    private static func createTrip(props: ReferenceListViewProps, icon: UIImage) -> LKInlineElement {
        let tripString = LKInlineElement(tagName: RichViewAdaptor.Tag.p)
        // 添加一个0宽度的内容，撑开高度
        let empty = LKInlineElement(tagName: RichViewAdaptor.Tag.span); empty.style.height(.point(20.auto())); empty.style.verticalAlign(.middle)
        tripString.addChild(empty)
        // 文本
        let text = LKTextElement(text: BundleI18n.LarkAI.MyAI_IM_NumReferences_Button(props.referenceList.count)); text.style.fontSize(.point(16.auto())); text.style.color(UIColor.ud.textCaption)
        text.style.verticalAlign(.middle)
        tripString.addChild(text)
        // icon
        let attachment = LKAsyncRichAttachmentImp(size: CGSize(width: 12.auto() + 4, height: 12.auto()), viewProvider: {
            let contentView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 12.auto() + 4, height: 12.auto())))
            let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 4, y: 0), size: CGSize(width: 12.auto(), height: 12.auto())))
            imageView.image = icon
            contentView.addSubview(imageView)
            return contentView
        // verticalAlign设置啥都无所谓，因为LKInlineBlockElement的高度和LKAttachmentElement是一样的
        }, verticalAlign: .bottom)
        let iconElement = LKInlineBlockElement(tagName: RichViewAdaptor.Tag.span).addChild(LKAttachmentElement(attachment: attachment))
        iconElement.style.verticalAlign(.middle)
        tripString.addChild(iconElement)

        return tripString
    }
}
