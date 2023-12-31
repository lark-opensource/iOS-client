//
//  LoadingComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/3/28.
//

import Foundation
import RustPB
import TangramComponent
import TangramUIComponent

// https://bytedance.feishu.cn/docx/doxcnHZibKQvfabHiC7MkgzrUsg
public final class LoadingComponentViewModel: RenderComponentBaseViewModel {
    private lazy var _component: LoadingComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let props = buildComponentProps(style: style, renderStyle: renderStyle)
        _component = LoadingComponent<EmptyContext>(props: props, style: renderStyle)
    }

    public override func buildComponentStyle(style: Basic_V1_URLPreviewComponent.Style) -> RenderComponentStyle {
        let renderStyle = super.buildComponentStyle(style: style)
        renderStyle.clipsToBounds = false
        // Loading组件支持字体缩放
        scale(renderStyle)
        return renderStyle
    }

    private func buildComponentProps(style: Basic_V1_URLPreviewComponent.Style,
                                     renderStyle: RenderComponentStyle) -> LoadingComponentProps {
        let props = LoadingComponentProps()
        let width = (renderStyle.width.unit == .pixcel) ? renderStyle.width.value : 0
        let height = (renderStyle.height.unit == .pixcel) ? renderStyle.height.value : 0
        let size = max(width, height)
        if size > 0 {
            props.size = size
            // Loading为方形，当只设置了width或height时，需要兼容设置成方形
            renderStyle.width = TCValue(cgfloat: size)
            renderStyle.height = TCValue(cgfloat: size)
        }
        if let color = style.textColorV2.color {
            props.color = color
        }
        return props
    }
}
