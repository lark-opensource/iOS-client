//
//  ComponentPatcherRegistry.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/2/28.
//

import Foundation
import RustPB

protocol PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty
}

struct ComponentPatcherRegistry {
    private static let propertyPatchers: [Basic_V1_URLPreviewComponent.TypeEnum: PropertyPatcher.Type] = [
        .avatar: AvatarPropertyPatcher.self,
        .button: ButtonPropertyPatcher.self,
        .cardContainer: CardContainerPropertyPatcher.self,
        .chattersPreview: ChattersPreviewPropertyPatcher.self,
        .docImage: DocImagePropertyPatcher.self,
        .empty: EmptyPropertyPatcher.self,
        .header: HeaderPropertyPatcher.self,
        .iconButton: IconButtonPropertyPatcher.self,
        .image: ImagePropertyPatcher.self,
        .linearLayout: LinearLayoutPropertyPatcher.self,
        .richtext: RichTextPropertyPatcher.self,
        .spinButton: SpinButtonPropertyPatcher.self,
        .tagList: TagListPropertyPatcher.self,
        .textButton: TextButtonPropertyPatcher.self,
        .text: TextPropertyPatcher.self,
        .oversizedText: OversizedTextPropertyPatcher.self,
        .time: TimePropertyPatcher.self,
        .video: VideoPropertyPatcher.self,
        .loading: LoadingPropertyPatcher.self,
        .timeZone: TimeZonePropertyPatcher.self,
        .flexLayout: FlexLayoutPropertyPatcher.self
    ]

    static func propertyPatch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                              baseType: Basic_V1_URLPreviewComponent.TypeEnum,
                              data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty? {
        guard let patcher = propertyPatchers[baseType] else {
            assertionFailure("unknown type")
            return nil
        }
        return patcher.patch(base: base, data: data)
    }

    static func stylePatch(base: Basic_V1_URLPreviewComponent.Style, data: Basic_V1_URLPreviewStyleData) -> Basic_V1_URLPreviewComponent.Style {
        var style = base
        data.previewStyleData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .sizeLevel: style.sizeLevel = .init(rawValue: Int(value.i32)) ?? base.sizeLevel
            case .themeColor: style.textColorV2 = value.themeColor
            case .backgroundType: style.backgroundColor.type = .init(rawValue: Int(value.i32)) ?? base.backgroundColor.type
            case .backgroundLinearDeg: style.backgroundColor.linear.deg = value.i32
            case .backgroundLinearThemeColors: style.backgroundColor.linear.colorsV2 = value.themeColors.colors
            case .width: style.width = value.layoutValue
            case .height: style.height = value.layoutValue
            case .maxWidth: style.maxWidth = value.layoutValue
            case .maxHeight: style.maxHeight = value.layoutValue
            case .minWidth: style.minWidth = value.layoutValue
            case .minHeight: style.minHeight = value.layoutValue
            case .growWeight: style.growWeight = value.i32
            case .shrinkWeight: style.shrinkWeight = value.i32
            case .fontLevel: style.fontLevel = value.fontLevel
            case .borderWidth: style.border.width = value.f
            case .borderCornerRadius: style.border.cornerRadius = value.f
            case .borderThemeColor: style.border.colorV2 = value.themeColor
            case .aspectRatio: style.aspectRatio = value.i32
            case .alignSelf: style.alignSelf = .init(rawValue: Int(value.i32)) ?? base.alignSelf
            @unknown default: return
            }
        }
        return style
    }
}
