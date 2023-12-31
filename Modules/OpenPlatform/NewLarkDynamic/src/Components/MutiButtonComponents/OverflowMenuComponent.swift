//
//  OverflowMenuComponent.swift
//  NewLarkDynamic
//
//  Created by Songwen Ding on 2019/7/30.
//

import Foundation
import LarkModel
import AsyncComponent
import EEFlexiable

class OverflowMenuComponentFactory<P: OverflowMenuComponentProps>: ButtonComponentFactory<P> {
    override var tag: RichTextElement.Tag {
        return .overflowmenu
    }
    //样式由设计制定
    let overflowPadding = CSSValue(value: 10.0, unit: .point)
    let overflowHeight = CSSValue(value: 36.0, unit: .point)

    override func create<C: LDContext>(
        richtext: RichText,
        element: RichTextElement,
        elementId: String,
        children: [RichTextElement],
        style: LDStyle,
        context: C?,
        translateLocale: Locale? = nil) -> ComponentWithSubContext<C, C> {
        let fixStyle = updateWithLocalStyle(style: style, context: context)
        //增加内边距，参数与button对齐
        fixStyle.paddingLeft = self.overflowPadding
        fixStyle.paddingRight = self.overflowPadding
        fixStyle.height = self.overflowHeight
        let property = element.property.overflowMenu
        var props = P()
        props.actionID = property.actionID
        props.disable = property.disable || property.options.isEmpty
        ///如果是转发后的消息，我们直接修改为可交互
        if context?.isForwardCardMessage ?? false {
            props.disable = false
        }
        props.isLoading = property.isLoading
        props.confirm = property.confirm
        props.options = property.options
        configProps(&props, style: fixStyle, element: element)
        return OverflowMenuComponent(props: props,
                                     style: fixStyle,
                                     context: context)
    }
}

class OverflowMenuComponentProps: ButtonComponentProps {
    var options = [RichTextElement.MenuOption]()
}

class OverflowMenuComponent<C: LDContext, P: OverflowMenuComponentProps>: ButtonComponent<C, LDButton, P> {

    override func onClick(sender: LDButton) {
        guard let context = context else {
            return
        }
        ///如果判断为转发后的消息，且处理成功（会弹提示），那么直接返回，不再继续处理
        if processForwardCardMessage(actionID: self.props.actionID ?? "") {
            return
        }
        context.selectOverflowOption(
        sender: sender,
        options: props.options.map { (text: $0.text, id: $0.optionActionID, value: $0.value) }) { [weak self] option in
            self?.sendAction(actionID: option.id,
                             params: ["selected_option": option.value],
                             confirm: self?.props.confirm)
        }
    }
}
