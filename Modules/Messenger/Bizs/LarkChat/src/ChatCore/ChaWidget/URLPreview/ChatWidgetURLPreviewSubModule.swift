//
//  ChatWidgetURLPreviewSubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/1/10.
//

import Foundation
import RustPB
import TangramService
import LKCommonsLogging
import LarkOpenChat
import LarkSDKInterface
import LarkModel
import RxSwift
import RxCocoa
import LarkContainer
import LarkCore
import LarkMessageCore
import DynamicURLComponent

public final class ChatWidgetURLPreviewSubModule: ChatWidgetSubModule {
    static let logger = Logger.log(ChatWidgetURLPreviewSubModule.self, category: "ChatWidgetURLPreviewSubModule")

    private let disposeBag: DisposeBag = DisposeBag()

    public override var type: RustPB.Im_V1_ChatWidget.WidgetType {
        return .urlPreview
    }

    public override class func canInitialize(context: ChatWidgetContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatWidgetMetaModel) -> Bool {
        return true
    }

    public override func handler(model: ChatWidgetMetaModel) -> [Module<ChatWidgetContext, ChatWidgetMetaModel>] {
        return [self]
    }

    private var metaModel: ChatWidgetMetaModel?
    public override func modelDidChange(model: ChatWidgetMetaModel) {
        self.metaModel = model
    }

    public override func parseWidgetsResponse(widgetPBs: [RustPB.Im_V1_ChatWidget], response: RustPB.Im_V1_GetChatWidgetsResponse) -> [ChatWidget] {
        let widgets: [ChatWidget] = widgetPBs.map { self.transform(pbModel: $0, previewEntities: response.previewEntities) }
        self.widgetTemplateService?.update(templates: response.previewTemplates)
        self.previewService?.fetchMissingURLPreviews(widgets: widgets)
        return widgets
    }

    public override func parseWidgetsPush(widgetPBs: [RustPB.Im_V1_ChatWidget], push: RustPB.Im_V1_PushChatWidgets) -> [ChatWidget] {
        let widgets: [ChatWidget] = widgetPBs.map { self.transform(pbModel: $0, previewEntities: push.previewEntities) }
        self.previewService?.fetchMissingURLPreviews(widgets: widgets)
        return widgets
    }

    private func transform(pbModel: RustPB.Im_V1_ChatWidget, previewEntities: [String: Basic_V1_UrlPreviewEntity]) -> ChatWidget {
        let hangPoint = pbModel.previewContent.previewHangPoint
        var urlPreviewEntity: URLPreviewEntity?
        if let entityPB = previewEntities[hangPoint.previewID] {
            urlPreviewEntity = URLPreviewEntity.transform(from: entityPB)
        }
        return ChatWidget(
            id: pbModel.id,
            type: pbModel.widgetType,
            content: ChatWidgetURLPreviewContent(
                hangPoint: hangPoint,
                urlPreviewEntity: urlPreviewEntity
            )
        )
    }

    private var widgetTemplateService: ChatWidgetURLTemplateService?
    private var previewService: ChatWidgetURLPreviewService?
    private var urlCardService: URLCardService?

    public override func setup() {
        guard let chatId = self.metaModel?.chat.id, let api = try? resolver.resolve(assert: URLPreviewAPI.self) else { return }

        let pushCenter = self.context.pushCenter
        self.previewService = ChatWidgetURLPreviewService(
            pushCenter: pushCenter,
            urlPreviewAPI: api,
            chatId: chatId
        )

        self.widgetTemplateService = ChatWidgetURLTemplateServiceImp(
            chatId: chatId,
            pushCenter: pushCenter,
            updateHandler: { [weak self] missingTemplateIDs in
                guard let self = self else { return }
                let missingTemplateIDSet = Set(missingTemplateIDs)
                self.context.update(doUpdate: { widget in
                    guard let content = widget.content as? ChatWidgetURLPreviewContent else { return nil }
                    guard let previewBody = content.urlPreviewEntity?.previewBody else { return nil }
                    let needUpdate = previewBody.states.values.contains {
                        return missingTemplateIDSet.contains($0.templateID)
                    }
                    return needUpdate ? widget : nil
                }, completion: nil)
            },
            urlAPI: api
        )
        self.context.container.register(ChatWidgetURLTemplateService.self) { [weak self] _ -> ChatWidgetURLTemplateService in
            return self?.widgetTemplateService ?? DefaultChatWidgetURLTemplateServiceImp()
        }

        let userID = self.context.userID
        self.urlCardService = URLCardService(userID: userID)
        self.context.container.register(URLCardService.self) { [weak self] _ in
            return self?.urlCardService ?? URLCardService(userID: userID)
        }

        pushCenter.observable(for: URLPreviewScenePush.self)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }

                var updatedEntities = [URLPreviewEntity]()
                var dataSourcePreviewIDs: Set<String> = []

                self.context.update(doUpdate: { widget in
                    guard var content = widget.content as? ChatWidgetURLPreviewContent else { return nil }
                    let previewID = content.hangPoint.previewID
                    dataSourcePreviewIDs.insert(previewID)

                    var needUpdate = false
                    if let newEntity = push.urlPreviewEntities[previewID] {
                        if let oldEntity = content.urlPreviewEntity {
                            if newEntity.version >= oldEntity.version {
                                content.urlPreviewEntity = newEntity
                                widget.content = content
                                updatedEntities.append(newEntity)
                                needUpdate = true
                            }
                        } else {
                            content.urlPreviewEntity = newEntity
                            widget.content = content
                            updatedEntities.append(newEntity)
                            needUpdate = true
                        }
                    }
                    return needUpdate ? widget : nil
                }, completion: { [weak self] _ in
                    guard let self = self else { return }
                    self.previewService?.handleURLPreviews(entities: updatedEntities)
                    guard push.type == .sdk else { return }
                    let previewIDs = push.needLazyLoadPreviews
                        .filter { $0.appID == 7_178_058_966_235_168_788
                            && $0.appSceneType == 1
                            && dataSourcePreviewIDs.contains($0.previewID)
                        }
                        .map { return $0.previewID }
                    self.previewService?.fetchNeedLazyLoadPreviews(previewIds: previewIDs)
                })
            }).disposed(by: self.disposeBag)
    }

    public override func canShow(_ metaModel: ChatWidgetCellMetaModel) -> Bool {
        guard let content = metaModel.widget.content as? ChatWidgetURLPreviewContent,
              let entity = content.urlPreviewEntity else {
            return false
        }
        return self.urlCardService?.canCreate(entity: entity, context: self) ?? false
    }

    public override func createViewModel(_ metaModel: ChatWidgetCellMetaModel) -> ChatWidgetContentViewModel? {
        return ChatWidgetURLPreviewViewModel(metaModel: metaModel, context: self.context)
    }
}

extension ChatWidgetURLPreviewSubModule: URLCardContext {
    public var templateService: TangramService.URLTemplateService? {
        return widgetTemplateService?.templateService
    }

    public func canCreateEngine(
        property: Basic_V1_URLPreviewComponent.EngineProperty,
        style: Basic_V1_URLPreviewComponent.Style
    ) -> Bool {
        return false
    }
}
