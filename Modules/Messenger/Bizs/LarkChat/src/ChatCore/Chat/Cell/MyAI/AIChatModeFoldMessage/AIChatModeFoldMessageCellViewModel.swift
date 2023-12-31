//
//  AIChatModeFoldMessageCellViewModel.swift
//  LarkChat
//
//  Created by ByteDance on 2023/6/25.
//

import Foundation
import RustPB
import LarkMessageCore
import LarkMessageBase
import AsyncComponent
import TangramService
import LarkContainer
import RichLabel
import LarkModel

class AIChatModeFoldMessageCellViewModel: ChatCellViewModel, HasCellConfig {
    var message: Message {
        didSet {
            self.calculateRenderer()
            if let viewModelId = self.id {
                self.context.reloadRow(byViewModelId: viewModelId, animation: .none)
            }
        }
    }
    var cellConfig: ChatCellConfig = ChatCellConfig()
    final override var identifier: String {
        return "ai_chat_mode_fold_message"
    }

    final override var id: String? {
        return "\(identifier)_\(message.aiChatModeID)"
    }

    var buttonType: ShowHideButton.ButtonType = .show(loading: false) {
        didSet {
            guard buttonType != oldValue else { return }
            self.calculateRenderer()
            if let viewModelId = self.id {
                self.context.reloadRow(byViewModelId: viewModelId, animation: .none)
            }
        }
    }

    lazy var buttonTappedBlock: ((ShowHideButton.ButtonType) -> Void) = { [weak self] type in
        guard let self = self else { return }
        switch type {
        case .show(let loading):
            guard !loading else { return }
            self.buttonType = .show(loading: true)
            self.context.unfoldMyAIChatModeThread(chatModeId: self.message.aiChatModeID, threadId: self.message.threadId)
        case .hide:
            self.context.foldMyAIChatModeThread(chatModeId: self.message.aiChatModeID)
        }
    }

    private let inlinePreviewService: InlinePreviewService = InlinePreviewService()

    var thread: RustPB.Basic_V1_Thread? {
        return message.thread
    }
    private var inlinePreview: InlinePreviewEntity? {
        guard let previewID = self.thread?.aiChatModeURLPreviewHangPoint.previewID else { return nil }
        return message.aiChatModeInlinePreviewEntities[previewID]
    }

    private let linkForegroundColor = UIColor.ud.textLinkNormal
    private let normalTextForegroundColor = UIColor.ud.textPlaceholder
    private let font = UIFont.ud.body2

    lazy var inlinePreviewAttrStringBlock: (_ width: CGFloat) -> NSAttributedString? = { [weak self] width in
        guard let self = self else { return nil }
        var backupAttrStringBlock: () -> NSAttributedString? = { [weak self] in
            guard let self = self,
                  let url = self.thread?.aiChatModeURLPreviewHangPoint.url else {
                return nil
            }
            return self.getTitleAttr(content: url, maxWidth: width)
        }
        guard let inlinePreview = self.inlinePreview else {
            return backupAttrStringBlock()
        }
        return self.getSummerizeAttr(inlineEntity: inlinePreview, maxWidth: width) ?? backupAttrStringBlock()
    }

    private let inlinePreviewMinWidth: CGFloat = 30 //inlinePreview的最小宽度，避免inlinePreview完全展示不出来
    lazy var totalContentBlock: (_ width: CGFloat) -> (NSAttributedString, [LKTextLink]) = { [weak self] width in
        guard let self = self else {
            return (.init(string: BundleI18n.AI.MyAI_IM_Server_CollaborationRecords_Text("")), [])
        }
        var i18nString = BundleI18n.AI.MyAI_IM_Server_CollaborationRecords_Text("")
        var widthOfI18nString = i18nString.lu.width(font: self.font)
        var remainWidth = width - widthOfI18nString
        var previewWidth = max(self.inlinePreviewMinWidth, remainWidth)
        var inlinePreviewAttrString = self.inlinePreviewAttrStringBlock(previewWidth) ?? NSAttributedString(string: "")
        var string = BundleI18n.AI.MyAI_IM_Server_CollaborationRecords_Text(inlinePreviewAttrString.string)
        var totalContentAttrString = NSMutableAttributedString(string: string, attributes: [.foregroundColor: self.normalTextForegroundColor,
                                                                                .font: self.font])
        let previewRange = (string as NSString).range(of: inlinePreviewAttrString.string)
        let offset = previewRange.location
        guard previewRange.location != NSNotFound else {
            //这个case通常不会走到。
            //仅在i18n文案出错，导致totalContentAttrString没有包含inlinePreviewAttrString时会走到。兜个底防止崩溃
            return (totalContentAttrString, [])
        }
        inlinePreviewAttrString.enumerateAttributes(in: .init(location: 0, length: inlinePreviewAttrString.length)) { attributes, range, _ in
            totalContentAttrString.addAttributes(attributes, range: NSRange(location: range.location + offset, length: range.length))
        }

        var textLinkList: [LKTextLink] = []
        var textLink = LKTextLink(range: previewRange, type: .link)
        textLink.linkTapBlock = { [weak self] (_, _) in
            self?.openURL()
        }
        textLinkList.append(textLink)
        return (totalContentAttrString, textLinkList)
    }

    var outOfRangeText: NSAttributedString {
        var attrString = NSMutableAttributedString(string: "...", attributes: [.foregroundColor: normalTextForegroundColor,
                                                                               .font: font])
        return attrString
    }

    init(rootMessage: Message, context: ChatContext) {
        self.message = rootMessage
        super.init(context: context, binder: AIChatModeFoldMessageComponentBinder(context: context))
        self.calculateRenderer()
    }

    private func openURL() {
        guard let thread = self.thread else { return }
        do {
            let url = try URL.forceCreateURL(string: thread.aiChatModeURLPreviewHangPoint.url)
            self.context.navigator(type: .open, url: url, params: nil)
        } catch {
        }
    }

    func getSummerizeAttr(inlineEntity: InlinePreviewEntity, maxWidth: CGFloat) -> NSMutableAttributedString? {
        guard let title = inlineEntity.title, !title.isEmpty else { return nil }
        let summerize = NSMutableAttributedString()
        let imageAttr = getImageAttr(inlineEntity: inlineEntity)
        let tagAttr = getTagAttr(entity: inlineEntity)
        let remainWidth = maxWidth - (imageAttr?.1 ?? 0) - (tagAttr?.1 ?? 0)
        if let imageAttr = imageAttr {
            summerize.append(imageAttr.0)
        }
        summerize.append(getTitleAttr(content: title, maxWidth: remainWidth))
        if let tagAttr = tagAttr {
            summerize.append(tagAttr.0)
        }
        return summerize
    }

    func getTitleAttr(content: String, maxWidth: CGFloat) -> NSAttributedString {
        let contentWidth = content.lu.width(font: self.font)
        let attachMent = LKAsyncAttachment(viewProvider: { [weak self] in
            guard let self = self else { return UIView() }
            let label = UILabel()
            label.textColor = self.linkForegroundColor
            label.font = self.font
            label.text = content
            return label
        }, size: CGSize(width: min(contentWidth, maxWidth),
                        height: font.pointSize))
        attachMent.fontAscent = font.ascender
        attachMent.fontDescent = font.descender
        let titleAttr = NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                           attributes: [LKAttachmentAttributeName: attachMent])
        return titleAttr
    }

    //返回值：(attr，width)
    func getImageAttr(inlineEntity: InlinePreviewEntity) -> (NSAttributedString, CGFloat)? {
        guard inlinePreviewService.hasIcon(entity: inlineEntity) else { return nil }
        let font = self.font
        let iconColor = self.linkForegroundColor
        let inlineService = inlinePreviewService
        let attachMent = LKAsyncAttachment(viewProvider: {
            return inlineService.iconView(entity: inlineEntity, iconColor: iconColor)
        }, size: CGSize(width: font.pointSize, height: font.pointSize * 0.95))
        attachMent.fontAscent = font.ascender
        attachMent.fontDescent = font.descender
        attachMent.margin = UIEdgeInsets(top: 1, left: 4, bottom: 0, right: 4)
        let imageAttr = NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                           attributes: [LKAttachmentAttributeName: attachMent])
        return (imageAttr, font.pointSize + 8)
    }

    //返回值：(attr，width)
    func getTagAttr(entity: InlinePreviewEntity) -> (NSAttributedString, CGFloat)? {
        guard inlinePreviewService.hasTag(entity: entity) else { return nil }
        let tag = entity.tag ?? ""
        let tagType = TagType.link
        let font = self.font
        let inlineService = inlinePreviewService
        let size = inlinePreviewService.tagViewSize(text: tag, titleFont: font)
        let attachMent = LKAsyncAttachment(viewProvider: {
            let tagView = inlineService.tagView(text: tag, titleFont: font, type: tagType)
            return tagView
        }, size: size)
        attachMent.fontAscent = font.ascender
        attachMent.fontDescent = font.descender
        attachMent.margin = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 2)
        return (NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                  attributes: [LKAttachmentAttributeName: attachMent]),
                size.width + 6)
    }

    func foldSuccess() {
        self.buttonType = .show(loading: false)
    }
    func unfoldSuccess() {
        self.buttonType = .hide
    }
}

final class AIChatModeFoldMessageComponentBinder: ComponentBinder<ChatContext> {
    private lazy var _component: AIChatModeFoldMessageComponent = .init(props: .init(), style: .init(), context: nil)
    private var props: AIChatModeFoldMessageComponent.Props = .init()

    final override var component: ComponentWithContext<ChatContext> {
        return _component
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? AIChatModeFoldMessageCellViewModel else {
            assertionFailure()
            return
        }
        props.labelAttrTextAndTextLinksBlock = vm.totalContentBlock
        props.outOfRangeText = vm.outOfRangeText
        props.buttonType = vm.buttonType
        props.buttonTappedBlock = vm.buttonTappedBlock
        _component.props = props
    }

    override func buildComponent(key: String? = nil, context: ChatContext? = nil) {
        props = AIChatModeFoldMessageComponent.Props()
        var style = ASComponentStyle()
        style.display = .flex
        style.paddingTop = 8
        style.paddingBottom = 8
        style.alignContent = .stretch
        style.justifyContent = .center
        _component = AIChatModeFoldMessageComponent(
            props: props,
            style: style,
            context: context
        )
    }
}

extension PageContext {
    var urlPreviewAPI: URLPreviewAPI? {
        return try? resolver.resolve(assert: URLPreviewAPI.self, cache: true)
    }
}
