//
//  DSLTemplateManager.swift
//  LarkSearch
//
//  Created by sunyihe on 2022/11/25.
//

import UIKit
import RustPB
import RxSwift
import ServerPB
import Foundation
import EEFlexiable
import LarkSearchCore
import AsyncComponent
import LKCommonsLogging
import UniverseDesignColor
import LarkStorage
import LarkListItem
import LarkContainer
import LarkRustClient

final class DSLTemplateManager {

    static let logger = Logger.log(DSLTemplateManager.self, category: "Module.Search")
    private let disposeBag = DisposeBag()

    let characterSet = CharacterSet(charactersIn: "<>")
    var cellWidth: CGFloat = 0
    var divisionInFoldStatus: Bool = true

    struct DSLComponentJson {
        let renderComponentsJson: [String: String]
        let templateJson: [String: Any]
    }

    func updateDSLTemplate(userResolver: UserResolver) {
        let onlineRequest = ServerPB_Usearch_PullRenderDSLTemplatesRequest()
        let notifyRequest = Search_V2_NotifySearchRequest()
        let rustService = try? userResolver.resolve(assert: RustService.self)

        rustService?.sendPassThroughAsyncRequest(
            onlineRequest,
            serCommand: .pullRenderDslTemplates
        )
        .observeOn(MainScheduler.instance).subscribe(
            onNext: { (response: ServerPB_Usearch_PullRenderDSLTemplatesResponse) in
                for element in response.templates {
                    KVStores.Search.globalStore[element.key] = element.value
                }
            }, onError: { (error) in
                Self.logger.error("update DSL templates failed, error: \(error)")
            })

        rustService?.sendAsyncRequest(notifyRequest)
            .subscribe(onNext: { (_) in
            }, onError: { (error) in
                Self.logger.error("notify rust failed, error: \(error)")
            })
    }

    public func getDSLRenderer(by renderData: String) -> ASComponentRenderer? {
        guard let dslComponentJson = analyzeRenderData(by: renderData) else { return nil }

        let dslComponent = transformToDSLComponent(renderComponentsJson: dslComponentJson.renderComponentsJson,
                                                   templateJson: dslComponentJson.templateJson)
        let renderer = ASComponentRenderer(dslComponent)
        return renderer
    }

    public func isDSLDivisionTruncated(renderData: String, labelWidth: CGFloat) -> Bool {
        guard let dslComponentJson = analyzeRenderData(by: renderData),
              let departmentName = dslComponentJson.renderComponentsJson["department_name"] else { return false }

        let font = UIFont.systemFont(ofSize: getFontSizeInTemplate(targetPlaceholder: "<department_name>", templateJson: dslComponentJson.templateJson))
        let labelTextSize = (departmentName as NSString).boundingRect(
            with: CGSize(width: labelWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil).size
        // 产品中部门信息可以展示两行
        return Int(ceil(CGFloat(labelTextSize.height) / font.lineHeight)) > 2
    }

    private func getFontSizeInTemplate(targetPlaceholder: String, templateJson: [String: Any]) -> CGFloat {
        // 遍历树，找到叶子结点，判断叶子结点的占位符与目标占位符是否一致
        for element in templateJson {
            switch element.key {
            case "subviews":
                guard let elements = element.value as? NSArray else { break }
                for element in elements {
                    if let element = element as? [String: String] {
                        if let templatePlaceholder = element["text"],
                           templatePlaceholder == targetPlaceholder {
                            // 找到目标占位符，取出字号
                            guard let fontSizeString = element["text_size"],
                                  let fontSize = Double(fontSizeString) else { break }
                            return fontSize
                        }
                    } else if let element = element as? [String: NSDictionary] {
                        //不是叶子结点时，递归调用
                        return getFontSizeInTemplate(targetPlaceholder: targetPlaceholder, templateJson: element)
                    }
                }
            default: return 12
            }
        }
        return 12
    }

    private func analyzeRenderData(by renderData: String) -> DSLComponentJson? {
        guard let renderJson = transformToDictionary(by: renderData),
              let templateName = renderJson["template"] as? String,
              let renderComponentsJson = renderJson["components"] as? [String: String] else {
            Self.logger.error("renderJson serialization failed")
            return nil
        }
        guard let templateData: String = KVStores.Search.globalStore[templateName] else {
            Self.logger.error("failed to find templateData by templateName")
            return nil
        }
        guard let templateJson = transformToDictionary(by: templateData) else {
            Self.logger.error("templateJson serialization failed")
            return nil
        }
        return DSLComponentJson(renderComponentsJson: renderComponentsJson, templateJson: templateJson)
    }

    private func transformToDSLComponent(renderComponentsJson: [String: String], templateJson: [String: Any]) -> ChatterDSLViewComponent {
        var labelComponents: [UILabelComponent<EmptyContext>] = []
        var subDSLComponent: [ChatterDSLViewComponent] = []
        var style = ASComponentStyle()
        var props = ChatterDSLViewProps()
        style.maxWidth = CSSValue(cgfloat: cellWidth)
        for element in templateJson {
            switch element.key {
            case "width":
                guard let valueString = element.value as? String,
                      let value = Float(valueString) else { break }
                style.width = CSSValue(float: value)
            case "max_width":
                guard let valueString = element.value as? String,
                      let value = Float(valueString) else { break }
                style.maxWidth = CSSValue(float: value)
            case "min_width":
                guard let valueString = element.value as? String,
                      let value = Float(valueString) else { break }
                style.minWidth = CSSValue(float: value)
            case "width_percent":
                guard let valueString = element.value as? String,
                      let present = Float(valueString) else { break }
                let value = Float(cellWidth) * present / 100
                style.width = CSSValue(float: value)
            case "height":
                guard let valueString = element.value as? String,
                      let value = Float(valueString) else { break }
                style.height = CSSValue(float: value)
            case "max_height":
                guard let valueString = element.value as? String,
                      let value = Float(valueString) else { break }
                style.maxHeight = CSSValue(float: value)
            case "min_height":
                guard let valueString = element.value as? String,
                      let value = Float(valueString) else { break }
                style.minHeight = CSSValue(float: value)
            case "height_percent":
                guard let valueString = element.value as? String,
                      let present = Float(valueString) else { break }
                let value = Float(cellWidth) * present / 100
                style.height = CSSValue(float: value)
            case "padding_left":
                guard let valueString = element.value as? String,
                      let value = Float(valueString) else { break }
                style.paddingLeft = CSSValue(float: value)
            case "padding_top":
                guard let valueString = element.value as? String,
                      let value = Float(valueString) else { break }
                style.paddingTop = CSSValue(float: value)
            case "padding_right":
                guard let valueString = element.value as? String,
                      let value = Float(valueString) else { break }
                style.paddingRight = CSSValue(float: value)
            case "padding_bottom":
                guard let valueString = element.value as? String,
                      let value = Float(valueString) else { break }
                style.paddingBottom = CSSValue(float: value)
            case "background":
                guard let valueString = element.value as? String else { break }
                style.backgroundColor = UDColor.getValueByBizToken(token: valueString) ?? UDColor.bgBody
            case "direction":
                guard let value = element.value as? String else { break }
                switch value {
                case "row": style.flexDirection = .row
                case "column": style.flexDirection = .column
                default: break
                }
            case "justify_content":
                guard let value = element.value as? String else { break }
                switch value {
                case "flex_start": style.justifyContent = .flexStart
                case "flex_end": style.justifyContent = .flexEnd
                case "center": style.justifyContent = .center
                case "space_between": style.justifyContent = .spaceBetween
                case "space_around": style.justifyContent = .spaceAround
                case "space_evenly": style.justifyContent = .spaceEvenly
                default: break
                }
            case "flex_wrap":
                guard let value = element.value as? String else { break }
                switch value {
                case "no_wrap": style.flexWrap = .noWrap
                case "wrap": style.flexWrap = .wrap
                case "wrap_reverse": style.flexWrap = .wrapReverse
                default: break
                }
            case "align_content:":
                guard let value = element.value as? String else { break }
                switch value {
                case "auto": style.alignContent = .auto
                case "flex_start": style.alignContent = .flexStart
                case "flex_end": style.alignContent = .flexEnd
                case "center": style.alignContent = .center
                case "space_between": style.alignContent = .spaceBetween
                case "space_around": style.alignContent = .spaceAround
                case "baseline": style.alignContent = .baseline
                default: break
                }
            case "align_items":
                guard let value = element.value as? String else { break }
                switch value {
                case "auto": style.alignItems = .auto
                case "flex_start": style.alignItems = .flexStart
                case "flex_end": style.alignItems = .flexEnd
                case "center": style.alignItems = .center
                case "space_between": style.alignItems = .spaceBetween
                case "space_around": style.alignItems = .spaceAround
                case "baseline": style.alignItems = .baseline
                default: break
                }
            case "subviews":
                guard let elements = element.value as? NSArray else { break }
                for element in elements {
                    //当判断为叶子结点时，根据type初始化对应的功能component
                    if let element = element as? [String: String] {
                        switch element["type"] {
                        case "text":
                            guard var placeholder = element["text"] else { break }
                            placeholder = placeholder.trimmingCharacters(in: characterSet)
                            guard let text = renderComponentsJson[placeholder],
                                  !text.isEmpty else { break }
                            labelComponents.append(transformToLabelComponent(labelJsonData: element,
                                                                             text: text))
                        default: break
                        }
                    } else if let  element = element as? [String: NSDictionary] {
                        //不是叶子结点时，递归调用
                        subDSLComponent.append(transformToDSLComponent(renderComponentsJson: renderComponentsJson,
                                                                       templateJson: element))
                    }
                }
            default: break
            }
        }
        let subComponent = labelComponents + subDSLComponent
        let dslComponent = ChatterDSLViewComponent(props: props, style: style)
        dslComponent.setSubComponents(subComponent)
        return dslComponent
    }

    private func transformToLabelComponent(labelJsonData: [String: String], text: String) -> UILabelComponent<EmptyContext> {
        var style = ASComponentStyle()
        var props = UILabelComponentProps()
        var mutableAttributeString = SearchAttributeString(searchHighlightedString: text).mutableAttributeText
        style.backgroundColor = .clear
        style.width = CSSValue(cgfloat: cellWidth)
        for element in labelJsonData {
            switch element.key {
            case "width":
                guard let value = Float(element.value) else { break }
                style.width = CSSValue(float: value)
            case "max_width":
                guard let value = Float(element.value) else { break }
                style.maxWidth = CSSValue(float: value)
            case "min_width":
                guard let value = Float(element.value) else { break }
                style.minWidth = CSSValue(float: value)
            case "width_percent":
                guard let present = Float(element.value) else { break }
                let value = Float(cellWidth) * present / 100
                style.width = CSSValue(float: value)
            case "height":
                guard let value = Float(element.value) else { break }
                style.height = CSSValue(float: value)
            case "max_height":
                guard let value = Float(element.value) else { break }
                style.maxHeight = CSSValue(float: value)
            case "min_height":
                guard let value = Float(element.value) else { break }
                style.minHeight = CSSValue(float: value)
            case "height_percent":
                guard let present = Float(element.value) else { break }
                let value = Float(cellWidth) * present / 100
                style.height = CSSValue(float: value)
            case "padding_left":
                guard let value = Float(element.value) else { break }
                style.paddingLeft = CSSValue(float: value)
            case "padding_top":
                guard let value = Float(element.value) else { break }
                style.paddingTop = CSSValue(float: value)
            case "padding_right":
                guard let value = Float(element.value) else { break }
                style.paddingRight = CSSValue(float: value)
            case "padding_bottom":
                guard let value = Float(element.value) else { break }
                style.paddingBottom = CSSValue(float: value)
            case "flex_grow":
                guard let value = Float(element.value) else { break }
                style.flexGrow = CGFloat(value)
            case "flex_shrink":
                guard let value = Float(element.value) else { break }
                style.flexShrink = CGFloat(value)
            case "align_self":
                switch element.value {
                case "stretch":
                    style.alignSelf = .stretch
                case "flex_start":
                    style.alignSelf = .flexStart
                case "flex_end":
                    style.alignSelf = .flexEnd
                case "center":
                    style.alignSelf = .center
                case "baseline":
                    style.alignSelf = .baseline
                default: break
                }
            case "position_type":
                switch element.value {
                case "absolute":
                    style.position = .absolute
                case "relative":
                    style.position = .relative
                default: break
                }
            case "text_color":
                props.textColor = UDColor.getValueByBizToken(token: element.value) ?? UDColor.bgBody
            case "fold_lines":
                if divisionInFoldStatus {
                    props.numberOfLines = Int(element.value) ?? 0
                } else {
                    props.numberOfLines = 0
                }
            case "max_lines":
                props.numberOfLines = Int(element.value) ?? 0
            case "text_size":
                let size = Double(element.value) ?? 12
                props.font = UIFont.systemFont(ofSize: size)
                mutableAttributeString.addAttribute(.font,
                                                    value: UIFont.systemFont(ofSize: size),
                                                    range: NSRange(location: 0, length: mutableAttributeString.length))
            case "ellipsize":
                switch element.value {
                case "none":
                    // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
                    props.lineBreakMode = .byWordWrapping
                case "start":
                    props.lineBreakMode = .byTruncatingHead
                case "middle":
                    props.lineBreakMode = .byTruncatingMiddle
                case "end":
                    props.lineBreakMode = .byTruncatingTail
                default: break
                }
            default: break
            }
        }
        props.attributedText = mutableAttributeString
        let dslComponent = UILabelComponent<EmptyContext>(props: props, style: style)
        return dslComponent
    }

    private func transformToDictionary(by string: String) -> [String: Any]? {
        guard let stringData = string.data(using: String.Encoding.utf8) else {
            return nil
        }

        if let json = try? JSONSerialization.jsonObject(with: stringData, options: []) as? [String: Any] {
            return json
        } else {
            Self.logger.error("serialization failed, name:\(string)")
            return nil
        }
    }
}
