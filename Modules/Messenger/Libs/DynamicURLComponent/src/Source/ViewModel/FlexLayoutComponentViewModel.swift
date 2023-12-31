//
//  FlexLayoutComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/7/31.
//

import RustPB
import TangramComponent
import TangramUIComponent

// https://bytedance.feishu.cn/docx/KFYmdDH8PoNZDexEbGdcs9SMnTg
public final class FlexLayoutComponentViewModel: LayoutComponentBaseViewModel {
    private var _component: FlexLayoutComponent = FlexLayoutComponent(children: [], props: FlexLayoutComponentProps())
    public override var component: Component {
        return _component
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        layoutStyle: LayoutComponentStyle) {
        let flexLayout = property?.flexLayout ?? .init()
        let props = buildComponentProps(property: flexLayout)
        _component = FlexLayoutComponent(children: [], props: props, style: layoutStyle)
    }

    private func buildComponentProps(property: Basic_V1_URLPreviewComponent.FlexLayoutProperty) -> FlexLayoutComponentProps {
        var props = FlexLayoutComponentProps()
        props.orientation = property.orientation.tcOrientation
        // 兼容开放平台ColumnSet：宽屏模式下且未配置强制使用窄屏模式时，固定不折叠
        if dependency.contentMaxWidth >= 378, !property.forceUseCompactMode {
            props.flexWrap = .noWrap
        } else {
            props.flexWrap = property.flexWrap.tcFlexWrap
        }
        props.mainAxisSpacing = CGFloat(property.mainAxisSpacing)
        props.crossAxisSpacing = CGFloat(property.crossAxisSpacing)
        props.padding = property.tcPadding
        props.justify = property.mainAxisJustify.tcJustify
        props.align = property.crossAxisAlign.tcAlign
        return props
    }
}

extension Basic_V1_URLPreviewComponent.FlexLayoutProperty {
    var tcPadding: Padding {
        if hasPadding {
            return .init(top: CGFloat(padding.top),
                         right: CGFloat(padding.right),
                         bottom: CGFloat(padding.bottom),
                         left: CGFloat(padding.left))
        }
        return .zero
    }
}
