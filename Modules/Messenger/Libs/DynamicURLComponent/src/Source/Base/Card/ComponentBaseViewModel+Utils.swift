//
//  ComponentBaseViewModel+Utils.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/19.
//

import UIKit
import Foundation
import RustPB
import TangramComponent
import TangramLayoutKit

extension ComponentBaseViewModel {
    public func scale(_ style: RenderComponentStyle) {
        if style.width.unit == .pixcel {
            style.width = TCValue(cgfloat: style.width.value.auto())
        }
        if style.height.unit == .pixcel {
            style.height = TCValue(cgfloat: style.height.value.auto())
        }
    }

    /// if `style` is a struct such as LayoutComponentStyle, then you should use the return value
    @discardableResult
    public func sync<S: Style>(from: Basic_V1_URLPreviewComponent.Style, to: S) -> S {
        var style = to
        style.width = from.width.tcValue
        style.height = from.height.tcValue
        style.maxWidth = from.maxWidth.tcValue
        style.maxHeight = from.maxHeight.tcValue
        style.minWidth = from.minWidth.tcValue
        style.minHeight = from.minHeight.tcValue
        style.growWeight = Int(from.growWeight)
        style.shrinkWeight = Int(from.shrinkWeight)
        if from.hasAspectRatio, from.aspectRatio > 0 {
            style.aspectRatio = CGFloat(from.aspectRatio) / 100.0
        }
        if from.hasAlignSelf {
            style.alignSelf = from.alignSelf.tcAlign
        }
        return style
    }

    /// if `style` is a struct such as LayoutComponentStyle, then you should use the return value
    @discardableResult
    public func sync<S: Style>(from: Basic_V1_CardComponent.Style, to: S) -> S {
        var style = to
        style.width = from.width.tcValue
        style.height = from.height.tcValue
        style.maxWidth = from.maxWidth.tcValue
        style.maxHeight = from.maxHeight.tcValue
        style.minWidth = from.minWidth.tcValue
        style.minHeight = from.minHeight.tcValue
        style.growWeight = Int(from.growWeight)
        style.shrinkWeight = Int(from.shrinkWeight)
        if from.hasAlignSelf {
            style.alignSelf = from.alignSelf.tcAlign
        }
        return style
    }
}

extension Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
    var linearLayout: Basic_V1_URLPreviewComponent.LinearLayoutProperty? {
        if case .linearLayout(let value) = self { return value }
        return nil
    }

    var flexLayout: Basic_V1_URLPreviewComponent.FlexLayoutProperty? {
        if case .flexLayout(let value) = self { return value }
        return nil
    }

    var empty: Basic_V1_URLPreviewComponent.EmptyProperty? {
        if case .empty(let value) = self { return value }
        return nil
    }

    var header: Basic_V1_URLPreviewComponent.PreviewHeaderProperty? {
        if case .header(let value) = self { return value }
        return nil
    }

    var richText: Basic_V1_URLPreviewComponent.RichTextProperty? {
        if case .richtext(let value) = self { return value }
        return nil
    }

    var image: Basic_V1_URLPreviewComponent.ImageProperty? {
        if case .image(let value) = self { return value }
        return nil
    }

    var chattersPreview: Basic_V1_URLPreviewComponent.ChattersPreviewProperty? {
        if case .chattersPreview(let value) = self { return value }
        return nil
    }

    var button: Basic_V1_URLPreviewComponent.ButtonProperty? {
        if case .button(let value) = self { return value }
        return nil
    }

    var iconButton: Basic_V1_URLPreviewComponent.IconButtonProperty? {
        if case .iconButton(let value) = self { return value }
        return nil
    }

    var textButton: Basic_V1_URLPreviewComponent.TextButtonProperty? {
        if case .textButton(let value) = self { return value }
        return nil
    }

    var time: Basic_V1_URLPreviewComponent.TimeProperty? {
        if case .time(let value) = self { return value }
        return nil
    }

    var text: Basic_V1_URLPreviewComponent.TextProperty? {
        if case .text(let value) = self { return value }
        return nil
    }

    var oversizedText: Basic_V1_URLPreviewComponent.OversizedTextProperty? {
        if case .oversizedText(let value) = self { return value }
        return nil
    }

    var tagList: Basic_V1_URLPreviewComponent.TagListProperty? {
        if case .tagList(let value) = self { return value }
        return nil
    }

    var spinButton: Basic_V1_URLPreviewComponent.SpinButtonProperty? {
        if case .spinButton(let value) = self { return value }
        return nil
    }

    var avatar: Basic_V1_URLPreviewComponent.AvatarProperty? {
        if case .avatar(let value) = self { return value }
        return nil
    }

    var video: Basic_V1_URLPreviewComponent.VideoProperty? {
        if case .video(let value) = self { return value }
        return nil
    }

    var cardContainer: Basic_V1_URLPreviewComponent.CardContainerProperty? {
        if case .cardContainer(let value) = self { return value }
        return nil
    }

    var docImage: Basic_V1_URLPreviewComponent.DocImageProperty? {
        if case .docImage(let value) = self { return value }
        return nil
    }

    var loading: Basic_V1_URLPreviewComponent.LoadingProperty? {
        if case .loading(let value) = self { return value }
        return nil
    }

    var timeZone: Basic_V1_URLPreviewComponent.TimeZoneProperty? {
        if case .timeZone(let value) = self { return value }
        return nil
    }

    var engine: Basic_V1_URLPreviewComponent.EngineProperty? {
        if case .engine(let value) = self { return value }
        return nil
    }
}
