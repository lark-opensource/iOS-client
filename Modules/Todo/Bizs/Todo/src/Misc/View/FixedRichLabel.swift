//
//  FixedRichLabel.swift
//  Todo
//
//  Created by 张威 on 2021/2/5.
//

import RichLabel
import LarkContainer
import RxSwift
import LKCommonsLogging
import UniverseDesignFont

/// NOTE: by zhangwei
/// 修复 `LKLabel` 因为屏幕宽度变化，没有重新绘制，导致渲染内容变形的问题；
/// 待 `LKLabel` 解决问题后，去掉 `FixedRichLabel`
class FixedRichLabel: LKLabel {

    override var frame: CGRect {
        didSet {
            if frame != oldValue { setNeedsDisplay() }
        }
    }

}

class RichContentLabel: LKLabel {

    typealias RawContent = Rust.RichContent
    typealias RenderContent = RichLabelContent
    typealias RenderConfig = RichLabelContentBuildConfig

    /// 修复 `LKLabel` 因为屏幕宽度变化，没有重新绘制，导致渲染内容变形的问题；
    /// 待 `LKLabel` 解决问题后，去掉 `FixedRichLabel`
    override var frame: CGRect {
        didSet { if frame != oldValue { setNeedsDisplay() } }
    }

    /// 自动修复 anchor title
    var needsAutoUpdate: ((RichLabelAnchorRenderState) -> Rust.RichText.AnchorHangEntity?)?
    var onAtClick: ((RichLabelContent.AtItem) -> Void)?
    var onAnchorClick: ((RichLabelContent.AnchorItem) -> Void)?
    var onImageClick: ((Int, UIImageView, [RichLabelContent.ImageItem]) -> Void)?
    private(set) var renderContent: RenderContent?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        autoDetectLinks = false
        outOfRangeText = AttrText(string: "\u{2026}", attributes: [
            .font: UDFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.ud.textTitle
        ])
        linkAttributes = [:]
        activeLinkAttributes = [:]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func clearRenderContent() {
        clearContent()
    }

    func updateRenderContent(userResolver: UserResolver, with rawContent: RawContent, sourceId: String, config: RenderConfig) {
        guard let richContentService = try? userResolver.resolver.resolve(assert: RichContentService.self) else {
            return
        }
        var config = config
        config.anchorConfig.sourceIdForHangEntity = sourceId
        var tempRenderContent: RenderContent?
        config.anchorConfig.renderCallback = { [weak self]  (anchorItemId, state) in
            guard
                let self = self,
                let stageContent = tempRenderContent,
                let curContent = self.renderContent,
                stageContent.id == curContent.id
            else {
                return
            }
            if let needsAutoUpdate = self.needsAutoUpdate, let entity = needsAutoUpdate(state) {
                let fixedContent = richContentService.fixLabelContent(
                    labelContent: curContent,
                    with: entity,
                    for: anchorItemId
                )
                self.render(with: fixedContent)
            }
        }
        tempRenderContent =  richContentService.buildLabelContent(with: rawContent, config: config)
        render(with: tempRenderContent!)
    }

    private func clearContent() {
        renderContent = nil
        removeLKTextLink()
    }

    private func render(with content: RenderContent) {
        renderContent = content

        removeLKTextLink()

        if onAnchorClick != nil {
            content.anchorItems
                .map { item in
                    var link = LKTextLink(range: item.range, type: .link)
                    link.linkTapBlock = { [weak self] (_, _) in self?.onAnchorClick?(item) }
                    return link
                }
                .forEach(addLKTextLink(link:))
        }
        if onAtClick != nil {
            content.atItems
                .map { item in
                    var link = LKTextLink(range: item.range, type: .link)
                    link.linkTapBlock = { [weak self] (_, _) in self?.onAtClick?(item) }
                    return link
                }
                .forEach(addLKTextLink(link:))
        }
        if onImageClick != nil {
            content.imageItems
                .map { item in
                    var link = LKTextLink(range: item.range, type: .link)
                    link.linkTapBlock = { [weak self] (label, _) in
                        let imageViews = label.subviews.compactMap { view in
                            if let subview = view as? UIImageView {
                                return subview
                            }
                            return nil
                        }
                        guard let index = content.imageItems.firstIndex(where: { $0.location == item.location }), index < imageViews.count else {
                            return
                        }
                        self?.onImageClick?(index, imageViews[index], content.imageItems)
                    }
                    return link
                }
                .forEach(addLKTextLink(link:))
        }

        attributedText = content.attrText
    }

}
