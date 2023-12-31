//
//  RichTextPreProcessor.swift
//  NewLarkDynamic
//
//  Created by Songwen Ding on 2019/8/20.
//

import LarkModel
import LKCommonsLogging

typealias ElementProcessResult = (String, RichTextElement)
protocol RichTextPreProcessorUnit {
    var tag: RichTextElement.Tag { get }
    func resolve(element: RichTextElement,
                 id: String,
                 context: LDContext?,
                 translateLocale: Locale?) -> [ElementProcessResult]
}

///将logger提出来,范型类不能含有静态变量，如果设置成实例变量，每次初始化logger会降低部分性能
private let logger = Logger.log(RichTextPreProcessorUnit.self,
                                category: larkDynamicModule)

class RichTextPreProcessor {
    private let context: LDContext?
    private var units: [RichTextElement.Tag: RichTextPreProcessorUnit] = [:]
    
    init(context: LDContext?) {
        self.context = context
    }

    func register(unit: RichTextPreProcessorUnit) {
        self.units[unit.tag] = unit
    }

    func process(richText: RichText, translateLocale: Locale?) -> RichText {
        logger.info("start to process richText")
        var resolvedRitchText = richText
        // 生成richText相应的element树结构
        richText.elements.forEach { (id, element) in
            guard let unit = units[element.tag] else {
                return
            }
            let results = unit.resolve(element: element,
                                       id: id,
                                       context: context,
                                       translateLocale: translateLocale)
            var childIds = resolvedRitchText.elements[id]?.childIds ?? []
            let tag = element.tag
            results.forEach({ (id, element) in
                resolvedRitchText.elements[id] = element
                if tag == .button || tag == .overflowmenu {
                    childIds.insert(id, at: 0)
                } else {
                    childIds.append(id)
                }
            })
            resolvedRitchText.elements[id]?.childIds = childIds
        }
        logger.info("end of processing richText")
        /// 找出所有Action的下面的Text，记录对应的elementId
        resolvedRitchText.elements.forEach { (_, element) in
            if element.tag == .button ||
                element.tag == .datepicker ||
                element.tag == .datetimepicker ||
                element.tag == .timepicker ||
                element.tag == .overflowmenu ||
                element.tag == .selectmenu {
                for childId in element.childIds where resolvedRitchText.elements[childId]?.tag == .text {
                    context?.recordButtonText(elementId: childId,
                                              parentElement: ElementContext(parentElement: element))
                }
            }
        }
        return resolvedRitchText
    }
}

class RichTextPreProcessorUnitHelpers {
    private static let logger = Logger.log(RichTextPreProcessorUnitHelpers.self, category: larkDynamicModule)
    static func formatDateString(_ dateString: String,
                                 translateLocale: Locale?,
                                 context: LDContext?) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: dateString) {
            return Self.getFormatTime(tag: .datepicker,
                                      date: date,
                                      translateLocale: translateLocale,
                                      context: context) ?? dateFormatter.string(from: date)
        }
        dateFormatter.dateFormat = "yyyy-MM-dd' 'XXXX"
        if let date = dateFormatter.date(from: dateString) {
            if let result = Self.getFormatTime(tag: .datepicker,
                                               date: date,
                                               translateLocale: translateLocale,
                                               context: context) {
                return result
            }
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.string(from: date)
        } else {
            RichTextPreProcessorUnitHelpers.logger.warn("format date failed!")
            return nil
        }
    }

    static func formatTimeString(
        _ dateString: String,
        _ parseFormate: String,
        _ outputFormate: String,
        tag: ElementTag,
        translateLocale: Locale?,
        context: LDContext?
    ) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.locale = Locale.current
        inputFormatter.dateFormat = parseFormate

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale.current
        outputFormatter.dateFormat = outputFormate

        if let date = inputFormatter.date(from: dateString) {
            return Self.getFormatTime(tag: tag,
                                      date: date,
                                      translateLocale: translateLocale,
                                      context: context) ?? outputFormatter.string(from: date)
        }

        inputFormatter.dateFormat = parseFormate + " Z"
        if let date = inputFormatter.date(from: dateString) {
            return Self.getFormatTime(tag: tag,
                                      date: date,
                                      translateLocale: translateLocale,
                                      context: context) ?? outputFormatter.string(from: date)
        }
        RichTextPreProcessorUnitHelpers.logger.warn("format time failed!")
        return nil
    }

    static func getFormatTime(tag: ElementTag,
                              date: Date,
                              translateLocale: Locale?,
                              context: LDContext?) -> String? {
        guard let context = context else {
            logger.error("getFormatTime context is nil")
            return nil
        }
        var formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = context.locale
        formatter.timeZone = TimeZone.current
        var language = context.locale.languageIdentifier

        var isTranslate = false
        //下发的locale不为nil，则为走翻译的locale
        if let translateLocale = translateLocale {
            language =  translateLocale.languageIdentifier
            formatter.locale = translateLocale
            isTranslate = true
        }
        var resultFormat: String? = nil
        let dateFormat = TimeComponentSettingHelper.getFormat(isTranslate: isTranslate,
                                                              originFormatType: "date",
                                                              language: language,
                                                              is24HourTime: true) ?? "yyyy-MM-dd' 'XXXX"
        let timeFormat = TimeComponentSettingHelper.getFormat(isTranslate: isTranslate,
                                                              originFormatType: "time",
                                                              language: language,
                                                              is24HourTime: true) ?? "HH:mm' 'XXXX"
        switch tag {
            case .timepicker:
                resultFormat = timeFormat
            case .datepicker:
                resultFormat = dateFormat
            case .datetimepicker:
                resultFormat = dateFormat + " " + timeFormat
            @unknown default:
                break
        }
        guard let formatstr = resultFormat else {
            return nil
        }
        formatter.dateFormat = formatstr
        return fixFormatStyle(formatter.string(from: date), locale: formatter.locale)
    }

    // 生成element的描述结构
    static func generateDescription(content: String,
                                    color: String,
                                    colorDarkMode: String) -> RichTextElement {
        var element = RichTextElement()
        element.tag = .text
        element.property.text.numberOfLines = 1
        element.property.text.content = content
        element.style = [
            "height": "100%",
            "width": "auto",
            "marginRight": "5",
            "textAlignment": "left",
            "fontSize": "14",
            "color": color,
            "colorDarkMode": colorDarkMode,
            "marginLeft": "-5"
        ]
        element.wideStyle = element.style
        #if DEBUG
        cardlog.info("TextComponent maek text \(content) style \(element.style)")
        if color == "#F0F0F0" {
            cardlog.info("TextComponent maek wrong text \(content) style \(element.style)")
        }
        #endif
        return element
    }

    // 生成加载中的tip图标
    static func generateAccessory(name: String,
                                  isRotaing: Bool,
                                  context: LDContext?) -> RichTextElement {
        let width = (context?.zoomAble() ?? false) ? 17.auto(.s4) : 17
        let styles = [
            "width": "\(width)",
            "aspectRatio": "1",
            "justifyContent": "flexEnd",
            "textAlignment": "left",
            "marginRight": "-4"
        ]
        return generateImage(name: name, isRotaing: isRotaing, style:styles)
    }
    // 生成加载中的tip图标
    static func generateButtonAbsoluteAccessory(name: String,
                                            isRotaing: Bool,
                                            context: LDContext?) -> RichTextElement {
        let width = (context?.zoomAble() ?? false) ? 18.auto(.s4) : 18
        let styles = [
            "width": "\(width)",
            "aspectRatio": "1",
            "justifyContent": "flexStart",
            "order": "-1",
            "marginRight": "4"
        ]
        return generateImage(name: name, isRotaing: isRotaing, style:styles)
    }
    // 生成LinkButton加载中的Loading图标
    static func generateLinkButtonAccessory(name: String,
                                            isRotaing: Bool,
                                            context: LDContext?) -> RichTextElement {
        let width = 17
        let isZoomFont: Bool = context?.zoomAble() ?? false
        let styles = [
            "width": "\(width)",
            "aspectRatio": "1",
            "textAlignment": "left",
            "left": "0",
            "top": "\(isZoomFont ? (10 + 2.auto(.s4)) : 0)",
            "alignSelf": "baseline",
            "marginRight": "4"
        ]
        return generateImage(name: name, isRotaing: isRotaing, style:styles)
    }
    static func generateImage(name: String, isRotaing: Bool, style: [String: String]) -> RichTextElement {
        var element = RichTextElement()
        element.tag = .img
        element.property.image.thumbKey = isRotaing ? name : ""
        element.property.image.originKey = name
        element.property.image.imgCanPreview = false
        element.style = style
        element.wideStyle = element.style
        return element
    }
}

extension RichTextElement.ImageProperty {
    var localImageRotaing: Bool {
        return localImage != nil && !thumbKey.isEmpty
    }
    var localImage: UIImage? {
        return BundleResources.NewLarkDynamic.iconbyName(iconName: originKey)
    }
}

class ButtonProcessorUnit: RichTextPreProcessorUnit {

    let buttonLoading = "button_loading"
    let isForwardMessage: Bool
    /// Link Button Style
    static let linkButtonStyleKey = "block_action_button_link"
    ///isForwardMessage 放在ButtonProcessorUnit中，方便多个组件使用
    required init(isForwardMessage: Bool) {
        self.isForwardMessage = isForwardMessage
    }

    var tag: RichTextElement.Tag {
        return .button
    }

    func resolve(element: RichTextElement,
                 id: String,
                 context: LDContext?,
                 translateLocale: Locale?) -> [ElementProcessResult] {
        guard element.property.button.isLoading else {
            return []
        }
        let loadingMode = element.property.button.mode
        let loadingImg = (loadingMode == "danger") ? "button_loading_red" : "button_loading"
        let isLinkButton = ButtonProcessorUnit.isLinkButton(element: element)
        let cardVersion = context?.cardVersion ?? 0
        var accessory: RichTextElement?
        if cardVersion < 2 {
            /// 如果是V3以下的卡片，样式不变，走老逻辑
            accessory = RichTextPreProcessorUnitHelpers.generateAccessory(name: loadingImg,
                                                                          isRotaing: true,
                                                                          context: context)
        } else if isLinkButton {
            accessory = RichTextPreProcessorUnitHelpers.generateLinkButtonAccessory(name: loadingImg,
                                                                                    isRotaing: true,
                                                                                    context: context)
        } else {
            accessory = RichTextPreProcessorUnitHelpers.generateButtonAbsoluteAccessory(name: loadingImg,
                                                                                        isRotaing: true,
                                                                                        context: context)
        }
        let accessoryID = id + accessory.hashValue.description
        return [(accessoryID, accessory!)]
    }
    /// 检测是不是Link Button
    static func isLinkButton(element: RichTextElement) -> Bool {
        return element.property.button.mode == "link"
    }
}

class DatePickerProcessorUnit: ButtonProcessorUnit {
    override var tag: RichTextElement.Tag {
        return .datepicker
    }
    func getInitContent(_ initDateStr: String,
                        translateLocale: Locale?,
                        context: LDContext?) -> String? {
        return RichTextPreProcessorUnitHelpers.formatDateString(initDateStr,
                                                                translateLocale: translateLocale,
                                                                context: context)
    }

    func buttonNormalImgStr() -> String {
        return "button_date"
    }
    func buttonDisableImgStr() -> String {
        return "button_date_disable"
    }
    override func resolve(element: RichTextElement,
                          id: String,
                          context: LDContext?,
                          translateLocale: Locale?) -> [ElementProcessResult] {
        let property = element.property.datePicker
        let content = getInitContent(property.initialDate,
                                     translateLocale: translateLocale,
                                     context: context)
        let placeholder = property.placeHolder

        let color = (content != nil ? UIColor.ud.N900 : UIColor.ud.N500).withContext(context: context)
        /// 是否是转发的消息，转发的消息需要设置成灰色文字颜色，不是disable的状态下，可以点击
//        let finnalColor = ((property.isLoading || property.disable || isForwardMessage) ? UIColor.ud.N400 : color).withContext(context: context)
        let lightColorHex = color.alwaysLight.hex6 ?? "#000000"
        let darkColorHex = color.alwaysDark.hex6 ?? "#FFFFFF"
        let description = RichTextPreProcessorUnitHelpers.generateDescription(content: content ?? placeholder,
                                                                              color: lightColorHex,
                                                                              colorDarkMode: darkColorHex)
        let descriptionID = id + description.hashValue.description
        /// 是否是转发的消息，转发的消息或者禁止交互的消息需要设置成灰色icon
        let iconName = (property.disable || isForwardMessage) ? buttonDisableImgStr() : buttonNormalImgStr()
        let accessory = RichTextPreProcessorUnitHelpers.generateAccessory(
            name: property.isLoading ? buttonLoading : iconName,
            isRotaing: property.isLoading, context: context
        )
        let accessoryID = id + accessory.hashValue.description

        return [(descriptionID, description), (accessoryID, accessory)]
    }
}

class DatetimePickerProcessorUnit: DatePickerProcessorUnit {
    override var tag: RichTextElement.Tag {
        return .datetimepicker
    }

    override func getInitContent(_ initDateStr: String,
                                 translateLocale: Locale?,
                                 context: LDContext?) -> String? {

        return RichTextPreProcessorUnitHelpers.formatTimeString(initDateStr,
                                                                "yyyy-MM-dd HH:mm",
                                                                "yyyy-MM-dd HH:mm",
                                                                tag: self.tag,
                                                                translateLocale: translateLocale,
                                                                context: context)
    }

    override func buttonNormalImgStr() -> String {
        return "button_time"
    }
    override func buttonDisableImgStr() -> String {
        return "button_time_disable"
    }
    override func resolve(element: RichTextElement,
                          id: String,
                          context: LDContext?,
                          translateLocale: Locale?) -> [ElementProcessResult] {
        let property: RichTextElement.DatetimePickerProperty = element.property.datetimePicker
        let content = getInitContent(property.initialDatetime,
                                     translateLocale: translateLocale,
                                     context: context)
        let placeholder = property.placeHolder
        /// 是否是转发的消息，转发的消息需要设置成灰色文字颜色，不是disable的状态下，可以点击
        let color = ((content != nil && !isForwardMessage) ? UIColor.ud.N900 : UIColor.ud.N500).withContext(context: context)
        let lightColorHex = color.alwaysLight.hex6 ?? "#000000"
        let darkColorHex = color.alwaysDark.hex6 ?? "#FFFFFF"
        let description = RichTextPreProcessorUnitHelpers.generateDescription(content: content ?? placeholder,
                                                                              color: lightColorHex,
                                                                              colorDarkMode: darkColorHex)
        let descriptionID = id + description.hashValue.description
        /// 是否是转发的消息，转发的消息或者禁止交互的消息需要设置成灰色icon
        let iconName = (property.disable || isForwardMessage) ? buttonDisableImgStr() : buttonNormalImgStr()
        let accessory = RichTextPreProcessorUnitHelpers.generateAccessory(
            name: property.isLoading ? buttonLoading : iconName,
            isRotaing: property.isLoading, context: context
        )
        let accessoryID = id + accessory.hashValue.description

        return [(descriptionID, description), (accessoryID, accessory)]
    }
}

class TimePickerProcessorUnit: DatePickerProcessorUnit {
    override var tag: RichTextElement.Tag {
        return .timepicker
    }

    override func buttonNormalImgStr() -> String {
        return "button_time"
    }
    override func buttonDisableImgStr() -> String {
        return "button_time_disable"
    }

    override func getInitContent(_ initDateStr: String, translateLocale: Locale?, context: LDContext?) -> String? {
        return RichTextPreProcessorUnitHelpers.formatTimeString(initDateStr,
                                                                "HH:mm",
                                                                "HH:mm",
                                                                tag: self.tag,
                                                                translateLocale: translateLocale,
                                                                context: context)
    }

    override func resolve(element: RichTextElement,
                          id: String,
                          context: LDContext?,
                          translateLocale: Locale?) -> [ElementProcessResult] {
        let property: RichTextElement.TimePickerProperty = element.property.timePicker
        let content = getInitContent(property.initialTime,
                                     translateLocale: translateLocale,
                                     context: context)
        let placeholder = property.placeHolder
        /// 是否是转发的消息，转发的消息需要设置成灰色文字颜色，不是disable的状态下，可以点击
        let color = ((content != nil && !isForwardMessage) ? UIColor.ud.N900 : UIColor.ud.N500).withContext(context: context)
        let lightColorHex = color.alwaysLight.hex6 ?? "#000000"
        let darkColorHex = color.alwaysDark.hex6 ?? "#FFFFFF"
        let description = RichTextPreProcessorUnitHelpers.generateDescription(content: content ?? placeholder,
                                                                              color: lightColorHex,
                                                                              colorDarkMode: darkColorHex)
        let descriptionID = id + description.hashValue.description
        /// 是否是转发的消息，转发的消息或者禁止交互的消息需要设置成灰色icon
        let iconName = (property.disable || isForwardMessage) ? buttonDisableImgStr() : buttonNormalImgStr()
        let accessory = RichTextPreProcessorUnitHelpers.generateAccessory(
            name: property.isLoading ? buttonLoading : iconName,
            isRotaing: property.isLoading, context: context
        )
        let accessoryID = id + accessory.hashValue.description

        return [(descriptionID, description), (accessoryID, accessory)]
    }

}

class SelectMenuProcessorUnit: ButtonProcessorUnit {
    override var tag: RichTextElement.Tag {
        return .selectmenu
    }

    override func resolve(element: RichTextElement,
                          id: String,
                          context: LDContext?,
                          translateLocale: Locale?) -> [ElementProcessResult] {
        let property = element.property.selectMenu
        let content = property.options
            .first(where: { $0.value == property.initialOption })?.text ?? property.initialOption
        let placeholder = property.placeHolder

        /// 是否是转发的消息，转发的消息需要设置成灰色文字颜色，不是disable的状态下，可以点击
        let color = (!content.isEmpty ? UIColor.ud.N900 : UIColor.ud.N500).withContext(context: context)
        let finnalColor = ((property.isLoading || property.disable || isForwardMessage) ? UIColor.ud.N400 : color).withContext(context: context)
        let lightColorHex = finnalColor.alwaysLight.hex6 ?? "#000000"
        let darkColorHex = finnalColor.alwaysDark.hex6 ?? "#FFFFFF"
        let description = RichTextPreProcessorUnitHelpers
            .generateDescription(content: !content.isEmpty ? content : placeholder,
                                 color: lightColorHex,
                                 colorDarkMode: darkColorHex)
        let descriptionID = id + description.hashValue.description
        ///Normal Icon When disable or enable
        /// 是否是转发的消息，转发的消息或者禁止交互的消息需要设置成灰色icon
        let iconName = (property.disable || isForwardMessage) ? "button_menu_disable" : "button_menu"
        let accessory = RichTextPreProcessorUnitHelpers.generateAccessory(
            name: property.isLoading ? buttonLoading : iconName,
            isRotaing: property.isLoading, context: context
        )
        let accessoryID = id + accessory.hashValue.description
        return [(descriptionID, description), (accessoryID, accessory)]
    }
}

class OverflowProcessorUnit: ButtonProcessorUnit {
    override var tag: RichTextElement.Tag {
        return .overflowmenu
    }
    override func resolve(element: RichTextElement,
                          id: String,
                          context: LDContext?,
                          translateLocale: Locale?) -> [ElementProcessResult] {
        let property = element.property.overflowMenu
        /// 是否是转发的消息，转发的消息需要设置成灰色icon
        let iconName = (property.isLoading || property.disable || property.options.isEmpty || isForwardMessage) ?
            "button_overflow_disable" : "button_overflow"
        let width = (context?.zoomAble() ?? false) ? 16.auto(.s4) : 16
        let icon = RichTextPreProcessorUnitHelpers.generateImage(
            name: iconName,
            isRotaing: false,
            style: [
                "width": "\(width)",
                "aspectRatio": "1",
                "alignContent": "center",
                "justifyContent": "center"
            ]
        )
        let iconID = id + icon.hashValue.description
        
        guard element.property.overflowMenu.isLoading else {
            return [(iconID, icon)]
        }
        let accessory = RichTextPreProcessorUnitHelpers.generateButtonAbsoluteAccessory(name: buttonLoading, isRotaing: true, context: context)
        let accessoryID = id + accessory.hashValue.description
        
        return [(accessoryID, accessory)]
    }
}
