//
//  SelectMenuConponent.swift
//  NewLarkDynamic
//
//  Created by Songwen Ding on 2019/7/30.
//

import Foundation
import AsyncComponent
import LarkModel

class SelectMenuComponentFactory<P: SelectMenuComponentProps>: ButtonComponentFactory<P> {
    override var tag: RichTextElement.Tag {
        return .selectmenu
    }

    override func create<C: LDContext>(
        richtext: RichText,
        element: RichTextElement,
        elementId: String,
        children: [RichTextElement],
        style: LDStyle,
        context: C?,
        translateLocale: Locale? = nil) -> ComponentWithSubContext<C, C> {
        let fixStyle = updateWithLocalStyle(style: style, context: context)
        let property = element.property.selectMenu
        var props = P()
        props.actionID = property.actionID
        props.disable = property.disable
        ///如果是转发后的消息，我们直接修改为可交互
        if context?.isForwardCardMessage ?? false {
            props.disable = false
        }
        props.isLoading = property.isLoading
        props.confirm = property.confirm
        props.initialOption = property.initialOption
        props.type = property.type
        props.options = property.options
        configProps(&props, style: fixStyle, element: element)
        return SelectMenuComponent(props: props,
                                   style: fixStyle,
                                   context: context)
    }
}

class SelectMenuComponentProps: DatePickerComponentProps {
    var type: RichTextElement.SelectMenuProperty.TypeEnum = .unknown
    var options = [RichTextElement.MenuOption]()
}

class SelectMenuComponent<C: LDContext, P: SelectMenuComponentProps>: DatePickerComponent<C, P> {

    override func onClick(sender: LDButton) {
        guard let context = context,
            let actionId = props.actionID else {
                return
        }
        ///如果判断为转发后的消息，且处理成功（会弹提示），那么直接返回，不再继续处理
        if processForwardCardMessage(actionID: actionId) {
            return
        }
        switch props.type {
        case .static:
            context.selectMenuOption(
                sender: sender,
                options: props.options.map { (text: $0.text, value: $0.value) },
                initialValue: props.initialOption) { [weak self] option in
                    DispatchQueue.main.async {
                        self?.sendAction(actionID: actionId,
                                         params: ["selected_option": option.value],
                                         confirm: self?.props.confirm)
                    }
            }
        case .person:
            context.selectChatter(sender: sender, chatterIDs: props.options.map { $0.value }) { [weak self] chatterId in
                DispatchQueue.main.async {
                    self?.sendAction(actionID: actionId,
                                     params: ["selected_option": chatterId],
                                     confirm: self?.props.confirm)
                }
            }
        case .unknown:
            break
        @unknown default:
            #if DEBUG
            assert(false, "new value")
            #else
            break
            #endif
        }
    }
}
