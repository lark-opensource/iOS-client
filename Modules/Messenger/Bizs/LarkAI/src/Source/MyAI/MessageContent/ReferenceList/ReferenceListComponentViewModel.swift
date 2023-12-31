//
//  ReferenceListComponentViewModel.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/16.
//

import RustPB
import LarkCore
import LarkModel
import Foundation
import LKRichView
import TangramService
import LarkMessageBase
import LarkRichTextCore
import UniverseDesignIcon
import LarkMessengerInterface
import ThreadSafeDataStructure

public protocol ReferenceListViewModelContext: ViewModelContext {}

public class ReferenceListComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ReferenceListViewModelContext>: NewMessageSubViewModel<M, D, C>, ReferenceListShowMoreDelegate {
    /// 引用链接是否展开，默认展开
    public private(set) var referenceIsShowMore: Bool = true {
        didSet {
            if referenceIsShowMore != oldValue {
                self.binderAbility?.syncToBinder()
                // 引用链接区域很高，设置none收起时会有问题：Cell高度立刻变小，引用链接逐渐从底往上消失；这是因为tableView.reloadRow本身自带了动画，即便animation为none
                // 设置fade也有问题：fade会使得Cell刷新时内容有渐隐渐现的动画，但内容中的COT也会跟着闪一下
                // 综上所述，COT闪体验更糟，所以设置为none比较合适
                self.binderAbility?.updateComponent(animation: .none)
            }
        }
    }

    public var referenceList: ThreadSafeDataStructure.SafeArray<LKRichElement> = [] + .readWriteLock
    /// 使用URL中台部分逻辑
    private let inlinePreviewService = InlinePreviewService()

    public override func initialize() {
        super.initialize()
        self.referenceList.removeAll(); self.referenceList.append(contentsOf: self.rebuildReferenceList())
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        self.referenceList.removeAll(); self.referenceList.append(contentsOf: self.rebuildReferenceList())
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    /// 设置引用链接
    private func rebuildReferenceList() -> [LKRichElement] {
        // 这里固定设置几个内容
        var referenceList: [LKRichElement] = []
        // 从Message上获取一共有哪些引用链接
        var contentReferences: [Basic_V1_Content.Reference] = []
        if self.metaModel.message.type == .text, let content = self.metaModel.message.content as? TextContent {
            contentReferences = content.contentReferences
        } else if self.metaModel.message.type == .post, let content = self.metaModel.message.content as? PostContent {
            contentReferences = content.contentReferences
        }
        // 依次遍历这些引用，获取对应的icon + title，逻辑copy from RichViewAdaptor-buildAnchor
        let inlinePreviewBody = MessageInlineViewModel.getInlinePreviewBody(message: self.metaModel.message)
        contentReferences.forEach { (reference: Basic_V1_Content.Reference) in
            // reference.title为空才解析中台结果：reference.title > 中台解析
            let messageInlineEntity: InlinePreviewEntity? = reference.title.isEmpty ? inlinePreviewBody[self.metaModel.message.urlPreviewHangPointMap[reference.url]?.previewID ?? ""] : nil
            // 引用需要去掉空白：中台解析 > reference.url
            var referenceURL = (messageInlineEntity?.url?.tcURL ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if referenceURL.isEmpty { referenceURL = reference.url.trimmingCharacters(in: .whitespacesAndNewlines) }
            // 初始化LKAnchorElement时，text需要设置为空，不然无法addChild；样式copy from RichViewAdaptor-Tag.a
            let anchorElement = LKAnchorElement(tagName: RichViewAdaptor.Tag.a, text: "", href: referenceURL)
            anchorElement.style.textDecoration(.init(line: [], style: .solid))
            anchorElement.style.color(UIColor.ud.textLinkNormal)
            // 添加一个0宽度的内容，撑开高度
            let empty = LKInlineElement(tagName: RichViewAdaptor.Tag.span); empty.style.height(.point(20.auto())); empty.style.verticalAlign(.middle)
            anchorElement.addChild(empty)
            // 添加icon，设置居中对齐，用于LKInlineBlockElement和其他Element在同一个LineBox时可以在中间展示
            let attchment = LKAsyncRichAttachmentImp(
                size: CGSize(width: 17.auto() + 4, height: 17.auto()),
                viewProvider: { [weak self] in
                    guard let `self` = self else { return UIView(frame: .zero) }
                    // icon 距离右边 title 为4
                    let contentView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 17.auto() + 4, height: 17.auto())))
                    // 判断是否使用URL中台解析的结果
                    var imageView: UIImageView?
                    if let inlinePreviewEntity = messageInlineEntity, self.inlinePreviewService.hasIcon(entity: inlinePreviewEntity) {
                        imageView = self.inlinePreviewService.iconView(entity: inlinePreviewEntity, iconColor: UIColor.ud.textLinkNormal)
                    } else {
                        imageView = UIImageView(image: UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.textLinkNormal, size: CGSize(width: 17.auto(), height: 17.auto())))
                    }
                    imageView?.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 17.auto(), height: 17.auto()))
                    imageView?.contentMode = .scaleAspectFit
                    if let imageView = imageView { contentView.addSubview(imageView) }
                    return contentView
                },
                verticalAlign: .bottom
            )
            let iconAttachment = LKInlineBlockElement(tagName: RichViewAdaptor.Tag.span).addChild(LKAttachmentElement(attachment: attchment)); iconAttachment.style.verticalAlign(.middle)
            anchorElement.addChild(iconAttachment)
            // 添加title：中台解析 > reference.title > 兜底url
            var title = messageInlineEntity?.title ?? ""; if title.isEmpty { title = reference.title }; if title.isEmpty { title = referenceURL }
            let titleElement = LKTextElement(text: title); titleElement.style.fontSize(.point(16.auto())); titleElement.style.verticalAlign(.middle)
            anchorElement.addChild(titleElement)

            // 添加进解析结果
            referenceList.append(anchorElement)
        }
        return referenceList
    }

    /// 点击了showMore，把listView回调出去
    public func handleShowMore(listView: ReferenceListView) {
        self.referenceIsShowMore = !self.referenceIsShowMore
    }
}
