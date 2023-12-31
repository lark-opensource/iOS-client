//
//  TCPreviewContainerComponentViewModel.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2022/6/29.
//

import UIKit
import Darwin
import RustPB
import RxSwift
import LarkCore
import LarkModel
import LarkUIKit
import Foundation
import EENavigator
import EEFlexiable
import LarkContainer
import AsyncComponent
import TangramService
import LarkMessageBase
import TangramComponent
import LKCommonsTracker
import DynamicURLComponent
import LarkAccountInterface
import LarkMessengerInterface

struct TCPreviewConfig {
    // 卡片背景色
    static let cardBgColor: UIColor = UDMessageColorTheme.imMessageCardBGBodyEmbed
}

final class TCPreviewContainerComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: TCPreviewContainerContext & PageContext>: NewMessageSubViewModel<M, D, C> {
    override var identifier: String {
        return "tcPreviewContainer"
    }
    private var rwLock = pthread_rwlock_t()
    // previewID -> VM
    private var _subVMs: [String: TCPreviewComponentViewModel<C>] = [:]
    private var subVMs: [String: TCPreviewComponentViewModel<C>] {
        get {
            pthread_rwlock_rdlock(&rwLock)
            defer { pthread_rwlock_unlock(&rwLock) }
            return _subVMs
        }
        set {
            pthread_rwlock_wrlock(&rwLock)
            defer { pthread_rwlock_unlock(&rwLock) }
            _subVMs = newValue
        }
    }
    var subComponents: [TCPreviewComponent<C>] {
        let subVMs = self.subVMs
        let components = message.orderedPreviewIDs.compactMap({
            let subvm = subVMs[$0]
            subvm?.component.style.border = subvm?.dependency?.border
            return subvm?.component
        })
        for index in 0..<components.count {
            if index == 0 { continue }
            // 卡片间距8
            components[index].style.marginTop = 8
        }
        return components
    }
    private let renderTrack: TCPreviewRenderTracker
    private let messageLinkFactory: MessageLinkEngineCellViewModelFactory<PageContext>

    var margin: CSSValue {
        if !TCPreviewContainerComponentFactory.isSinglePreviewWithBubble(message: message, scene: context.scene),
           !message.displayInThreadMode, // 话题模式群里也没有气泡，但是需要有margin
           TCPreviewContainerComponentFactory.canCreateSinglePreview(message: message, chat: metaModel.getChat(), context: context) {
            return 0
        }
        return CSSValue(cgfloat: metaModelDependency.contentPadding)
    }

    lazy var fileUtilService: FileUtilService? = {
        self.context.fileUtilService
    }()

    init(metaModel: M,
         metaModelDependency: D,
         context: C,
         messageLinkFactory: MessageLinkEngineCellViewModelFactory<PageContext>,
         renderTrack: TCPreviewRenderTracker) {
        self.messageLinkFactory = messageLinkFactory
        self.renderTrack = renderTrack
        pthread_rwlock_init(&rwLock, nil)
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
    }

    override func initialize() {
        let entities = message.urlPreviewEntities.filter({ context.urlCardService.canCreate(entity: $0.1, context: context) })
        guard !entities.isEmpty else { return }
        var subVMs = [String: TCPreviewComponentViewModel<C>]()
        entities.forEach { previewID, entity in
            let renderInfo = renderTrack.initRenderInfo(entity: entity, hangPoints: message.urlPreviewHangPointMap)
            subVMs[previewID] = TCPreviewComponentViewModel(entity: entity, dependency: self, context: context, renderInfo: renderInfo)
        }
        self.subVMs = subVMs
    }

    override func update(metaModel: M, metaModelDependency: D?) {
        // 先更新数据源
        self.metaModel = metaModel
        if let metaModelDependency = metaModelDependency {
            self.metaModelDependency = metaModelDependency
        }
        let entities = metaModel.message.urlPreviewEntities.filter({ context.urlCardService.canCreate(entity: $0.1, context: context) })
        if entities.isEmpty {
            self.subVMs = [:]
        } else {
            // remove
            var subVMs = self.subVMs.filter({ entities[$0.key] != nil })
            // update & insert
            entities.forEach { previewID, entity in
                if let vm = subVMs[previewID] {
                    vm.update(entity: entity)
                } else {
                    let renderInfo = renderTrack.initRenderInfo(entity: entity, hangPoints: message.urlPreviewHangPointMap)
                    subVMs[previewID] = TCPreviewComponentViewModel(entity: entity, dependency: self, context: context, renderInfo: renderInfo)
                }
            }
            self.subVMs = subVMs
        }
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    override func willDisplay() {
        subVMs.values.forEach({ $0.willDisplay() })
        super.willDisplay()
    }

    override func didEndDisplay() {
        subVMs.values.forEach({ $0.didEndDisplay() })
        super.didEndDisplay()
    }

    override func onResize() {
        subVMs.values.forEach({ $0.onResize() })
        super.onResize()
    }
}

extension TCPreviewContainerComponentViewModel: TCPreviewComponentDependency {

    func getCardLinkScene() -> DynamicURLComponent.URLCardLinkSceneType? {
        if metaModel.getChat().chatMode == .threadV2 { return .topic }
        switch metaModel.getChat().type {
        case .group, .topicGroup: return .multi
        case .p2P: return .single
        @unknown default: return nil
        }
    }

    func getChatID() -> String? {
        return metaModel.getChat().id
    }

    func openProfile(chatterID: String, from: UIViewController) {
        let body = PersonCardBody(chatterId: chatterID, chatId: metaModel.getChat().id, source: .chat)
        Navigator.shared.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    func showImagePreview(
        properties: [RustPB.Basic_V1_RichTextElement.ImageProperty],
        index: Int,
        from: UIViewController
    ) {
        let chat = metaModel.getChat()
        var assets: [LKDisplayAsset] = []
        var assetPositionMap: [String: (position: Int32, id: String)] = [:]
        properties.forEach { (imageProperty) in
            let imageAsset = LKDisplayAsset.createAsset(
                postImageProperty: imageProperty,
                isTranslated: false,
                isAutoLoadOrigin: true
            )
            imageAsset.detectCanTranslate = message.localStatus == .success
            imageAsset.trackExtraInfo = ["message_id": message.id, "is_message_delete": message.isDeleted]
            imageAsset.extraInfo[ImageAssetMessageIdKey] = message.id
            imageAsset.extraInfo[ImageAssetFatherMFIdKey] = message.fatherMFMessage?.id
            assets.append(imageAsset)
            assetPositionMap[imageAsset.key] = (message.position, message.id)
        }
        let assetResult = CreateAssetsResult(assets: assets, selectIndex: index, assetPositionMap: assetPositionMap)
        let body = PreviewImagesBody(assets: assetResult.assets.map { $0.transform() },
                                     pageIndex: index,
                                     scene: .normal(assetPositionMap: assetResult.assetPositionMap, chatId: nil),
                                     shouldDetectFile: chat.shouldDetectFile,
                                     canSaveImage: !chat.enableRestricted(.download),
                                     canShareImage: !chat.enableRestricted(.forward),
                                     canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
                                     showSaveToCloud: !chat.enableRestricted(.download),
                                     canTranslate: false,
                                     translateEntityContext: (message.id, .message))
        Navigator.shared.present(body: body, from: from)
    }

    var userResolver: LarkContainer.UserResolver {
        return self.context.userResolver
    }

    var currentChatterId: String {
        return self.context.userID
    }

    var contentMaxWidth: CGFloat {
        if self.context.scene == .newChat, message.showInThreadModeStyle {
            return metaModelDependency.getContentPreferMaxWidth(message)
        }
        // 独立卡片且无气泡时，宽度和气泡宽度一样
        if TCPreviewContainerComponentFactory.canCreateSinglePreview(message: message, chat: metaModel.getChat(), context: context),
           !TCPreviewContainerComponentFactory.isSinglePreviewWithBubble(message: message, scene: context.scene) {
            return metaModelDependency.getContentPreferMaxWidth(message)
        }
        return metaModelDependency.getContentPreferMaxWidth(message) - 2 * metaModelDependency.contentPadding
    }

    var templateService: URLTemplateService? {
        return context.templateService
    }

    var targetVC: UIViewController? {
        return context.targetVC
    }

    var scene: ContextScene {
        return context.scene
    }

    var cornerRadius: CGFloat {
        // 气泡场景圆角为6，非气泡为8
        if scene == .newChat {
            return 6
        }
        return 8
    }

    var hostMessage: Message? {
        return self.message
    }

    var hostChat: Chat? {
        return self.metaModel.getChat()
    }

    var extraTrackParams: [AnyHashable: Any] {
        var params = IMTracker.Param.chat(metaModel.getChat())
        params += IMTracker.Param.message(self.message, doc: false)
        return params
    }

    var supportClosePreview: Bool {
        return !TCPreviewContainerComponentFactory.canCreateSinglePreview(message: message, chat: metaModel.getChat(), context: context)
    }

    var border: Border? {
        if message.type == .file {
            //文件卡片总是有边框
            return Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderCard, style: .solid))
        }
        // 卡片边框和圆角不支持配置，气泡内卡片无边框/圆角，详情页有
        switch context.scene {
        case .newChat:
            if self.message.showInThreadModeStyle {
                return Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderCard, style: .solid))
            }
            return nil
        case .mergeForwardDetail: return nil
        default: return Border(BorderEdge(width: 1, color: UIColor.ud.lineDividerDefault, style: .solid))
        }
    }

    var backgroundColor: UIColor {
        return TCPreviewConfig.cardBgColor
    }

    var cardRouterContext: [String: Any] {
        context.cardRouterContext
    }

    func update(component: AsyncComponent.Component, animation: UITableView.RowAnimation) {
        binderAbility?.updateComponent(animation: animation)
    }

    func reloadRow(animation: UITableView.RowAnimation, updateVM: Bool) {
        if updateVM {
            context.reloadRows(by: [self.message.id], doUpdate: { $0 })
        } else {
            context.reloadRow(by: message.id, animation: animation)
        }
    }

    func downloadDocThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], viewSize: CGSize) -> Observable<UIImage> {
        return context.downloadDocThumbnail(url: url, fileType: fileType, thumbnailInfo: thumbnailInfo, viewSize: viewSize)
    }

    func getColor(for key: ColorKey, type: Type) -> UIColor {
        return context.getColor(for: key, type: type)
    }

    func auditEvent(event: ChatSecurityAuditEventType) {
        context.auditEvent(event: event, isSecretChat: false)
    }

    public func getOriginURL(previewID: String) -> String {
        var richText: Basic_V1_RichText?
        if message.type == .text, let content = message.content as? TextContent {
            richText = content.richText
        } else if message.type == .post, let content = message.content as? PostContent {
            richText = content.richText
        }
        if let richText = richText,
           let elementID = message.urlPreviewHangPointMap.first(where: { $0.value.previewID == previewID })?.key,
           let element = richText.elements[elementID],
           element.tag == .a { // 目前Message里只解析了a标签
            if !element.property.anchor.href.isEmpty {
                return element.property.anchor.href
            } else if !element.property.anchor.iosHref.isEmpty {
                return element.property.anchor.iosHref
            }
        }
        return ""
    }

    var senderID: String {
        return self.message.fromId
    }

    func createEngine(
        entity: URLPreviewEntity,
        property: Basic_V1_URLPreviewComponent.EngineProperty,
        style: Basic_V1_URLPreviewComponent.Style,
        renderStyle: RenderComponentStyle
    ) -> URLEngineAbility? {
        switch property.type {
        case .message:
            guard let messageLink = message.messageLinks[entity.previewID] else { return nil }
            return MessageLinkEngineViewModel(
                context: context,
                messageLink: messageLink,
                previewID: entity.previewID,
                containerChat: self.metaModel.getChat,
                vmFactory: messageLinkFactory,
                getContentMaxWidth: { [weak self] in return self?.contentMaxWidth ?? 0 },
                targetVCProvider: { [weak self] in return self?.targetVC },
                trackParams: ["msg_id": message.id, "occasion_id": self.metaModel.getChat().id]
            )
        @unknown default: return nil
        }
    }
}
