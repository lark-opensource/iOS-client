//
//  ComponentsFactory.swift
//  NewLarkDynamic
//
//  Created by qihongye on 2019/6/19.
//

import Foundation
import LarkModel
import AsyncComponent
import LarkFeatureGating
import LKCommonsLogging
import RustPB
import LarkSetting

let basicFactories: [ComponentFactory.Type] = [
    TextComponentFactory.self,
    AnchorComponentFactory.self,
    AtComponentFactory.self,
    EmotionComponentFactory.self,
    TextableAreaComponentFactory.self,
    ImageComponentFactory.self,
    LDTimeComponentFactory.self
]
let containerFactories: [ComponentFactory.Type] = [
    DivComponentFactory.self,
    PComponentFactory.self,
    ButtonComponentFactory.self,
    LinkComponentFactory.self
]
let mutiFactories: [ComponentFactory.Type] = [
    DatePickerComponentFactory.self,
    DateTimePickerComponentFactory.self,
    TimePickerComponentFactory.self,
    OverflowMenuComponentFactory.self,
    SelectMenuComponentFactory.self
]

class ComponentFactory {


    private var flexParser: FlexStyleParser
    var tag: RichTextElement.Tag {
        assertionFailure("must override!")
        return .unknown
    }

    var needChildren: Bool {
        return false
    }

    var needRecursiveSubComponents: Bool {
        return true
    }

    required init(flexParser: FlexStyleParser = FlexStyleParser([]), translateLocale: Locale?) {
        self.flexParser = flexParser
    }

    func parseStyle(style: [String: String], context: LDContext?, elementId: String? = nil) -> LDStyle {
        let ldStyle = LDStyle(context: context, elementId: elementId)
        flexParser.parse(style: ldStyle, map: style)
        ldStyle.styleValues = StyleParser.parse(style)
        return ldStyle
    }

    func create<C: LDContext>(richtext: RichText,
                               element: RichTextElement,
                             elementId: String,
                              children: [RichTextElement],
                                 style: LDStyle,
                               context: C?,
                              translateLocale: Locale? = nil
) -> ComponentWithSubContext<C, C> {
        let props = UILabelComponentProps()
        props.numberOfLines = 0
        props.text = context?.i18n.unknownTag
        props.font = style.font
        return UILabelComponent<C>(props: props, style: style, context: context)
    }
}

class ComponentsFactory<C: LDContext> {
    private var factoryMap: [RichTextElement.Tag: ComponentFactory]
    private let context: C?
    private let flexParser: FlexStyleParser
    private let logger = Logger.log(ComponentFactory.self, category: larkDynamicModule)
    public var translateLocale: Locale?

    init(flexParser: FlexStyleParser, context: C?, translateLocale: Locale?) {
        self.flexParser = flexParser
        self.context = context
        self.factoryMap = [.unknown: ComponentFactory(flexParser: flexParser, translateLocale: translateLocale)]
        self.translateLocale = translateLocale
    }

    func regist<F: ComponentFactory>(_ factory: F.Type) {
        let elementFactory = factory.init(flexParser: self.flexParser, translateLocale: translateLocale)
        self.factoryMap[elementFactory.tag] = elementFactory
    }

    func create(elementID: String,
                _ element: RichTextElement,
                richtext: RichText,
                unknownTags: inout [RustPB.Basic_V1_RichTextElement.Tag]
    ) -> (ComponentWithSubContext<C, C>, Bool) {
        let factory = factoryMap[element.tag] ?? factoryMap[.unknown]!
        if factoryMap[element.tag] == nil {
            unknownTags.append(element.tag)
        }
        var children: [RichTextElement] = []
        if factory.needChildren {
            children = element.childIds.compactMap({ richtext.elements[$0] })
        }
        var element = element
        if LarkFeatureGating.shared.getFeatureBoolValue(for: FeatureGating.messageCardEnableImageStretchMode) {
            element = applyStyleCustomWidth(element)
        }
        let elementStyle = (context?.wideCardMode ?? false) ? patchWideStyle(e: element): element.style
        let component = factory.create(
            richtext: richtext,
            element: element,
            elementId: elementID,
            children: children,
            style: factory.parseStyle(style: elementStyle, context: context, elementId: elementID),
            context: context,
            translateLocale: translateLocale
        )
        return (component, factory.needRecursiveSubComponents)
    }

    private func applyStyleCustomWidth(_ element:RichTextElement) -> RichTextElement{
        var element = element
        switch element.tag {
        case .img:
            /// 如果允许自定义宽度
            let patchWidthKey = KeyStylePreProcessor.keyWidth
            let minWidthKey = KeyStylePreProcessor.keyMinWidth
            if let imageProperty = element.property.image as? ImageProperty,
               imageProperty.hasCustomWidth,
               imageProperty.customWidth > 0 {
                // 图像品质优化更新：图片宽度范围是16px~581px
                // PRD文档 https://bytedance.feishu.cn/docx/doxcn8NJeu7YbutVcMhQ7uVyH6d
                let minCustomWidth = min(581, imageProperty.customWidth)
                let customWidth = max(minCustomWidth, 16)
                element.style[patchWidthKey] = "\(customWidth)"
                element.style.removeValue(forKey: minWidthKey)
            }
        @unknown default:
            break
        }
        return element
    }

    private func patchWideStyle(e: RichTextElement) -> [String : String] {
        var wideStyles = e.wideStyle
        switch e.tag {
        case .img:
            detailLog.info("patchWideStyle start \(e.tag)")
            let patchAspectRatioKey = KeyStylePreProcessor.keyAspectRatio
            let patchWidthKey = KeyStylePreProcessor.keyWidth
            let minWidthKey = KeyStylePreProcessor.keyMinWidth
            /// 如果是Image 需要客户端设置aspectRatio，长期方案是放在property中
            if wideStyles[patchAspectRatioKey] == nil && e.style[patchAspectRatioKey] != nil {
                wideStyles[patchAspectRatioKey] = e.style[patchAspectRatioKey]
                detailLog.info("patchWideStyle did patch \(e.style)")
            }
            /// 如果允许自定义宽度
            if let imageProperty = e.property.image as? ImageProperty,
               imageProperty.hasCustomWidth,
               imageProperty.customWidth > 0 {
                // - 图片宽度范围是278px~580px，开发者配置小于278px时，限定为278px，大于580px时，限定为580px
                // PRD文档 https://bytedance.feishu.cn/docs/doccnvZWfgViAcbwJfAhIAdmXef#PggeDK
                let customWidth = max(min(580, imageProperty.customWidth), 278)
                let oldHeight = wideStyles[patchWidthKey]
                wideStyles[patchWidthKey] = "\(customWidth)"
                if LarkFeatureGating.shared.getFeatureBoolValue(for: FeatureGating.messageCardEnableImageStretchMode) {
                    wideStyles.removeValue(forKey: minWidthKey)
                }
                let log = "patch image wide style for custom width from \(oldHeight) to \(customWidth)"
                logger.info(log)
                detailLog.info("patchWideStyle \(log)")
            }
        @unknown default:
            break
        }
        return wideStyles
    }
}

func empowerment<C: LDContext>(componentsFactory: ComponentsFactory<C>) {
    (basicFactories + containerFactories + mutiFactories).forEach {
        componentsFactory.regist($0)
    }
}

///预处理的时候，需要上下文信息，通过context获取消息转发的标记；将isForwardMessage传入unit，不依赖context
func empowerment(richTextPreProcessor: RichTextPreProcessor, context: LDContext?) {
    let isForwardMessage = context?.isForwardCardMessage ?? false
    richTextPreProcessor.register(unit: ButtonProcessorUnit.init(isForwardMessage: isForwardMessage))
    richTextPreProcessor.register(unit: DatePickerProcessorUnit.init(isForwardMessage: isForwardMessage))
    richTextPreProcessor.register(unit: DatetimePickerProcessorUnit.init(isForwardMessage: isForwardMessage))
    richTextPreProcessor.register(unit: TimePickerProcessorUnit.init(isForwardMessage: isForwardMessage))
    richTextPreProcessor.register(unit: SelectMenuProcessorUnit.init(isForwardMessage: isForwardMessage))
    richTextPreProcessor.register(unit: OverflowProcessorUnit.init(isForwardMessage: isForwardMessage))
}
