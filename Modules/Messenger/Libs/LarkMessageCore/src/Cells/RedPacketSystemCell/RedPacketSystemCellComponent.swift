//
//  RedPacketSystemCellComponent.swift
//  LarkMessageBase
//
//  Created by liuwanlin on 2019/6/10.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import RichLabel
import LarkMessageBase

public protocol RedPacketSystemCellContext: ViewModelContext {
    var maxCellWidth: CGFloat { get }
    func getChatThemeScene() -> ChatThemeScene
}

extension PageContext: RedPacketSystemCellContext {}

open class RedPacketSystemCellComponent<C: RedPacketSystemCellContext>: ASComponent<RedPacketSystemCellComponent.Props, EmptyState, UIView, C> {
    public final class Props: ASComponentProps {
        public var text: String = ""
        public var highlightText: String = ""
        public var tapLinkAction: (() -> Void)?
        public var chatComponentTheme: ChatComponentTheme = ChatComponentTheme.getChatDefault()
    }

    private lazy var blurBackgroundView: BlurViewComponent<C> = {
        let props = BlurViewProps()
        props.blurRadius = 25
        props.cornerRadius = 6
        let style = ASComponentStyle()
        style.alignSelf = .center
        return BlurViewComponent<C>(props: props, style: style)
    }()

    private lazy var label: RichLabelComponent<C> = {
        let labelProps = RichLabelProps()
        labelProps.numberOfLines = 0

        let labelStyle = ASComponentStyle()
        labelStyle.backgroundColor = UIColor.clear
        labelStyle.marginLeft = 8
        labelStyle.marginRight = 8
        labelStyle.marginTop = 4
        labelStyle.marginBottom = 4
        labelStyle.alignSelf = .center

        let label = RichLabelComponent<C>(props: labelProps, style: labelStyle)
        return label
    }()

    override public func render() -> BaseVirtualNode {
        style.paddingBottom = 12
        style.paddingTop = 12
        style.justifyContent = .center
        let maxCellWidth = context?.maxCellWidth ?? UIScreen.main.bounds.width
        style.width = CSSValue(cgfloat: maxCellWidth)
        setSubComponents([blurBackgroundView])
        blurBackgroundView.setSubComponents([label])
        let result = getAttributeString()
        label.props.attributedText = result.0
        label.props.textLinkList = result.1

        return super.render()
    }

    private func getAttributeString() -> (NSAttributedString, [LKTextLink]) {

        let font = UIFont.ud.caption1

        // 消息前面的红包图标
        let iconHeight = font.rowHeight
        let iconImage = BundleResources.hongbao_system_light
        let iconWidth = iconHeight * (iconImage.size.width / iconImage.size.height)
        let attachmentSize = CGSize(width: iconWidth * 1.3, height: iconHeight)

        let attachment = LKAsyncAttachment(viewProvider: { () -> UIView in
            let imgView = UIImageView()
            imgView.backgroundColor = UIColor.clear
            imgView.frame = CGRect(
                origin: .zero,
                size: CGSize(width: iconWidth, height: iconHeight)
            )
            imgView.clipsToBounds = true
            imgView.image = iconImage

            let wraper = UIView(frame: CGRect(origin: .zero, size: attachmentSize))
            wraper.addSubview(imgView)

            return wraper
        }, size: attachmentSize)

        attachment.fontDescent = font.descender
        attachment.fontAscent = font.ascender
        attachment.verticalAlignment = .top

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributeText = NSMutableAttributedString(
            string: "",
            attributes: [.paragraphStyle: paragraphStyle]
        )
        attributeText.append(
            NSAttributedString(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [
                    LKAttachmentAttributeName: attachment,
                    .paragraphStyle: paragraphStyle
                ]
            )
        )

        // 系统消息文案
        let systemAttributeText = NSMutableAttributedString(
            string: props.text,
            attributes: [
                .foregroundColor: UIColor.ud.N500,
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
        )
        // 红包文案颜色不同
        var range = (props.text as NSString).range(of: props.highlightText, options: .backwards)
        if range.location != NSNotFound {
            systemAttributeText.addAttributes(
                [.foregroundColor: UIColor.ud.colorfulRed],
                range: range
            )
        }
        attributeText.append(systemAttributeText)

        // 红包文案加链接
        var links: [LKTextLink] = []
        range = (attributeText.string as NSString).range(of: props.highlightText, options: .backwards)
        if range.location != NSNotFound {
            var link = LKTextLink(
                range: range,
                type: .link,
                attributes: [.foregroundColor: UIColor.ud.colorfulRed],
                activeAttributes: [
                    .foregroundColor: UIColor.ud.colorfulRed,
                    .backgroundColor: UIColor.ud.N600
                ]
            )
            link.linkTapBlock = { [weak self] (_, _) in
                self?.props.tapLinkAction?()
            }
            links.append(link)
        }

        return (attributeText, links)
    }

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        label.style.marginLeft = new.chatComponentTheme.isDefaultScene ? 0 : 8
        label.style.marginRight = new.chatComponentTheme.isDefaultScene ? 0 : 8
        label.style.marginTop = new.chatComponentTheme.isDefaultScene ? 0 : 4
        label.style.marginBottom = new.chatComponentTheme.isDefaultScene ? 0 : 4

        blurBackgroundView.props.blurRadius = new.chatComponentTheme.isDefaultScene ? 0 : 25
        blurBackgroundView.props.fillColor = new.chatComponentTheme.systemMessageBlurColor
        return true
    }
}
