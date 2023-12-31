//
//  RichContentService.swift
//  Todo
//
//  Created by 张威 on 2021/6/30.
//

import Foundation

/// `RichLabelContent`: Content for `LKLabel`
/// `RichContentService`: Providing Content for `LKLabel` based on `Rust.Content`

struct RichLabelContent {
    struct AnchorItem {
        var id: String
        var property: Rust.RichText.Element.AnchorProperty
        var range: NSRange
        var iconRange: NSRange?
        var textRange: NSRange
    }
    struct AtItem {
        var id: String
        var property: Rust.RichText.Element.AtProperty
        var range: NSRange
    }

    struct ImageItem {
        var location: Int
        var property: Rust.RichText.Element.ImageProperty
        var range: NSRange
    }

    var id: String
    var attrText: AttrText
    var anchorItems = [AnchorItem]()
    var atItems = [AtItem]()
    var imageItems = [ImageItem]()
}

enum RichLabelAnchorRenderState {
    enum Completion {
        case hangEntity(Rust.RichText.AnchorHangEntity)
        case none
    }
    case completed(Completion)
    case needsFix(point: Rust.RichText.AnchorHangPoint)
    case needsUpdate(entity: Rust.RichText.AnchorHangEntity)
}

struct RichLabelContentBuildConfig {

    /// Anchor 标签配置
    struct AnchorConfig {
        typealias RenderCallback = (
            _ anchorId: String,
            _ state: RichLabelAnchorRenderState
        ) -> Void
        typealias HangEntityAsyncResponse = (
            _ anchorId: String,
            _ entity: Rust.RichText.AnchorHangEntity
        ) -> Void
        // 前景色，如果值为 nil，就不额外设置
        var foregroundColor: UIColor?
        var sourceIdForHangEntity: String?
        var renderCallback: RenderCallback?
    }

    /// At 标签配置
    struct AtConfig {
        // 普通前景色
        var normalForegroundColor: UIColor?
        // 外部前景色
        var outerForegroundColor: UIColor?
    }

    struct ImageConfig {
        // 图片宽度
        var width: CGFloat?
    }

    // 基本 attr 配置
    var baseAttrs = [AttrText.Key: Any]()
    // 行分隔符
    var lineSeperator = "\n"

    var anchorConfig = AnchorConfig()
    var atConfig = AtConfig()
    var imageConfig = ImageConfig()

}

protocol RichContentService: AnyObject {

    func buildLabelContent(
        with richContent: Rust.RichContent,
        config: RichLabelContentBuildConfig
    ) -> RichLabelContent

    func fixLabelContent(
        labelContent: RichLabelContent,
        with hangEntity: Rust.RichText.AnchorHangEntity,
        for anchorItemId: String
    ) -> RichLabelContent

}
