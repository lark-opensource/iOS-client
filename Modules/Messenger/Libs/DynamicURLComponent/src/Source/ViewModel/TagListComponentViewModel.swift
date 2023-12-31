//
//  TagListComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/19.
//

import UIKit
import Foundation
import RustPB
import TangramComponent
import TangramUIComponent

public final class TagListComponentViewModel: RenderComponentBaseViewModel {
    private lazy var _component: TagListComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let tagList = property?.tagList ?? .init()
        let props = buildComponentProps(property: tagList, style: component.style)
        _component = TagListComponent<EmptyContext>(props: props, style: renderStyle)
    }

    public override func buildComponentStyle(style: Basic_V1_URLPreviewComponent.Style) -> RenderComponentStyle {
        let renderStyle = super.buildComponentStyle(style: style)
        renderStyle.backgroundColor = UIColor.clear // backgroundColor由单个tag响应
        return renderStyle
    }

    private func buildComponentProps(property: Basic_V1_URLPreviewComponent.TagListProperty,
                                     style: Basic_V1_URLPreviewComponent.Style) -> TagListComponentProps {
        let props = TagListComponentProps()
        // 优先级：mixedTags > tags
        if !property.mixedTags.isEmpty {
            props.tagInfos = property.mixedTags.map({
                return TagInfo(text: $0.tag,
                               textColor: $0.textColor.color ?? TagListView.defaultTextColor,
                               backgroundColor: $0.backgroundColor.color ?? TagListView.defaultBackgroundColor)
            })
        } else if !property.tags.isEmpty {
            let textColor = style.tcTextColor ?? TagListView.defaultTextColor
            let backgroundColor = style.tcBackgroundColor ?? TagListView.defaultBackgroundColor
            props.tagInfos = property.tags.map({
                return TagInfo(text: $0, textColor: textColor, backgroundColor: backgroundColor)
            })
        }
        if let font = style.tcFont {
            props.font = font
        }
        props.numberOfLines = Int(property.numberOfLines)
        return props
    }
}
