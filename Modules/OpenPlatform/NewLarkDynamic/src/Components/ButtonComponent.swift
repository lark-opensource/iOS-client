//
//  LDButtonComponent.swift
//  NewLarkDynamic
//
//  Created by Jiayun Huang on 2019/6/20.
//

import Foundation
import AsyncComponent
import EEFlexiable
import LarkModel
import RichLabel
import LKCommonsLogging
import LarkAlertController
import LarkInteraction
import LarkFeatureGating

class ButtonComponentFactory<P: ButtonComponentProps>: ComponentFactory {
    let NormalPadding = CSSValue(value: 19.0, unit: .point)
    
    override var tag: RichTextElement.Tag {
        return .button
    }

    override var needChildren: Bool {
        return true
    }

    func configProps(_ props: inout P, style: LDStyle, element: RichTextElement) {
        props.element = element
        props.backgroundColor = style.getBackgroundColor() ?? .clear
        props.backgroundColorActive = style.getBackgroundColorActive() ?? .clear
        props.backgroundColorDisable = style.getBackgroundColorDisable() ?? .clear
        props.borderColor = style.getBorderColor()
        /// 如果UI需要展示非交互状态
        let buttonUIDisable = element.property.button.isLoading || element.property.button.disable
        if let borderAlpha = props.loadingBorderAlpha(), buttonUIDisable {
            props.borderColor = style.getBorderColor()?.withAlphaComponent(borderAlpha)
        }
        
        props.border = style.border
        /// IG样式跟随本地
        props.borderRadius = 6
    }

    override func create<C: LDContext>(
        richtext: RichText,
        element: RichTextElement,
        elementId: String,
        children: [RichTextElement],
        style: LDStyle,
        context: C?,
        translateLocale: Locale? = nil) -> ComponentWithSubContext<C, C> {
            var fixStyle = updateWithLocalStyle(style: style, context: context, element: element)
            fixStyle = updateButtonPaddingLeftRightStyle(element: element,
                                                         style: fixStyle,
                                                         context: context)
            let property = element.property.button
            var props = P()
            props.actionID = property.actionID
            props.disable = property.disable
            ///如果是转发后的消息，我们直接修改为可交互
            if context?.isForwardCardMessage ?? false {
                props.disable = false
            }
            props.isLoading = property.isLoading
            props.confirm = property.confirm
            configProps(&props, style: fixStyle, element: element)
            if let borderColor = props.borderColor {
                fixStyle.updateBorderColor(color: borderColor)
            }
            return ButtonComponent<C, LDButton, ButtonComponentProps>(props: props,
                                                                      style: fixStyle,
                                                                      context: context)
    }
    func updateWithLocalStyle(style: LDStyle,
                              context: LDContext?,
                              element: RichTextElement? = nil) -> LDStyle {
        var resultStyle = style
        /// 如果处于字体放大的场景中，需要将height去掉，让paddingTop和paddingBottom生效
        if context?.zoomAble() ?? false {
            resultStyle.height = CSSValueAuto
            let defaultValue = CSSValue(value: 10, unit: .point)
            if resultStyle.paddingTop.unit == .undefined || resultStyle.paddingTop.value == 0 {
                resultStyle.paddingTop = defaultValue
            }
            if resultStyle.paddingBottom.unit == .undefined || resultStyle.paddingBottom.value == 0 {
                resultStyle.paddingBottom = defaultValue
            }
        } else if let element = element, !ButtonProcessorUnit.isLinkButton(element: element) {
            resultStyle.height = CSSValue(value: 36, unit: .point)
        }
        /// 如果是本地（存在子元素）的组件，必须要 justifyContent = .spaceBetween 这个样式，否则客户端的样式会紊乱
        if tag == .datepicker || tag == .datetimepicker || tag == .timepicker || tag == .selectmenu {
            resultStyle.justifyContent = .spaceBetween
        }
        return resultStyle
    }
    /// 3.43.0 版本消息卡片按钮优化paddingLeft和paddingRight需求
    /// https://bytedance.feishu.cn/docs/doccnea8FcJn7jLx9DZrqZeXIQb?appid=2
    func updateButtonPaddingLeftRightStyle(element: RichTextElement,
                                           style: LDStyle,
                                           context: LDContext?) -> LDStyle {
        guard element.tag == .button else {
            return style
        }
        guard let cardVersion = context?.cardVersion, cardVersion >= 2 else {
            /// 如果是V3以下的卡片，样式不变，走老逻辑
            return style
        }
        var resultStyle = style
        if ButtonProcessorUnit.isLinkButton(element: element) {
            resultStyle.paddingLeft = CSSValue(value: 0, unit: .point)
            resultStyle.paddingRight = CSSValue(value: 0, unit: .point)
        } else {
            resultStyle.paddingLeft = self.NormalPadding
            resultStyle.paddingRight = self.NormalPadding
        }
        return resultStyle
    }
}

enum ButtonMode: String {
    case danger
    case `default`
    case primary
    case unknown
}

class ButtonComponentProps: ASComponentProps {
    var actionID: String?
    var disable: Bool = false
    var isLoading: Bool = false
    var confirm: RichTextElement.ButtonConfirmProperty?
    var element: RichTextElement?
    var backgroundColor: UIColor = .clear
    var backgroundColorActive: UIColor = .clear
    var backgroundColorDisable: UIColor = .clear
    var borderColor: UIColor?
    var border: Border?
    var borderRadius = CSSValueUndefined
    /// figma.com/file/rRNYrFxBdkshyouJruMRSq/消息卡片?node-id=52%3A1
    func loadingAlpha() -> CGFloat {
        return 0.6
    }
    
    func loadingBorderAlpha() -> CGFloat? {
        let mode = ButtonMode(rawValue: element?.property.button.mode ?? "") ?? .unknown
        if mode == .danger || mode == .primary {
            return loadingAlpha()
        }
        return nil
    }
    
    func getBackgroundColor() -> UIColor {
        if isLoading {
            return backgroundColor.withAlphaComponent(loadingAlpha())
        }
        return backgroundColor
    }
    func getBackgroundColorActive() -> UIColor {
        if isLoading {
            return backgroundColorActive.withAlphaComponent(loadingAlpha())
        }
        return backgroundColorActive
    }
    func getBackgroundColorDisable() -> UIColor {
        if isLoading {
            return backgroundColorDisable.withAlphaComponent(loadingAlpha())
        }
        return backgroundColorDisable
    }
    required override init(key: String? = nil, children: [Component] = []) {
        super.init(key: key, children: children)
    }
}

class ButtonComponent<C: LDContext, V: LDButton, P: ButtonComponentProps>: LDComponent<P, V, C> {
    private let logger = Logger.log(ButtonComponent.self, category: larkDynamicModule)
    override func update(view: V) {
        super.update(view: view)
        context?.actionFinished = true
        view.isEnabled = !props.disable
        let bgColor = props.getBackgroundColor().withContext(context: self.context).currentColor()
        view.setBackgroundColor(color: bgColor, for: .normal)
        let bgColorActive = props.getBackgroundColorActive().withContext(context: self.context).currentColor()
        view.setBackgroundColor(color: bgColorActive, for: .highlighted)
        let bgColorDisable = props.getBackgroundColorDisable().withContext(context: self.context).currentColor()
        view.setBackgroundColor(color: bgColorDisable, for: .disabled)
//        view.setBackgroundColor(color: bgColorDisable, for: .selected)
        let borderColor = props.borderColor
        view.layer.borderColor = borderColor?.cgColor
        view.layer.borderWidth = props.border?.top.width ?? 0
        view.borderRadius = props.borderRadius
        view.removeTarget(nil, action: #selector(self.onClick(sender:)), for: .touchUpInside)
        view.addTarget(self, action: #selector(self.onClick(sender:)), for: .touchUpInside)
    }

    final func sendAction(
        actionID: String,
        params: [String: String]?,
        confirm: RichTextElement.ButtonConfirmProperty?
    ) {
        guard let context = self.context else {
            return
        }
        if let confirm = confirm,
            !confirm.title.isEmpty
                && !confirm.text.isEmpty
                && !confirm.confirm.isEmpty
                && !confirm.dismiss.isEmpty {
            let alert = LarkAlertController()
            alert.setTitle(text: confirm.title)
            alert.setContent(text: confirm.text)
            alert.addSecondaryButton(text: context.i18n.cancelText, dismissCompletion: {
                self.logger.info("alert cancel send action: \(actionID)")
            })
            alert.addPrimaryButton(text: context.i18n.sureText, dismissCompletion: {
                self.logger.info("alert confirm send action: \(actionID)")
                context.sendAction(actionID: actionID, params: params)
            })
            context.presentController(vc: alert, wrap: nil)
            logger.info("show alert: \(actionID)")
        } else {
            context.sendAction(actionID: actionID, params: params)
        }
    }

    @objc func onClick(sender: LDButton) {
        guard !props.disable,
            let actionId = props.actionID else {
            return
        }
        ///如果判断为转发后的消息，且处理成功（会弹提示），那么直接返回，不再继续处理
        if processForwardCardMessage(actionID: actionId) {
            return
        }
        sendAction(actionID: actionId, params: nil, confirm: props.confirm)
    }
}

extension UIButton.State: Hashable {
}

public final class LDButton: UIButton {
    var backgroundColors: [State: UIColor] = [:]
    var interactionRegionSize: CGSize?
    var interactionRegionCornerRadius: CGFloat?
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? backgroundColors[.highlighted] : backgroundColors[.normal]
        }
    }

    func setBackgroundColor(color: UIColor, for state: State) {
        backgroundColors[state] = color
        if color == .clear {
            setBackgroundImage(nil, for: state)
            return
        }
        UIGraphicsBeginImageContext(self.bounds.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(self.bounds)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        setBackgroundImage(image, for: state)
    }
    
    public override func layoutSubviews() {
        superview?.layoutSubviews()
        // setupPointerInteraction()
    }
    
    private func setupPointerInteraction() {
        if let size = interactionRegionSize,
              let radius = interactionRegionCornerRadius,
              size.equalTo(bounds.size),
              radius == layer.cornerRadius {
            return
        }
        interactionRegionSize = bounds.size
        interactionRegionCornerRadius = layer.cornerRadius
        if #available(iOS 13.4, *) {
            self.lkPointerStyle = PointerStyle(effect: .hover())
        }
    }
}

