//
//  AIChatModeFoldMessageComponent.swift
//  LarkChat
//
//  Created by ByteDance on 2023/6/25.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import RichLabel
import FigmaKit
import LarkMessageBase
import LarkMessageCore
import UniverseDesignIcon
import UniverseDesignLoading
import UniverseDesignFont

class AIChatModeFoldMessageComponent: ASComponent<AIChatModeFoldMessageComponent.Props, EmptyState, UIView, ChatContext> {
    final class Props: ASComponentProps {
        var buttonType: ShowHideButton.ButtonType = .show(loading: false)
        var buttonTappedBlock: ((ShowHideButton.ButtonType) -> Void)?
        var labelAttrTextAndTextLinksBlock: (_ width: CGFloat) -> (NSAttributedString, [LKTextLink]) = { _ in
            return (NSAttributedString(string: ""), [])
        }
        var outOfRangeText = NSAttributedString(string: "...")

        var chatComponentTheme: ChatComponentTheme = ChatComponentTheme.getChatDefault()
    }

    private lazy var blurBackgroundView: BlurViewComponent<ChatContext> = {
        let props = BlurViewProps()
        props.blurRadius = 25
        props.cornerRadius = 6
        let style = ASComponentStyle()
        style.alignSelf = .center
        style.flexDirection = .row
        style.marginRight = 12
        style.marginLeft = 12
        return BlurViewComponent<ChatContext>(props: props, style: style)
    }()

    lazy var labelComponent: RichLabelComponent<ChatContext> = {
        let labelProps = RichLabelProps()
        labelProps.numberOfLines = 1
        let style = ASComponentStyle()
        style.marginLeft = 0
        style.marginRight = 0
        style.marginTop = 4
        style.marginBottom = 4
        style.backgroundColor = UIColor.clear
        style.alignSelf = .center
        style.flexShrink = 1
        return RichLabelComponent<ChatContext>(props: labelProps, style: style)
    }()

    lazy var showHideComponent: ShowHideButtonComponent = {
        let style = ASComponentStyle()
        style.marginLeft = 12
        style.marginRight = 0
        // ShowHideButton内部高度固定20，上下间隔为3，整个ShowHideButton高度 = 20 + 6 = 26
        style.marginTop = 3
        style.marginBottom = 3
        style.backgroundColor = UIColor.clear
        style.alignSelf = .center
        style.flexShrink = 0
        return ShowHideButtonComponent(props: ShowHideButtonComponent.Props(), style: style)
    }()

    override init(props: Props, style: ASComponentStyle, context: ChatContext? = nil) {
        super.init(props: props, style: style, context: context)
        // UX要求高度为42，整个Cell高度 = ShowHideButton高度（子元素中最高元素） + 上下padding = 26 + 16 = 42
        style.paddingBottom = 8
        style.paddingTop = 8
        style.paddingLeft = 20
        style.paddingRight = 20
        style.justifyContent = .center
        setSubComponents([blurBackgroundView])
        blurBackgroundView.setSubComponents([labelComponent, showHideComponent])
        setupProps(props)
    }

    private func setupProps(_ props: Props) {
        labelComponent.props.backgroundColor = UIColor.clear
        let (attr, link) = props.labelAttrTextAndTextLinksBlock(labelComponent.props.preferMaxLayoutWidth ?? UIScreen.main.bounds.width)
        labelComponent.props.textLinkList = link
        labelComponent.props.attributedText = attr
        labelComponent.props.outOfRangeText = props.outOfRangeText
        showHideComponent.props.type = props.buttonType
        showHideComponent.props.buttonTappedBlock = props.buttonTappedBlock
    }

    override func willReceiveProps(_ old: AIChatModeFoldMessageComponent.Props, _ new: AIChatModeFoldMessageComponent.Props) -> Bool {
        setupProps(new)
        return true
    }

    override func update(view: UIView) {
        super.update(view: view)
    }
    override func render() -> BaseVirtualNode {
        let maxCellWidth = (context?.maxCellWidth ?? UIScreen.main.bounds.width)
        style.width = CSSValue(cgfloat: maxCellWidth)
        let contentHorizontalMargin = labelComponent.style.marginLeft.value + labelComponent.style.marginRight.value
        + showHideComponent.style.marginLeft.value + showHideComponent.style.marginRight.value
        let blurBackgroundViewHorizontalMargin = blurBackgroundView.style.marginLeft.value + blurBackgroundView.style.marginRight.value
        let padding = self.style.paddingLeft.value + self.style.paddingRight.value
        ///-2的原因：https://bytedance.feishu.cn/wiki/wikcnjS9uVfFopQObxLkB0LwIoe#
        let preferMaxLayoutWidth = maxCellWidth - CGFloat(contentHorizontalMargin) - CGFloat(blurBackgroundViewHorizontalMargin)
        - ShowHideButton.getSuggestSizeFor(type: props.buttonType).width - CGFloat(padding) - 2
        labelComponent.props.preferMaxLayoutWidth = preferMaxLayoutWidth

        //如果之前attributedText已经赋过值了，需要根据新的width刷新一下值
        if labelComponent.props.attributedText != nil {
            let (attr, link) = props.labelAttrTextAndTextLinksBlock(preferMaxLayoutWidth)
            labelComponent.props.textLinkList = link
            labelComponent.props.attributedText = attr
        }
        return super.render()
    }
}

class ShowHideButtonComponent: ASComponent<ShowHideButtonComponent.Props, EmptyState, ShowHideButton, ChatContext> {
    final class Props: ASComponentProps {
        var type: ShowHideButton.ButtonType = .show(loading: false)
        var buttonTappedBlock: ((ShowHideButton.ButtonType) -> Void)?
    }

    open override var isSelfSizing: Bool {
        return true
    }

    open override var isComplex: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        return ShowHideButton.getSuggestSizeFor(type: props.type)
    }

    public override func create(_ rect: CGRect) -> ShowHideButton {
        let view = ShowHideButton(frame: rect)
        return view
    }

    override func update(view: ShowHideButton) {
        super.update(view: view)
        view.type = props.type
        view.buttonTappedBlock = props.buttonTappedBlock
    }
}

class ShowHideButton: UIControl {
    static func getSuggestSizeFor(type: ButtonType) -> CGSize {
        let textWidth: CGFloat
        switch type {
        case .show:
            textWidth = BundleI18n.AI.MyAI_IM_ShowChatHistory_Button.lu.width(font: UDFont.body2, height: 20.auto())
        case .hide:
            textWidth = BundleI18n.AI.MyAI_IM_HideChatHistory_Button.lu.width(font: UDFont.body2, height: 20.auto())
        }
        return .init(width: textWidth + 14.auto(),
                     height: 20.auto())
    }
    enum ButtonType: Equatable {
        case show(loading: Bool)
        case hide

        static func ==(lhs: ButtonType, rhs: ButtonType) -> Bool {
            switch (lhs, rhs) {
            case (.hide, .hide):
                return true
            case (.show(let loading1), .show(let loading2)):
                return loading1 == loading2
            default:
                return false
            }
        }
    }
    var type: ButtonType = .show(loading: false) {
        didSet {
            guard type != oldValue else { return }
            updateUI()
        }
    }
    var buttonTappedBlock: ((ShowHideButton.ButtonType) -> Void)?

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.body2
        label.textColor = .ud.textPlaceholder
        return label
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    lazy var loadingView: UDSpin = {
        var indicatorConfig = UDSpinIndicatorConfig(size: 10.auto(),
                                                    color: UIColor.ud.textLinkLoading)
        return UDLoading.spin(
            config: .init(indicatorConfig: indicatorConfig, textLabelConfig: nil)
        )
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(onTapped), for: .touchUpInside)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.centerY.left.equalToSuperview()
        }
        addSubview(imageView)
        imageView.snp.makeConstraints { (maker) in
            maker.centerY.right.equalToSuperview()
        }
        addSubview(loadingView)
        loadingView.snp.makeConstraints { (maker) in
            maker.centerY.right.equalToSuperview()
        }
        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUI() {
        switch type {
        case .show(let loading):
            self.titleLabel.text = BundleI18n.AI.MyAI_IM_ShowChatHistory_Button
            if loading {
                self.imageView.isHidden = true
                self.loadingView.isHidden = false
            } else {
                self.imageView.isHidden = false
                self.loadingView.isHidden = true
                self.imageView.image = UDIcon.getIconByKey(.downOutlined,
                                                           renderingMode: .alwaysOriginal,
                                                           iconColor: .ud.iconN3,
                                                           size: CGSize(width: 10.auto(), height: 10.auto()))
            }
        case .hide:
            self.imageView.isHidden = false
            self.loadingView.isHidden = true
            self.titleLabel.text = BundleI18n.AI.MyAI_IM_HideChatHistory_Button
            self.imageView.image = UDIcon.getIconByKey(.upOutlined,
                                                       renderingMode: .alwaysOriginal,
                                                       iconColor: .ud.iconN3,
                                                       size: CGSize(width: 10.auto(), height: 10.auto()))
        }
    }

    @objc
    func onTapped() {
        buttonTappedBlock?(self.type)
    }
}
