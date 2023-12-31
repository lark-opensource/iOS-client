//
//  DatePickerComponent.swift
//  NewLarkDynamic
//
//  Created by Songwen Ding on 2019/7/30.
//

import Foundation
import AsyncComponent
import EEFlexiable
import LarkModel
import RichLabel
import LKCommonsLogging

class DatePickerComponentFactory<P: DatePickerComponentProps>: ButtonComponentFactory<P> {
    override var tag: RichTextElement.Tag {
        return .datepicker
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
        let property = element.property.datePicker
        var props = P()
        props.actionID = property.actionID
        props.disable = property.disable
        ///如果是转发后的消息，我们直接修改为可交互
        if context?.isForwardCardMessage ?? false {
            props.disable = false
        }
        props.isLoading = property.isLoading
        props.confirm = property.confirm
        props.initialOption = property.initialDate
        props.tag = tag
        configProps(&props, style: fixStyle, element: element)
        return DatePickerComponent(props: props,
                                   style: fixStyle,
                                   context: context)
    }
}

class DatePickerComponentProps: ButtonComponentProps {
    var initialOption: String?
    var tag: RichTextElement.Tag = .datepicker

    func dateOption() -> DateOption {
        var op: DateOption = .onlyDate
        if tag == .timepicker {
            op = DateOption.onlyeTime
        } else if tag == .datetimepicker {
            op = DateOption.dateTime
        } else {
            op = DateOption.onlyDate
        }
        return op
    }

}

class DatePickerComponent<C: LDContext, P: DatePickerComponentProps>: ButtonComponent<C, LDButton, P> {

    override func onClick(sender: LDButton) {
        guard let context = context,
            let actionId = props.actionID else {
                return
        }
        ///如果判断为转发后的消息，且处理成功（会弹提示），那么直接返回，不再继续处理
        if processForwardCardMessage(actionID: actionId) {
            return
        }
        context.selectDate(sender: sender, initialDate: props.initialOption, dateOption: props.dateOption()) { [weak self] date in
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale.current
            dateFormatter.dateFormat = "yyyy-MM-dd' 'XXXX"
            var options: [String: String] = [:]

            if let tag = self?.props.tag {
                if tag == .timepicker {
                    dateFormatter.dateFormat = "HH:mm' 'XXXX"
                } else if tag == .datetimepicker {
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm' 'XXXX"
                } else {
                    // props中没有指定tag，使用默认fromate"yyyy-MM-dd' 'XXXX"
                }
                options["timezone"] = TimeZone.current.identifier
                let dateString = dateFormatter.string(from: date)
                options["selected_option"] = dateString
                self?.sendAction(actionID: actionId,
                                 params: options,
                                 confirm: self?.props.confirm)
            }

        }
    }
}

class DateTimePickerComponentFactory<P: DatePickerComponentProps>: ButtonComponentFactory<P> {
    override var tag: RichTextElement.Tag {
        return .datetimepicker
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
        let property = element.property.datetimePicker
        var props = P()
        props.actionID = property.actionID
        props.disable = property.disable
        props.isLoading = property.isLoading
        props.confirm = property.confirm
        props.initialOption = property.initialDatetime
        props.tag = tag
        configProps(&props, style: fixStyle, element: element)
        return DatePickerComponent(props: props,
                                   style: fixStyle,
                                   context: context)
    }
}

class TimePickerComponentFactory<P: DatePickerComponentProps>: ButtonComponentFactory<P> {
    override var tag: RichTextElement.Tag {
        return .timepicker
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
        let property = element.property.timePicker
        var props = P()
        props.actionID = property.actionID
        props.disable = property.disable
        props.isLoading = property.isLoading
        props.confirm = property.confirm
        props.initialOption = property.initialTime
        props.tag = tag
        configProps(&props, style: fixStyle, element: element)
        return DatePickerComponent(props: props,
                                   style: fixStyle,
                                   context: context)
    }
}
