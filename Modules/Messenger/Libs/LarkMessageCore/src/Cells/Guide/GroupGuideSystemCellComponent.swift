//
//  GuideCellComponent.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2022/10/27.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import RichLabel
import LarkMessageBase
import ByteWebImage
import LarkUIKit
import UniverseDesignTheme

public protocol GroupGuideSystemCellContext: ViewModelContext {
    var maxCellWidth: CGFloat { get }
    func getChatThemeScene() -> ChatThemeScene
}

extension PageContext: GroupGuideSystemCellContext {}

struct GroupGuideConfig {
    /* 标题 */
    static var titleFont: UIFont { UIFont.ud.title3 }
    static var titleColor: UIColor { UIColor.ud.textTitle }
    /* 副标题 */
    static var subTitleFont: UIFont { UIFont.ud.body2 }
    static var subTitleColor: UIColor { UIColor.ud.textPlaceholder }
    /* 插画*/
    static let imageSize = CGSize(width: 176, height: 132)
    /* 按钮 */
    static var buttonHeight: CGFloat { UIFont.ud.body0.rowHeight * 2 }
    static var buttonTextFont: UIFont { UIFont.ud.body0 }
    static var buttonTextColor: UIColor { UIColor.ud.textTitle }
    static var buttonIconSize: CGSize { CGSize(width: UIFont.ud.body0.rowHeight,
                                       height: UIFont.ud.body0.rowHeight) }
    static let iconLabelPadding: CGFloat = 4
    static let buttonMargin: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 6
    /* 左右安全边距 */
    static let safetyMargin = CGFloat(16)
}

open class GroupGuideSystemCellComponent<C: GroupGuideSystemCellContext>: ASComponent<GroupGuideSystemCellComponent.Props, EmptyState, UIView, C> {
    public final class Props: ASComponentProps {
        public var title: String = ""
        public var subTitle: String = ""
        public var lmImagePassThrough: ImagePassThrough = ImagePassThrough()
        public var dmImagePassThrough: ImagePassThrough = ImagePassThrough()
        public var buttonItems: [GroupGuideActionButtonItem] = []
        public var chatComponentTheme: ChatComponentTheme = ChatComponentTheme.getChatDefault()
    }

    private lazy var titleContainer: BlurViewComponent<C> = {
        let props = BlurViewProps()
        props.blurRadius = 25
        props.cornerRadius = 6
        let style = ASComponentStyle()
        style.flexDirection = .column
        return BlurViewComponent<C>(props: props, style: style)
    }()

    /// 主标题
    private lazy var titleLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = GroupGuideConfig.titleFont
        props.textColor = GroupGuideConfig.titleColor
        props.textAlignment = .center
        props.numberOfLines = 0
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.alignSelf = .stretch
        return UILabelComponent<C>(props: props, style: style)
    }()

    /// 副标题
    private lazy var subTitleLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = GroupGuideConfig.subTitleFont
        props.textColor = GroupGuideConfig.subTitleColor
        props.textAlignment = .center
        props.numberOfLines = 0
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.alignSelf = .stretch
        style.marginTop = 4
        return UILabelComponent<C>(props: props, style: style)
    }()

    /// 插画
    private lazy var image: UIImageViewComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.width = 176
        style.height = 132
        style.marginTop = 20
        return UIImageViewComponent<C>(props: UIImageViewComponentProps(), style: style)
    }()

    /// 按钮容器
    private lazy var buttonContainer: UIViewComponent<C> = {
        let style = ASComponentStyle()
        return UIViewComponent<C>(props: ASComponentProps(), style: style)
    }()

    /// guide cell 宽度
    private var cellWidth: CGFloat {
        context?.maxCellWidth ?? UIScreen.main.bounds.width
    }

    /// 计算按钮大小
    private func calculateButtonWidth(_ text: String) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        var width = NSAttributedString(
            string: text,
            attributes: [
                .font: GroupGuideConfig.titleFont,
                .paragraphStyle: paragraphStyle
            ]
        ).boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: GroupGuideConfig.buttonTextFont.pointSize + 10),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size.width
        width += (GroupGuideConfig.buttonIconSize.width + GroupGuideConfig.buttonMargin * 2 + GroupGuideConfig.iconLabelPadding)
        // 按钮长度最大不能超过屏幕安全区域
        return min(width, cellWidth - GroupGuideConfig.safetyMargin)
    }

    /// 按钮Component数组
    private lazy var btnComponents: [GroupGuideActionButtonComponent<C>] = []

    /// 初始化新的按钮组件
    private func newBtnComponent() -> GroupGuideActionButtonComponent<C> {
        let props = GroupGuideActionButtonComponent<C>.Props()
        let style = ASComponentStyle()
        style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderComponent, style: .solid))
        style.height = CSSValue(cgfloat: GroupGuideConfig.buttonHeight)
        style.ui.cornerRadius = GroupGuideConfig.buttonCornerRadius
        let btnComponet = GroupGuideActionButtonComponent(props: props, style: style)
        return btnComponet
    }

    private var isDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return UDThemeManager.getRealUserInterfaceStyle() == .dark
        } else {
            return false
        }
    }

    public override init(props: GroupGuideSystemCellComponent.Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.paddingTop = 12
        style.paddingBottom = 12
        style.alignSelf = .stretch
        style.alignItems = .center
        style.flexDirection = .column
        style.paddingLeft = CSSValue(cgfloat: GroupGuideConfig.safetyMargin)
        style.paddingRight = CSSValue(cgfloat: GroupGuideConfig.safetyMargin)
        setSubComponents([
            titleContainer,
            image,
            buttonContainer
        ])
        titleContainer.setSubComponents([
            titleLabel,
            subTitleLabel
        ])
    }

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        titleContainer.style.paddingLeft = props.chatComponentTheme.isDefaultScene ? 0 : 8
        titleContainer.style.paddingRight = props.chatComponentTheme.isDefaultScene ? 0 : 8
        titleContainer.style.paddingTop = props.chatComponentTheme.isDefaultScene ? 0 : 4
        titleContainer.style.paddingBottom = props.chatComponentTheme.isDefaultScene ? 0 : 4
        titleContainer.props.fillColor = props.chatComponentTheme.systemMessageBlurColor
        titleContainer.props.blurRadius = props.chatComponentTheme.isDefaultScene ? 0 : 25

        /* 标题 */
        titleLabel.props.text = new.title
        subTitleLabel.props.text = new.subTitle
        /* 按钮 */
        let gap = new.buttonItems.count - btnComponents.count
        /// 使按钮组件数量与VM中按钮数据数量一致
        if gap > 0 {
            for _ in 0..<gap {
                btnComponents.append(newBtnComponent())
            }
        } else if gap < 0 {
            btnComponents.dropLast(-gap)
        }
        /// 刷新按钮Component数据
        for index in 0..<new.buttonItems.count {
            btnComponents[index].props = GroupGuideActionButtonComponent<C>.Props(text: new.buttonItems[index].text,
                                                                                  lmIcon: new.buttonItems[index].lmIcon,
                                                                                  dmIcon: new.buttonItems[index].dmIcon,
                                                                                  onTapped: new.buttonItems[index].tapAction)
        }
        buttonContainer.setSubComponents(btnComponents)
        return true
    }

    public override func render() -> BaseVirtualNode {
        /* 主容器 */
        style.width = CSSValue(cgfloat: cellWidth)
        /* 插画 */
        let imageKey = (isDarkMode ? props.dmImagePassThrough.key : props.lmImagePassThrough.key) ?? ""
        let passThrough = isDarkMode ? props.dmImagePassThrough : props.lmImagePassThrough
        if !imageKey.isEmpty {
            image.style.display = .flex
            image.props.setImage = { imageViewTask in
                let imageView = imageViewTask.view
                imageView.bt.setLarkImage(
                    with: .default(key: imageKey),
                    passThrough: passThrough
                )
            }
        } else {
            image.style.display = .none
        }
        /* 按钮 */
        // 按钮宽度调整
        var totalButtonWidth: CGFloat = 0
        for (index, btnComponent) in btnComponents.enumerated() where index < props.buttonItems.count {
            let btnWidth = CSSValue(cgfloat: self.calculateButtonWidth(props.buttonItems[index].text))
            btnComponent.style.width = btnWidth
            totalButtonWidth += CGFloat(btnWidth.value)
        }
        buttonContainer.style.alignItems = .center
        // iPad c视图与r视图的按钮布局方向不同, 同时要保证在宽屏下,横向排列时所有按钮能够不超出安全区域
        if Display.pad, cellWidth > 500,
           cellWidth - totalButtonWidth
            - (CGFloat(btnComponents.count - 1) * 16) > GroupGuideConfig.safetyMargin * 2 {
            buttonContainer.style.flexDirection = .row
            buttonContainer.style.paddingTop = 20
            buttonContainer.style.marginLeft = -8
            buttonContainer.style.marginRight = -8
            btnComponents.forEach { btnComponent in
                btnComponent.style.marginLeft = 8
                btnComponent.style.marginRight = 8
                btnComponent.style.marginTop = 0
            }
        } else {
            buttonContainer.style.flexDirection = .column
            buttonContainer.style.paddingTop = 4
            buttonContainer.style.marginLeft = 0
            buttonContainer.style.marginRight = 0
            btnComponents.forEach { btnComponent in
                btnComponent.style.marginTop = 16
            }
        }
        return super.render()
    }
}
